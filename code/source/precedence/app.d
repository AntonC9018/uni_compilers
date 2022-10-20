module app;

struct Production
{
    size_t[] rhsIds;
}

struct Symbol
{
    string name;
    Production[] productions = null;

    bool isTerminal() const { return productions.length == 0; }
}

struct Grammar
{
    Symbol[] symbols;

    auto productions(this This)()
    {
        static struct ProductionInfo
        {
            size_t lhsId;
            typeof(This.symbols[0].productions[0].rhsIds) rhsIds;
        }
        import std.algorithm;
        import std.range;
        return symbols[]
            .enumerate
            .map!(t => t.value.productions
                .map!(p => ProductionInfo(t.index, p.rhsIds)))
            .joiner;
    }
}


size_t addOrGetSymbolId(ref Grammar g, string name)
{
    import std.algorithm;
    auto id = g.symbols.countUntil!(t => t.name == name);
    if (id == -1)
    {
        id = g.symbols.length;
        g.symbols ~= Symbol(name);
    }
    return cast(size_t) id;
}

void addProduction(ref Grammar g, size_t lhsId, const(string)[] rhs)
{
    size_t[] rhsIds;
    foreach (symbolName; rhs)
    {
        size_t id = g.addOrGetSymbolId(symbolName);
        rhsIds ~= id;
    }
    g.symbols[lhsId].productions ~= Production(rhsIds);
}

void writeProduction(TWriter)(auto ref TWriter w, in Grammar g, size_t lhs, const(size_t)[] rhs)
{
    import std.format.write;
    w.put(g.symbols[lhs].name);
    w.put(" --> ");
    foreach (s; rhs)
        w.put(g.symbols[s].name);
    w.put("\n");
}

void writeProductions(TWriter)(auto ref TWriter w, in Grammar g, size_t lhs)
{
    foreach (p1; g.symbols[lhs].productions)
        writeProduction(w, g, lhs, p1.rhsIds);
}

void addProduction(ref Grammar g, string lhs, const(string)[] rhs)
{
    addProduction(g, g.addOrGetSymbolId(lhs), rhs);
}

