module ll1.app;

import sharedd.grammar;

import std.stdio;
import std.algorithm;
import std.range;

void main(string[] args)
{
    if (args.length == 1)
    {
        writeln("Usage: ", args[0], " grammar-path");
        writeln("Example grammar file:");
        writeln("A --> a B c | D e F");
        writeln("B --> D | c");
        writeln("F --> a");
        return;
    }

    Grammar g;
    {
        string grammarPath = args[1];
        auto maybeGrammar = parseGrammarFile(grammarPath);
        if (maybeGrammar.isNull)
            return;
        g = maybeGrammar.get();
    }

    auto epsilonId = addOrGetSymbolId(g, "eps");
    // if (g.symbols[]
    //     .map!(s => s.productions)
    //     .joiner
    //     .map!(p => p.stride(2))
    //     .any!(a => a[0] == a[1] && a[0] == epsilonId))
    if (g.productions
        .map!(p => p.rhsIds)
        .any!((rhsIds) => rhsIds.length > 1
            && rhsIds[].count(epsilonId) != 0))
    {
        writeln("If a production contains an epsilon, it must be the only symbol.");
        return;
    }

    auto headTable = makeEpsilonOperationTable!HeadDirection(g, epsilonId);
    auto tailTable = makeEpsilonOperationTable!TailDirection(g, epsilonId);
    
    writeProductions(stdout.lockingTextWriter, g);
    headTable.writeTo(stdout.lockingTextWriter, g, "Head");
    tailTable.writeTo(stdout.lockingTextWriter, g, "Tail");

    {
        import mir.ndslice : slice;
        size_t eofId = g.symbols.length;
        size_t numSymbols = g.symbols.length + 1;
        auto table = slice!size_t(numSymbols, numSymbols);
        table[] = size_t.max;

        // foreach (sid, s; g.nonTerminals)
        // {
        //     foreach (terminalId; headTable
        //         .iterate(sid)
        //         .filter!(id => g.symbols[id].isTerminal)) 
        //     {
        //         if (terminalId != epsilonId)
        //             table[sid, terminalId]
        //     }
        // }
        bool isError = false;
        void assignMaybeError(size_t lhsId, size_t rhsId, size_t productionIndex)
        {
            size_t* indexInTable = &table[lhsId, rhsId];
            if (*indexInTable == size_t.max)
            {
                *indexInTable = productionIndex;
                return;
            }
            if (*indexInTable == productionIndex)
                return;

            {
                writeln("This grammar is not an LL(1) grammar: Rule collision:");
                auto productions = g.symbols[lhsId].productions;
                const(size_t)[] rhsIds = productions[productionIndex].rhsIds;
                writeProduction(stdout.lockingTextWriter, g, lhsId, rhsIds);

                auto p0 = productions[*indexInTable];
                writeProduction(stdout.lockingTextWriter, g, lhsId, p0.rhsIds);
                isError = true;
            }
        }

        foreach (lhsId, lhsSymbol; g.symbols)
        {
            foreach (productionIndex, production; lhsSymbol.productions)
            {
                auto rhsIds = production.rhsIds;

                if (rhsIds == [epsilonId])
                {
                    foreach (tailId; tailTable.iterate(lhsId))
                    {
                        if (g.symbols[tailId].isTerminal)
                            assignMaybeError(lhsId, tailId != epsilonId ? tailId : eofId, productionIndex);
                    }
                    continue;
                }
                else
                {
                    size_t rhsIndex = 0;
                    
                    import std.bitmanip;
                    BitArray bt;
                    do
                    {
                        bt = headTable.getBitArray(rhsIds[rhsIndex]);
                        foreach (headId; bt.bitsSet)
                        {
                            if (g.symbols[headId].isTerminal
                                && headId != epsilonId)
                            {
                                assignMaybeError(lhsId, headId, productionIndex);
                            }
                        }
                        if (rhsIndex >= rhsIds.length - 1)
                            break;
                        rhsIndex += 1;
                    }
                    while (bt[epsilonId]);
                }
            }
        }

        import std.algorithm;
        auto terminalColumns = iota(0, numSymbols)
            .filter!((icol)
            {
                if (icol == eofId)
                    return true;
                if (!g.symbols[icol].isTerminal)
                    return false;
                if (icol == epsilonId)
                    return false;
                return true;
            });

        auto nonTerminalRows = iota(0, g.symbols.length)
            .filter!(i => !g.symbols[i].isTerminal);

        import std.range;
        auto strings = g.symbols[].enumerate.map!((s)
        {
            return s.value.productions.map!((p)
            {
                auto app = appender!string;
                writeProduction(app, g, s.index, p.rhsIds);
                return app[];
            }).array;
        }).array;

        size_t cellWidth = strings.joiner.map!(s => s.length).maxElement;
        size_t leftWidth = nonTerminalRows.map!(sid => g.symbols[sid].name.length).maxElement;

        write(' '.repeat(leftWidth));
        foreach (s; terminalColumns.map!(i => getPrecedenceSymbolName(g, i)))
            writef!"|%*s"(cellWidth, s);
        writeln();
        foreach (irow; nonTerminalRows)
        {
            writef!"%*s"(leftWidth, g.symbols[irow].name);
            foreach (icol; terminalColumns)
            {
                const v = table[irow, icol];
                if (v == size_t.max)
                    write("|", ' '.repeat(cellWidth));
                else
                    writef!"|%*s"(cellWidth, strings[irow][v]);
            }
            writeln();
        }
    }
}

