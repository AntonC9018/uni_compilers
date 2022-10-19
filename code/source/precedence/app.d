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

void addProduction(ref Grammar g, string lhs, const(string)[] rhs)
{
    addProduction(g, g.addOrGetSymbolId(lhs), rhs);
}

void main(string[] args)
{
    Grammar g;
    // 1. S→A  2. A→B  3. A→AcB  4. B→a  5. B →b 6. B→dD  7. D→Ae
    g.addProduction("S", ["A"]);
    g.addProduction("A", ["B"]);
    g.addProduction("A", ["A", "c", "B"]);
    g.addProduction("B", ["a"]);
    g.addProduction("B", ["b"]);
    g.addProduction("B", ["d", "D"]);
    g.addProduction("D", ["A", "e"]);


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
                    return precedenceTable[top.get!size_t().value, fid];
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
                            return precedenceTable[lhsId, top.get!size_t().value];
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
        writeln(g.symbols[i], " and ", g.symbols[j], " have ambiguous precedence relation of ", value, " and ", *p);
    }

    foreach (p; g.productions)
    {
        foreach (i; 1 .. p.rhsIds.length)
        {
            size_t j = i - 1;

            unambiguousSet(i, j, PrecedenceRelationKind.DotEqual);
            foreach (headId; headTable.iterate(j))
                unambiguousSet(i, headId, PrecedenceRelationKind.DotLess);
            
            foreach (tailId; tailTable.iterate(i))
            {
                foreach (headId; headTable.iterate(j))
                {
                    if (g.symbols[tailId].isTerminal)
                        continue;
                    unambiguousSet(tailId, headId, PrecedenceRelationKind.DotGreater);
                }
            }
        }
    }

    import std.typecons;
    return isGood ? nullable(precedenceTable) : typeof(nullable(precedenceTable)).init;
}

// S -> Aa
// A -> Bb
// B -> Sc | d


// S -> A,      A, B, S             A 
//              B, S
// A -> B       B, S, B, A          B, c
// A -> c
//              S, B, A       
// B -> S       S, S, A, S, B       
// B -> d                           S, d
//              S, A, S, B
// S -> A       S, A, S, B, B, S    A, B, c, S, d
//              A, S, B, B, S
//              S, B, B, S
// A -> B       S, B, B, S, S, A    B, c, S, d, A
//              B, B, S, S, A
//              B, S, S, A
// B -> S       B, S, S, A          S, d, A, B, c, d


// S -> A       A, S        A
//              S           
// A -> B       S, B, A     B
// A -> c                   B, c
//              B, A
// S -> A       B, A, S     A, B, c
//              A, S
// B -> S       A, S, B     S, A, B, c
// B -> d                   S, A, B, c, d
//              S, B
// A -> B       S, B, A     S, A, B, c, d
//              B, A
// S -> A       B, A, S     S, A, B, c, d

static struct OperationTable
{
    import std.bitmanip;
    size_t[] _memory;
    size_t _dimension;

    this(size_t[] memory, size_t dimension)
    {
        _memory = memory;
        _dimension = dimension;
    }

    this(size_t dimension, size_t numRows)
    {
        _memory = new size_t[](dimension * numRows);
        _dimension = dimension;
    }
    
    inout(size_t[]) getSliceOf(size_t id) inout
    {
        return _memory[id * _dimension .. (id + 1) * _dimension];
    }

    inout(BitArray) getBitArrayOf(size_t id) inout
    {
        return inout(BitArray)(cast(void[]) getSliceOf(id), _dimension);
    }

    auto iterate(size_t id) inout
    {
        return getBitArrayOf(id).bitsSet;
    }
}

static OperationTable makeOperationTable(alias getRhsElementOperation)(in Grammar g)
{
    import std.algorithm;

    size_t dimension = max(g.symbols.length / (8 * size_t.sizeof), 1);
    auto resultTable = OperationTable(dimension, dimension);

    auto tempTable = OperationTable(dimension, 3);
    auto hasBeenQueued = tempTable.getBitArrayOf(1);
    auto tempArray1 = tempTable.getBitArrayOf(2);
    auto tempArray2 = tempTable.getBitArrayOf(3);
    auto tempBuffer1 = tempTable.getSliceOf(2);
    auto tempBuffer2 = tempTable.getSliceOf(3);

    import std.container : DList;
    auto queue = DList!size_t([0]);
    while (!queue.empty)
    {
        size_t t = queue.back;
        hasBeenQueued[t] = true;
        queue.removeBack();

        tempBuffer1[] = 0;
        
        foreach (p; g.symbols[t].productions)
        {
            auto h = getRhsElementOperation(p.rhsIds);
            tempArray1[h] = true;
            tempBuffer1[] |= resultTable.getSliceOf(h)[];
        }
        
        // whichever things were new.
        // t1 &= ~h(t)
        tempBuffer2[] = resultTable.getSliceOf(t)[];
        tempArray2.flip();
        tempBuffer1[] &= tempBuffer2[];
        
        if (tempArray1.bitsSet.empty)
            continue;

        foreach (newIdIndex; tempArray1.bitsSet)
        {
            if (!hasBeenQueued[newIdIndex])
                queue ~= newIdIndex;
        }

        queue ~= t;
        resultTable.getSliceOf(t)[] = tempBuffer1[];
    }

    return resultTable;
}