void main(string[] args)
{
    Grammar g;
    // 1. S→A  2. A→B  3. A→AcB  4. B→a  5. B →b 6. B→dD  7. D→Ae
    // g.addProduction("S", ["A"]);
    // g.addProduction("A", ["B"]);
    // g.addProduction("A", ["A", "c", "B"]);
    // g.addProduction("B", ["a"]);
    // g.addProduction("B", ["b"]);
    // g.addProduction("B", ["d", "D"]);
    // g.addProduction("D", ["A", "e"]);
    g.addProduction("S", ["a", "S", "S", "b"]);
    g.addProduction("S", ["c"]);


    import std.stdio;
    import std.algorithm;
    import std.range;
    
    // Check epsilon rules
    bool hasEpsilonProductions =
    (){
        bool isBad = false;
        foreach (s; g.symbols)
        foreach (p; s.productions)
        {
            if (p.rhsIds.length == 0)
            {
                isBad = true;
                writeln("Epsilon productions are not allowed, at ", 
                    s.name, " --> eps");
            }
        }
        return isBad;
    }();

    bool hasUnreachableSymbols =
    (){
        import mir.ndslice;
        auto metSymbol = bitSlice(g.symbols.length);
        size_t[] toProcess = [0];
        metSymbol[0] = true;
        while (toProcess.length != 0)
        {
            size_t t = toProcess[$ - 1];
            toProcess = toProcess[0 .. $ - 1];
            foreach (p; g.symbols[t].productions)
            {
                foreach (rhsSymbolId; p.rhsIds)
                {
                    if (metSymbol[rhsSymbolId])
                        continue;
                    metSymbol[rhsSymbolId] = true;
                    toProcess ~= rhsSymbolId;
                }
            }
        }
        bool isBad = false;
        foreach (size_t index, bool met; metSymbol[].enumerate)
        {
            if (!met)
            {
                writeln("Symbol ", g.symbols[index].name, " is unreachable.");
                isBad = true;
            }
        }
        return isBad;
    }();

    bool hasUnproductiveSymbols =
    (){
        import mir.ndslice;
        auto metSymbol = bitSlice(g.symbols.length);
        int prevCount = 0;
        int newCount = 0;
        foreach (id, s; g.symbols)
        {
            if (s.isTerminal)
            {
                newCount += 1;
                metSymbol[id] = true;
            }
        }
        
        while (prevCount != newCount)
        {
            prevCount = newCount;
            foreach (id, s; g.symbols)
            {
                if (metSymbol[id])
                    continue;

                foreach (p; s.productions)
                {
                    bool allRhsAreProductive = p.rhsIds[].all!(rhsIndex => metSymbol[rhsIndex]);
                    if (allRhsAreProductive)
                    {
                        metSymbol[id] = true;
                        newCount += 1;
                        break;
                    }
                }
            }
        }

        bool isBad = false;
        foreach (size_t index, bool met; metSymbol[].enumerate)
        {
            if (!met)
            {
                writeln("Symbol ", g.symbols[index].name, " is unproductive.");
                isBad = true;
            }
        }
        return isBad;
    }();

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
        write("Enter input: ");
        string inputLine = readln();

        string input = inputLine;
        import std.sumtype;

        alias StackEl = SumType!(size_t, PrecedenceRelationKind);
        StackEl[] stack;

        // stack ~= StackEl(size_t.max);
        while (true)
        {
            auto f = input.front;
            // TODO: tokenize in a normal way.
            auto fid = g.symbols[].countUntil!(a => a.isTerminal && a.name[0] == f);
            if (fid == -1)
            {
                writeln(f, " didn't match a terminal.");
                return;
            }

            import std.string;
            writeln("Input: ", input.strip, "; Stack: ", stack);
            
            PrecedenceRelationKind getRelationKindFromStack()
            {
                if (stack.empty)
                {
                    // $ <. Head+(S)
                    if (headTable.getBitArrayOf(0)[fid])
                    {
                        return PrecedenceRelationKind.DotLess;
                    }
                    else
                    {
                        writeln("Not alowed");
                        return PrecedenceRelationKind.None;
                    }
                }
                else
                {
                    auto top = stack[$ - 1];
                    return precedenceTable[top.get!size_t(), fid];
                }
            }
            PrecedenceRelationKind relationKind = getRelationKindFromStack();

            final switch (relationKind)
            {
                case PrecedenceRelationKind.None:
                {
                    writeln("Precedence relation none, shouldn't happen. Probably input doesn't match.");
                    return;
                }
                case PrecedenceRelationKind.DotLess:
                case PrecedenceRelationKind.DotEqual:
                {
                    stack ~= StackEl(relationKind);
                    stack ~= StackEl(fid);
                    input.popFront();
                    break;
                }

                case PrecedenceRelationKind.DotGreater:
                {
                    int i = cast(int) stack.length;
                    for (; i >= 0; i--)
                    {
                        if (stack[i].match!(
                            (PrecedenceRelationKind k) => k == PrecedenceRelationKind.DotLess,
                            _ => false))
                        {
                            break;
                        }
                    }
                    if (i == -1)
                    {
                        writeln("didn't find the <.??");
                        return;
                    }
                    auto pivot = stack[i .. $];

                    import std.array;
                    auto pivotIds = appender!(size_t[]);
                    foreach (p; pivot[])
                        p.tryMatch!((size_t id) => pivotIds ~= id);

                    import std.algorithm;
                    auto prods = g.productions.find!(t => t.rhsIds[] == pivotIds[]);
                    if (prods.empty)
                    {
                        writeln("Shouldn't be empty");
                        return;
                    }

                    auto prod = prods.front;
                    auto lhsId = prod.lhsId;

                    // import std.range;
                    // auto relations = pivot[].retro.find!(t => t.canMatch!((PrecedenceRelationKind k){}));
                    // if (relations.empty)
                    // {
                    //     writeln("Shouldn't be empty 2.");
                    //     return;
                    // }

                    PrecedenceRelationKind getRelationKindFromStack2()
                    {
                        if (stack.empty)
                        {
                            // $ <. Head+(S)
                            if (tailTable.getBitArrayOf(0)[lhsId])
                            {
                                return PrecedenceRelationKind.DotGreater;
                            }
                            else
                            {
                                writeln("Not alowed");
                                return PrecedenceRelationKind.None;
                            }
                        }
                        else
                        {
                            auto top = stack[$ - 1];
                            return precedenceTable[lhsId, top.get!size_t()];
                        }
                    }

                    auto relation = getRelationKindFromStack2();
                    stack ~= StackEl(relation);
                    stack ~= StackEl(lhsId);
                    break;
                }
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
}

auto getPrecedenceTable(in Grammar g, in OperationTable headTable, in OperationTable tailTable)
{
    import mir.ndslice;
    import std.stdio;
    auto precedenceTable = slice!PrecedenceRelationKind(g.symbols.length, g.symbols.length);

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
        writeln(g.symbols[i].name, " and ", g.symbols[j].name, " have ambiguous precedence relation of ", value, " and ", *p);
        writeProductions(stdout.lockingTextWriter, g, i);
        writeProductions(stdout.lockingTextWriter, g, j);
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
                if (g.symbols[y].isTerminal)
                    unambiguousSet(tailId, y, PrecedenceRelationKind.DotGreater);

                foreach (headId; headTable.iterate(y))
                {
                    if (g.symbols[headId].isTerminal)
                        continue;
                    unambiguousSet(tailId, headId, PrecedenceRelationKind.DotGreater);
                }
            }
        }
    }

    import std.typecons;
    return isGood ? nullable(precedenceTable) : typeof(nullable(precedenceTable)).init;
}

