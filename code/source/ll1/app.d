module ll1.app;

import sharedd.grammar;
import sharedd.helper;

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

    string grammarPath = args[1];
    auto maybeGrammarBuilder = parseGrammarFile(grammarPath);
    if (maybeGrammarBuilder.isNull)
        return;
    auto grammarBuilder = maybeGrammarBuilder.get();
    bool addEpsilon = true;
    auto maybeGrammar = grammarBuilder.build(addEpsilon);
    if (maybeGrammar.isNull)
        return;
    const(Grammar) g = maybeGrammar.get();
    
    auto firstTable = makeFirstTable(g);

    // This is not ideal, might alocate a few more size_t's than necessary.
    size_t[] tokenMask = bitMemory(g.symbols.length);
    setBitRange(tokenMask, g.numNonTerminals, g.symbols.length, true);
    auto followTable = makeFollowTable(g, firstTable, tokenMask);
    
    writeProductions(stdout.lockingTextWriter, g);
    firstTable.writeTo(stdout.lockingTextWriter, g, "First");
    followTable.writeTo(stdout.lockingTextWriter, i => getPrecedenceSymbolName(g, i), "Follow");

    {
        import mir.ndslice : slice;
        const eofIdInFollowTable = g.symbols.length;
        const size_t tableEofIndex = g.epsilonId;
        const ssize_t none = -1;
        const ssize_t epsilon = -2;
        auto table = slice!ssize_t(g.numNonTerminals, g.numTerminals);
        table[] = none;

        bool isError = false;
        void assignMaybeError(size_t lhsId, size_t rhsId, size_t productionIndex)
        {
            size_t rhsIndex;
            // $ = epsilon? still not sure.
            // if (rhsId == eofIdInFollowTable)
            //     rhsId = g.epsilonId;
            // else
                rhsIndex = g.getTerminalIndex(rhsId);
            
            ssize_t* indexInTable = &table[lhsId, rhsIndex];
            if (*indexInTable == none)
            {
                *indexInTable = productionIndex;
                return;
            }
            if (*indexInTable == productionIndex)
                return;

            auto productions = g.symbols[lhsId].productions;
            if (productionIndex == epsilon
                && productions[*indexInTable].rhsIds == [g.epsilonId])
            {
                return;
            }
            if (*indexInTable == epsilon
                && productions[productionIndex].rhsIds == [g.epsilonId])
            {
                *indexInTable = productionIndex;
                return;
            }

            {
                writeln("This grammar is not an LL(1) grammar: Rule collision:");

                void writeProdEpsilon(ssize_t productionIndex)
                {
                    if (productionIndex == epsilon)
                    {
                        writeln(g.symbols[lhsId].name, " --> eps");
                    }
                    else
                    {
                        const(size_t)[] rhsIds = productions[productionIndex].rhsIds;
                        writeProduction(stdout.lockingTextWriter, g, lhsId, rhsIds);
                        writeln();
                    }
                }
                writeProdEpsilon(productionIndex);
                writeProdEpsilon(*indexInTable);
                isError = true;
            }
        }

        size_t[] temp = bitMemory(g.symbols.length + 1);

        foreach (lhsId, lhsSymbol; g.symbols)
        {
            foreach (productionIndex, production; lhsSymbol.productions)
            {
                auto rhsIds = production.rhsIds;
                auto rhsFirst = firstTable.getSlice(rhsIds[0]);
                auto followA = followTable.getSlice(lhsId);

                temp[] = rhsFirst[] & tokenMask[];
                foreach (terminalId; iterateSetBits(temp, g.symbols.length))
                    assignMaybeError(lhsId, terminalId, productionIndex);

                if (getBit(rhsFirst, g.epsilonId))
                {
                    temp[] = followA[] & tokenMask[];
                    foreach (terminalId; iterateSetBits(temp, g.symbols.length))
                        assignMaybeError(lhsId, terminalId, epsilon);

                    if (getBit(followA, eofIdInFollowTable))
                        assignMaybeError(lhsId, tableEofIndex, epsilon);
                }
            }
        }

        import std.algorithm;
        auto terminalColumns = g.iterateTerminals;
        auto nonTerminalRows = g.nonTerminals;

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
        size_t leftWidth = nonTerminalRows.map!(s => s.name.length).maxElement;

        write(' '.repeat(leftWidth));
        foreach (s; terminalColumns.map!(t => t.id == tableEofIndex ? "$" : t.name))
            writef!"|%*s"(cellWidth, s);
        writeln();
        foreach (irow, s; nonTerminalRows.enumerate)
        {
            writef!"%*s"(leftWidth, s.name);
            foreach (icol, t; terminalColumns.enumerate)
            {
                const v = table[irow, icol];
                switch (v)
                {
                    case none:
                    {
                        write("|", ' '.repeat(cellWidth));
                        break;
                    }
                    case epsilon:
                    {
                        writef!"|%*s"(cellWidth, g.symbols[irow].name ~ " --> eps");
                        break;
                    }
                    default:
                    {
                        writef!"|%*s"(cellWidth, strings[irow][v]);
                        break;
                    }
                }
            }
            writeln();
        }
    }
}

