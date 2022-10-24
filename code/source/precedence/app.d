module app;

import precedence.grammar;

import std.stdio;
import std.algorithm;
import std.range;

void main(string[] args)
{
    if (args.length == 1)
    {
        writeln("Usage: ", args[0], " grammar");
        writeln("grammar can be a path to a grammar text file, or one of the following: ",
            "lab3-example, wiki-example-1", "wiki-example-2");
        writeln("Example grammar file:");
        writeln("A --> a B c | D e F");
        writeln("B --> D | c");
        writeln("F --> a");
        return;
    }

    Grammar g;
    string grammarPath = args[1];
    switch (grammarPath)
    {
        case "lab3-example":
        {
            // 1. S→A  2. A→B  3. A→AcB  4. B→a  5. B →b 6. B→dD  7. D→Ae
            g.addProduction("S", ["A"]);
            g.addProduction("A", ["B"]);
            g.addProduction("A", ["A", "c", "B"]);
            g.addProduction("B", ["a"]);
            g.addProduction("B", ["b"]);
            g.addProduction("B", ["d", "D"]);
            g.addProduction("D", ["A", "e"]);
            break;
        }
        case "wiki-example-1":
        {
            // Example from wiki
            // https://www.wikiwand.com/en/Wirth%E2%80%93Weber_precedence_relationship#/Examples
            g.addProduction("S", ["a", "S", "S", "b"]);
            g.addProduction("S", ["c"]);
            break;
        }
        case "wiki-example-2":
        {
            // Example from wiki
            // https://www.wikiwand.com/en/Simple_precedence_parser#/Example
            g.addProduction("E", ["E", "+", "T'"]);
            g.addProduction("E", ["T'"]);
            g.addProduction("T'", ["T"]);
            g.addProduction("T", ["T", "*", "F"]);
            g.addProduction("T", ["F"]);
            g.addProduction("F", ["(", "E'", ")"]);
            g.addProduction("F", ["num"]);
            g.addProduction("E'", ["E"]);
            break;
        }
        default:
        {
            auto maybeGrammar = parseGrammarFile(grammarPath);
            if (maybeGrammar.isNull)
                return;
            g = maybeGrammar.get();
            break;
        }
    }
    
    bool hasEpsilonProductions = g.checkForEpsilonProductions();
    bool hasUnreachableSymbols = g.checkForUnreachableSymbols();
    bool hasUnproductiveSymbols = g.checkForUnproductiveSymbols();

    auto headTable = makeOperationTable!(rhsIds => rhsIds[0])(g);
    auto tailTable = makeOperationTable!(rhsIds => rhsIds[$ - 1])(g);

    foreach (p; g.productions)
        writeProduction(stdout.lockingTextWriter, g, p.lhsId, p.rhsIds);
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

    writeln(padRight("Stack", ' ', 50), "  ", padRight("Input", ' ', 50));
    while (true)
    {
        auto fid = input.front;

        {
            auto i = input[].map!(i => g.getPrecedenceSymbolName(i)).joiner(" ");
            auto a = stack[].map!(s => getPrecedenceSymbolName(g, s));
            auto b = precedenceStack[].map!(k => getPrecedenceRelationString(k));
            auto s = a.take(1).chain(b.interlace(a.drop(1))).joiner(" ");
            writeln(padRight(s, ' ', 50), "  ", padRight(i, ' ', 50));
        }

        if (input.front == eof
            && stack[] == [eof, g.initialSymbolId])
        {
            return true;
        }

        PrecedenceRelationKind relationKind = precedenceTable[stack.top, fid];
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

static struct OperationTable
{
    import std.bitmanip;
    size_t[] _memory;
    size_t _dimensionBits;
    size_t _dimensionSizeTs;

    // this(size_t[] memory, size_t dimensionBits)
    // {
    //     import std.algorithm;
    //     _memory = memory;
    //     _dimensionBits = dimensionBits;
    // }

    this(size_t dimensionBits, size_t numRows)
    {
        import std.algorithm;
        import sharedd.helper;
        _dimensionSizeTs = ceilDivide(dimensionBits, 8 * size_t.sizeof);
        _memory = new size_t[](_dimensionSizeTs * numRows);
        _dimensionBits = dimensionBits;
    }
    
    inout(size_t[]) getSlice(size_t id) inout
    {
        return _memory[id * _dimensionSizeTs .. (id + 1) * _dimensionSizeTs];
    }

    inout(BitArray) getBitArray(size_t id) inout
    {
        return inout(BitArray)(cast(void[]) getSlice(id), _dimensionBits);
    }

    auto iterate(size_t id) inout
    {
        import core.bitop;
        return BitRange(getSlice(id).ptr, _dimensionBits);
    }

    void writeTo(TWriter)(auto ref TWriter w, in Grammar g, string funcName)
    {
        import std.format.write;
        import std.range;
        foreach (i, s; g.symbols)
        {
            w.formattedWrite!"%s(%s) = {"(funcName, s.name);
            foreach (index, j; getBitArray(i).bitsSet.enumerate)
            {
                if (index != 0)
                    w.put(", ");
                w.put(g.symbols[j].name);
            }
            w.put("}\n");
        }
    }
}

static OperationTable makeOperationTable(alias getRhsElementOperation)(in Grammar g)
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
            auto h = getRhsElementOperation(p.rhsIds);
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

static struct Stack(T)
{
    T[] _underlyingArray = null;
    size_t _currentLength = 0;

    auto opSlice(this This)()
    {
        return _underlyingArray[0 .. _currentLength];
    }
    void push(V : T)(auto ref V el)
    {
        import std.algorithm;
        if (_underlyingArray.length <= _currentLength)
            _underlyingArray.length = max(_underlyingArray.length * 2, 1);
        _underlyingArray[_currentLength++] = el;
    }
    void pop()
    {
        _currentLength--;
    }
    T[] popN(size_t i)
    {
        size_t prev = _currentLength;
        assert(_currentLength >= i);
        _currentLength -= i;
        return _underlyingArray[_currentLength .. prev];
    }
    bool empty() const
    {
        return _currentLength == 0;
    }
    ref inout(T) top() inout
    {
        assert(_currentLength > 0);
        return _underlyingArray[_currentLength - 1];
    }
    size_t length() const
    {
        return _currentLength;
    }
}