import mir.ndslice : Slice;
void writePrecedenceTable(TWriter)(auto ref TWriter w, in Grammar g, Slice!(PrecedenceRelationKind*, 2) precedenceTable)
{
    static string getRelationString(PrecedenceRelationKind kind)
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
        }
    }

    import std.algorithm;
    size_t length = g.symbols[].map!(s => s.name.length).maxElement + 1;

    import std.format.write;

    w.formattedWrite!"%*c"(length, ' ');
    foreach (i, s; g.symbols)
        w.formattedWrite!"|%*s"(length, s.name);

    foreach (i; 0 .. g.symbols.length)
    {
        w.put("\n");
        w.formattedWrite!"%*s"(length, g.symbols[i].name);
        auto row = precedenceTable[i,];
        foreach (relationKind; row)
            w.formattedWrite!"|%*s"(length, getRelationString(relationKind));
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
        _dimensionSizeTs = max(dimensionBits / (8 * size_t.sizeof), 1);
        _memory = new size_t[](_dimensionSizeTs * numRows);
        _dimensionBits = dimensionBits;
    }
    
    inout(size_t[]) getSliceOf(size_t id) inout
    {
        return _memory[id * _dimensionSizeTs .. (id + 1) * _dimensionSizeTs];
    }

    inout(BitArray) getBitArrayOf(size_t id) inout
    {
        return inout(BitArray)(cast(void[]) getSliceOf(id), _dimensionBits);
    }

    auto iterate(size_t id) inout
    {
        return getBitArrayOf(id).bitsSet;
    }

    void writeTo(TWriter)(auto ref TWriter w, in Grammar g, string funcName)
    {
        import std.format.write;
        import std.range;
        foreach (i, s; g.symbols)
        {
            w.formattedWrite!"%s(%s) = {"(funcName, s.name);
            foreach (index, j; getBitArrayOf(i).bitsSet.enumerate)
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
    auto tempArray1 = tempTable.getBitArrayOf(0);
    auto tempBuffer1 = tempTable.getSliceOf(0);

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
            tempBuffer1[] |= resultTable.getSliceOf(h)[];
        }
        
        // whichever things were new.
        tempBuffer1[] &= ~resultTable.getSliceOf(t)[];
        
        // Some new stuff was added.
        if (!tempArray1.bitsSet.empty)
        {
            queue ~= t;
            resultTable.getSliceOf(t)[] |= tempBuffer1[];
        }
    }

    return resultTable;
}

import std.sumtype;
auto get(V, T)(inout T sumtype)
    if (is(T : SumType!(K), K...))
{
    return sumtype.match!(
        (inout ref V v) => v,
        (_) { assert(false, "Unexpected thing"); return V.init; }
    );
}