module app;

import sharedd.grammar;
import sharedd.parsing;

import std.stdio;
import std.algorithm;
import std.range;

void main(string[] args)
{
    if (args.length == 1)
    {
        writeln("Usage: ", args[0], " grammar");
        writeln("grammar can be a path to a grammar text file, or one of the following: ",
            "lab3-example, wiki-example-1, wiki-example-2");
        writeln("Example grammar file:");
        writeln("A --> a B c | D e F");
        writeln("B --> D | c");
        writeln("F --> a");
        return;
    }

    GrammarBuilder grammarBuilder;
    string grammarPath = args[1];
    switch (grammarPath)
    {
        case "lab3-example":
        {
            // 1. S→A  2. A→B  3. A→AcB  4. B→a  5. B →b 6. B→dD  7. D→Ae
            grammarBuilder.addProduction("S", ["A"]);
            grammarBuilder.addProduction("A", ["B"]);
            grammarBuilder.addProduction("A", ["A", "c", "B"]);
            grammarBuilder.addProduction("B", ["a"]);
            grammarBuilder.addProduction("B", ["b"]);
            grammarBuilder.addProduction("B", ["d", "D"]);
            grammarBuilder.addProduction("D", ["A", "e"]);
            break;
        }
        case "wiki-example-1":
        {
            // Example from wiki
            // https://www.wikiwand.com/en/Wirth%E2%80%93Weber_precedence_relationship#/Examples
            grammarBuilder.addProduction("S", ["a", "S", "S", "b"]);
            grammarBuilder.addProduction("S", ["c"]);
            break;
        }
        case "wiki-example-2":
        {
            // Example from wiki
            // https://www.wikiwand.com/en/Simple_precedence_parser#/Example
            grammarBuilder.addProduction("E", ["E", "+", "T'"]);
            grammarBuilder.addProduction("E", ["T'"]);
            grammarBuilder.addProduction("T'", ["T"]);
            grammarBuilder.addProduction("T", ["T", "*", "F"]);
            grammarBuilder.addProduction("T", ["F"]);
            grammarBuilder.addProduction("F", ["(", "E'", ")"]);
            grammarBuilder.addProduction("F", ["num"]);
            grammarBuilder.addProduction("E'", ["E"]);
            break;
        }
        default:
        {
            auto maybeGrammarBuilder = parseGrammarFile(grammarPath);
            if (maybeGrammarBuilder.isNull)
                return;
            grammarBuilder = maybeGrammarBuilder.get();
            break;
        }
    }
    
    auto maybeGrammar = grammarBuilder.build();
    if (maybeGrammar.isNull)
        return;
    const(Grammar) g = maybeGrammar.get();
    
    bool hasEpsilonProductions = g.checkForEpsilonProductions();
    bool hasUnreachableSymbols = g.checkForUnreachableSymbols();
    bool hasUnproductiveSymbols = g.checkForUnproductiveSymbols();

    auto headTable = g.makeNoEpsilonOperationTable!(rhsIds => rhsIds[0]);
    auto tailTable = g.makeNoEpsilonOperationTable!(rhsIds => rhsIds[$ - 1]);

    foreach (p; g.productions)
    {
        writeProduction(stdout.lockingTextWriter, g, p.lhsId, p.rhsIds);
        writeln();
    }
    headTable.writeTo(stdout.lockingTextWriter, g, "Head");
    tailTable.writeTo(stdout.lockingTextWriter, g, "Tail");

    auto nullablePrecedenceTable = getPrecedenceTable(g, headTable, tailTable);

    // G is uniquely inversible?? how to prove?

    if (hasEpsilonProductions
        || hasUnproductiveSymbols
        || hasUnreachableSymbols
        || nullablePrecedenceTable.isNull)
    {
        return;
    }

    auto precedenceTable = nullablePrecedenceTable.get();
    writePrecedenceTable(stdout.lockingTextWriter, g, precedenceTable);

    while (true)
    {
        import std.string;
        
        write("Enter input: ");
        string inputLine = readln().strip;

        auto maybeInput = tokenize(g, inputLine);
        if (maybeInput.isNull)
            continue;
        size_t[] input = maybeInput.get();
        
        if (matchInput(g, precedenceTable, input))
            writeln("Input matched");
    }
}

bool matchInput(in Grammar g, in PrecedenceTable precedenceTable, ref size_t[] input)
{
    import std.algorithm;
    import std.range;
    import std.array;
    import std.stdio;

    const eof = g.symbols.length;
    input ~= eof;

    Stack!size_t stack;
    Stack!PrecedenceRelationKind precedenceStack;
    stack.push(eof);

    writeln(padRight("Stack", ' ', 35), "     ", padRight("Input", ' ', 35));
    while (true)
    {
        auto fid = input.front;

        void writeState(string precedenceRelationString)
        {
            auto i = input[].map!(i => g.getPrecedenceSymbolName(i)).joiner(" ");
            auto a = stack[].map!(s => getPrecedenceSymbolName(g, s));
            auto b = precedenceStack[].map!(k => getPrecedenceRelationString(k));
            auto s = a.take(1).chain(b.interlace(a.drop(1))).joiner(" ");
            writeln(padRight(s, ' ', 35), " ", precedenceRelationString, "   ", padRight(i, ' ', 35));
        }

        if (input.front == eof
            && stack[] == [eof, g.initialSymbolId])
        {
            writeState(" ");
            return true;
        }

        PrecedenceRelationKind relationKind = precedenceTable[stack.top, fid];
        writeState(getPrecedenceRelationString(relationKind));

        final switch (relationKind)
        {
            case PrecedenceRelationKind.Conflict:
                assert(false, "Invalid precedence table.");

            case PrecedenceRelationKind.None:
            {
                writeln("Precedence relation none, shouldn't happen. Probably input doesn't match.");
                return false;
            }
            case PrecedenceRelationKind.DotLess:
            case PrecedenceRelationKind.DotEqual:
            {
                precedenceStack.push(relationKind);
                stack.push(fid);
                input.popFront();
                break;
            }
            case PrecedenceRelationKind.DotGreater:
            {
                auto t = precedenceStack[].retro.countUntil!(k => k == PrecedenceRelationKind.DotLess);
                if (t == -1)
                {
                    writeln("didn't find the <.??");
                    return false;
                }
                t += 1;
                auto pivot = stack.popN(t);
                precedenceStack.popN(t);

                import std.algorithm;
                auto prods = g.productions.find!(t => t.rhsIds[] == pivot[]);
                if (prods.empty)
                {
                    writeln("Shouldn't be empty");
                    return false;
                }

                auto prod = prods.front;
                auto lhsId = prod.lhsId;
                auto relation = precedenceTable[stack.top, lhsId];
                precedenceStack.push(relation);
                stack.push(lhsId);
                break;
            }
        }
    }
}