enum int HeadDirection = 1;
enum int TailDirection = -1;

import sharedd.parsing;

OperationTable makeFirstTable(in Grammar g)
{
    const numSymbols = g.symbols.length;

    auto resultTable = OperationTable(numSymbols, numSymbols);
    auto temp = bitMemory(numSymbols);

    import std.container : DList;
    auto queue = DList!size_t();
    foreach (i, s; g.symbols)
    {
        if (!s.isTerminal)
            queue ~= i;
        else
            resultTable.getBitArray(i)[i] = true;
    } 

    while (!queue.empty)
    {
        size_t t = queue.front;
        queue.removeFront();
        temp[] = 0;

        productionLoop: foreach (p; g.symbols[t].productions)
        {
            size_t h = p.rhsIds[0];

            import std.bitmanip;
            if (g.hasEpsilon)
            {
                if (p.rhsIds.length == 1 && h == g.epsilonId)
                {
                    setBit(temp, g.epsilonId);
                    continue;
                }

                BitArray other;
                while ((other = resultTable.getBitArray(h))[g.epsilonId])
                {
                    other[g.epsilonId] = false;
                    temp[] |= resultTable.getSlice(h)[];
                    other[g.epsilonId] = true;
                    h += 1;

                    // Went off the array
                    if (h == p.rhsIds.length)
                    {
                        setBit(temp, g.epsilonId);
                        continue productionLoop;
                    }
                }
            }

            // The thing at h is not an epsilon.
            setBit(temp, h);
            temp[] |= resultTable.getSlice(h)[];
        }
        
        // whichever things were new.
        temp[] &= ~resultTable.getSlice(t)[];
        
        // Some new stuff was added.
        if (!iterateSetBits(temp, numSymbols).empty)
        {
            queue ~= t;
            resultTable.getSlice(t)[] |= temp[];
        }
    }

    return resultTable;
}

// http://www.cs.ecu.edu/karl/5220/spr16/Notes/Top-down/follow.html
OperationTable makeFollowTable(in Grammar g, in OperationTable firstTable, const(size_t)[] tokenMask)
{
    const eofId = g.symbols.length;
    const numSymbols = g.symbols.length + 1;
    auto resultTable = OperationTable(numSymbols, numSymbols);

    // 1. Add $ to FOLLOW(S), where S is the start nonterminal.
    resultTable.getBitArray(g.initialSymbolId)[eofId] = true;

    import std.container : DList;
    auto queue = DList!size_t();
    foreach (i, s; g.symbols)
    {
        if (!s.isTerminal)
            queue ~= i;
    }

    size_t[] temp = bitMemory(numSymbols);
    size_t[] hasBeenQueued = bitMemory(numSymbols);

    while (!queue.empty)
    {
        size_t t = queue.front;
        queue.removeFront();
        clearBit(hasBeenQueued, t);

        productionLoop: foreach (p; g.symbols[t].productions)
        {
            auto rhsIds = p.rhsIds;

            // 2. If there is a production A → αBβ,
            // then add every token that is in FIRST(β) to FOLLOW(B).
            // (Do not add ε to FOLLOW(B). 
            if (rhsIds.length >= 2
                && !g.symbols[rhsIds[$ - 2]].isTerminal)
            {

                const bIndex = rhsIds[$ - 2];
                auto B = resultTable.getSlice(bIndex);
                auto beta = firstTable.getSlice(rhsIds[$ - 1]);

                bool shouldRemoveEpsilon = !getBit(B, g.epsilonId) && getBit(beta, g.epsilonId);
                temp[0 .. beta.length] = beta[] & tokenMask[];
                if (shouldRemoveEpsilon)
                    setBit(temp, g.epsilonId);
                
                // 4. If there is a production A → αBβ where FIRST(β) contains ε,
                // then add all members of FOLLOW(A) to FOLLOW(B).
                // (Reasoning is like rule 3. Just erase β.)
                if (getBit(beta, g.epsilonId))
                {
                    auto A = resultTable.getSlice(t);
                    temp[] |= A[];
                }

                temp[] &= ~B[];

                if (temp.any!(s => s != 0) && !setBit(hasBeenQueued, bIndex))
                {
                    B[] = temp[];
                    queue ~= bIndex;
                }
            }

            // 3. If there is a production A → αB, then add all members of FOLLOW(A) to FOLLOW(B).
            // (If t can follow A, then there must be a sentential form β A t γ
            // Using production A → αB gives sentential form β α B t γ, where B is followed by t.)
            if (!g.symbols[rhsIds[$ - 1]].isTerminal)
            {
                const bIndex = rhsIds[$ - 1];
                auto A = resultTable.getSlice(t);
                auto B = resultTable.getSlice(bIndex);
                temp[] = A[] & ~B[];

                if (temp.any!(s => s != 0) && !setBit(hasBeenQueued, bIndex))
                {
                    B[] |= A[];
                    queue ~= bIndex;
                }
            }
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