enum int HeadDirection = 1;
enum int TailDirection = -1;

import sharedd.parsing;

OperationTable makeEpsilonOperationTable(int direction)(in Grammar g, size_t epsilonSymbolId)
{
    static assert(direction == 1 || direction == -1);

    const numSymbols = g.symbols.length;

    assert(g.symbols[epsilonSymbolId].isTerminal);

    auto resultTable = OperationTable(numSymbols, numSymbols);

    auto tempTable = OperationTable(numSymbols, 1);
    auto tempArray1 = tempTable.getBitArray(0);
    auto tempBuffer1 = tempTable.getSlice(0);

    import std.container : DList;
    auto queue = DList!size_t();
    foreach (i, s; g.symbols)
    {
        if (!s.isTerminal)
            queue ~= i;
    }

    while (!queue.empty)
    {
        size_t t = queue.front;
        queue.removeFront();
        tempBuffer1[] = 0;

        productionLoop: foreach (p; g.symbols[t].productions)
        {
            if (p.rhsIds[] == [epsilonSymbolId])
            {
                tempArray1[epsilonSymbolId] = true;
                continue;
            }

            static if (direction == 1)
                size_t h = p.rhsIds[0];
            else
                size_t h = p.rhsIds[$ - 1];

            import std.bitmanip;
            BitArray other;
            while ((other = resultTable.getBitArray(h))[epsilonSymbolId])
            {
                other[epsilonSymbolId] = false;
                tempBuffer1[] |= resultTable.getSlice(h)[];
                other[epsilonSymbolId] = true;

                // Went off the array
                if (direction == 1
                    ? (h >= g.symbols.length - direction)
                    : (h < -direction))
                {
                    tempArray1[epsilonSymbolId] = true;
                    continue productionLoop;
                }

                h += direction;
            }

            // The thing at h is not an epsilon.
            tempArray1[h] = true;
            tempBuffer1[] |= resultTable.getSlice(h)[];
        }
        
        // whichever things were new.
        tempBuffer1[] &= ~resultTable.getSlice(t)[];
        
        // Some new stuff was added.
        if (!tempArray1.bitsSet.empty)
        {
            queue ~= t;
            resultTable.getSlice(t)[] |= tempBuffer1[];
        }
    }

    return resultTable;
}

string getPrecedenceSymbolName(in Grammar g, size_t i)
{
    if (i == g.symbols.length)
        return "$";
    else
        return g.symbols[i].name;
}