enum PrecedenceRelationKind
{
    None,
    DotEqual,
    DotLess,
    DotGreater,
    Conflict,
}

string getPrecedenceSymbolName(in Grammar g, size_t i)
{
    if (i == g.symbols.length)
        return "$";
    else
        return g.symbols[i].name;
}

auto getPrecedenceTable(in Grammar g, in OperationTable headTable, in OperationTable tailTable)
{
    import mir.ndslice;
    import std.range;
    import std.stdio;
    auto precedenceTable = slice!PrecedenceRelationKind(g.symbols.length + 1, g.symbols.length + 1);

    bool isGood = true;
    void unambiguousSet(size_t i, size_t j, PrecedenceRelationKind value)
    {
        auto p = &precedenceTable[i, j];
        if (*p == PrecedenceRelationKind.None)
        {
            *p = value;
            return;
        }
        if (*p == value)
            return;

        isGood = false;
        writeln(g.symbols[i].name, " and ", g.symbols[j].name, " have ambiguous precedence relation of ",
            getPrecedenceRelationString(value), " and ", getPrecedenceRelationString(*p));
        writeProductions(stdout.lockingTextWriter, g, i);
        writeProductions(stdout.lockingTextWriter, g, j);

        *p = PrecedenceRelationKind.Conflict;
    }

    foreach (p; g.productions)
    {
        foreach (i; 1 .. p.rhsIds.length)
        {
            size_t x = p.rhsIds[i - 1];
            size_t y = p.rhsIds[i];

            // X =. Y
            unambiguousSet(x, y, PrecedenceRelationKind.DotEqual);
            
            // X <. Head+(Y)
            foreach (headId; headTable.iterate(y))
                unambiguousSet(x, headId, PrecedenceRelationKind.DotLess);
            
            // Tail+(X) >. Head*(Y)
            foreach (tailId; tailTable.iterate(x))
            {
                foreach (headId; headTable.iterate(y).chain(only(y)))
                {
                    if (g.symbols[headId].isTerminal)
                        unambiguousSet(tailId, headId, PrecedenceRelationKind.DotGreater);
                }
            }
        }
    }
    foreach (sid; headTable.iterate(g.initialSymbolId))
        precedenceTable[g.symbols.length, sid] = PrecedenceRelationKind.DotLess;

    foreach (sid; tailTable.iterate(g.initialSymbolId))
        precedenceTable[sid, g.symbols.length] = PrecedenceRelationKind.DotGreater;

    import std.typecons;
    return isGood ? nullable(precedenceTable) : typeof(nullable(precedenceTable)).init;
}

string getPrecedenceRelationString(PrecedenceRelationKind kind)
{
    final switch (kind)
    {
        case PrecedenceRelationKind.DotEqual:
            return "=";
        case PrecedenceRelationKind.DotGreater:
            return ">";
        case PrecedenceRelationKind.DotLess:
            return "<";
        case PrecedenceRelationKind.None:
            return " ";
        case PrecedenceRelationKind.Conflict:
            return "?";
    }
}

import mir.ndslice : Slice;
alias PrecedenceTable = Slice!(PrecedenceRelationKind*, 2);
void writePrecedenceTable(TWriter)(auto ref TWriter w, in Grammar g, PrecedenceTable precedenceTable)
{
    import std.algorithm;
    size_t length = g.symbols[].map!(s => s.name.length).maxElement + 1;

    import std.format.write;

    w.formattedWrite!"%*c"(length, ' ');
    foreach (i, s; g.symbols)
        w.formattedWrite!"|%*s"(length, s.name);
    w.formattedWrite!"|%*s"(length, "$");

    foreach (i; 0 .. g.symbols.length + 1)
    {
        w.put("\n");
        w.formattedWrite!"%*s"(length, g.getPrecedenceSymbolName(i));
        auto row = precedenceTable[i,];
        foreach (relationKind; row)
            w.formattedWrite!"|%*s"(length, getPrecedenceRelationString(relationKind));
    }
    w.put("\n");
}

OperationTable makeNoEpsilonOperationTable(alias getRhsElementOperation)(in Grammar g)
{
    auto resultTable = OperationTable(g.symbols.length, g.symbols.length);

    auto tempTable = OperationTable(g.symbols.length, 1);
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
        
        foreach (p; g.symbols[t].productions)
        {
            size_t h = getRhsElementOperation(p.rhsIds);
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

auto interlace(T...)(auto ref T args)
{
    import std.algorithm;
    import std.range;
    return zip(args).map!(t => only(t.expand)).joiner;
}
