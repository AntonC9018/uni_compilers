module sharedd.grammar;

alias ssize_t = ptrdiff_t;

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

struct GrammarBuilder
{
    Symbol[] _symbols;
    size_t[string] _symbolIndexMap;
}

struct Grammar
{
    Symbol[] symbols;
    size_t[string] indexMap;
    size_t numNonTerminals;
    ssize_t epsilonId;
    enum size_t initialSymbolId = 0;
    enum size_t initialNonTerminalIndex = 0;

    bool hasEpsilon() const
    {
        return epsilonId >= 0;
    }

    auto productions() const
    {
        import std.algorithm;
        import std.range;
        import std.typecons;
        return symbols[]
            .enumerate
            .map!(t => t.value.productions
                .map!(p => tuple!("lhsId", "rhsIds")(t.index, p.rhsIds)))
            .joiner;
    }

    const(Symbol)[] terminals() const
    {
        return symbols[numNonTerminals .. $];
    }

    size_t numTerminals() const
    {
        return symbols.length - numNonTerminals;
    }

    size_t getTerminalIndex(size_t id) const
    {
        assert(id >= numNonTerminals);
        return id - numNonTerminals;
    }

    size_t getNonTerminalIndex(size_t id) const
    {
        return id;
    }

    auto iterateTerminals() const
    {
        import std.range;
        import std.algorithm;
        import std.typecons;
        return symbols[]
            .enumerate
            .drop(numNonTerminals)
            .map!(t => tuple!("id", "name")(t.index, t.value.name));
    }

    const(Symbol)[] nonTerminals() const
    {
        return symbols[0 .. numNonTerminals];
    }
}

size_t addOrGetSymbolId(ref GrammarBuilder g, string name)
{
    import std.algorithm;

    if (const idp = name in g._symbolIndexMap)
        return *idp;
    
    const id = g._symbols.length;
    g._symbols ~= Symbol(name);
    g._symbolIndexMap[name] = id;
    return id;
}

void addProduction(ref GrammarBuilder g, size_t lhsId, scope const(string)[] rhs)
{
    size_t[] rhsIds;
    foreach (symbolName; rhs)
    {
        size_t id = g.addOrGetSymbolId(symbolName);
        rhsIds ~= id;
    }
    g._symbols[lhsId].productions ~= Production(rhsIds);
}

Nullable!(const(Grammar)) build(alias errorHandler = writeln)(ref GrammarBuilder g, bool addEpsilon = false)
{
    import std.algorithm;
    import std.range;
    import std.array;

    // Maybe add another function for this?
    ssize_t epsilonId = g._symbols[].countUntil!(s => s.name == "eps");
    if (epsilonId == -1 && addEpsilon)
    {
        epsilonId = g._symbols.length;
        g._symbols ~= Symbol("eps", null);
    }
    if (epsilonId != -1)
    {
        if (g._symbols[epsilonId].productions.length != 0)
        {
            errorHandler("The epsilon symbol must not contain any productions.");
            return typeof(return).init;
        }

        if (g._symbols
            .map!(s => s.productions)
            .joiner
            .map!(p => p.rhsIds)
            .any!((rhsIds) => rhsIds.length > 1
                && rhsIds[].count(epsilonId) != 0))
        {
            writeln("If a production contains an epsilon, it must be the only symbol.");
            return typeof(return).init;
        }
    }

    size_t[] idMap;
    idMap.length = g._symbols.length;

    size_t indexCounter = 0;
    foreach (sid, s; g._symbols)
    {
        if (!s.isTerminal)
            idMap[sid] = indexCounter++;
    }
    size_t numNonTerminals = indexCounter;
    foreach (sid, s; g._symbols)
    {
        if (s.isTerminal && s.name != "eps")
            idMap[sid] = indexCounter++;
    }
    if (epsilonId != -1)
        idMap[epsilonId] = indexCounter++;

    auto newSymbols = new Symbol[](g._symbols.length);
    foreach (sid, s; g._symbols)
    {
        const newId = idMap[sid];
        Production[] newProductions = s.productions
            .map!(p => 
                Production(p.rhsIds
                    .map!(rhsId => idMap[rhsId])
                    .array))
            .array;
        newSymbols[newId] = Symbol(s.name, newProductions);
    }

    size_t[string] indexMap;
    foreach (name, id; g._symbolIndexMap)
        indexMap[name] = idMap[id];

    size_t mappedEpsId = epsilonId;
    if (mappedEpsId != -1)
        mappedEpsId = newSymbols.length - 1;

    return nullable(const Grammar(newSymbols, indexMap, numNonTerminals, mappedEpsId));
}

void writeProduction(TWriter)(auto ref TWriter w, in Grammar g, size_t lhs, scope const(size_t)[] rhs)
{
    import std.format.write;
    w.put(g.symbols[lhs].name);
    w.put(" --> ");
    foreach (i, s; rhs)
    {
        w.put(g.symbols[s].name);
        if (i != rhs.length - 1)
            w.put(' ');
    }
}

void writeProductions(TWriter)(auto ref TWriter w, in Grammar g, size_t lhs)
{
    foreach (p1; g.symbols[lhs].productions)
    {
        writeProduction(w, g, lhs, p1.rhsIds);
        w.put("\n");
    }
}

void writeProductions(TWriter)(auto ref TWriter w, in Grammar g)
{
    foreach (p1; g.productions)
    {
        writeProduction(w, g, p1.lhsId, p1.rhsIds);
        w.put("\n");
    }
}

void addProduction(ref GrammarBuilder g, string lhs, scope const(string)[] rhs)
{
    addProduction(g, g.addOrGetSymbolId(lhs), rhs);
}

import std.stdio;

bool checkForEpsilonProductions(alias errorHandler = writeln)(in Grammar g)
{
    bool isBad = false;
    foreach (s; g.symbols)
    foreach (p; s.productions)
    {
        if (p.rhsIds.length == 0)
        {
            isBad = true;
            errorHandler("Epsilon productions are not allowed, at ", 
                s.name, " --> eps");
        }
    }
    return isBad;
}

bool checkForUnreachableSymbols(alias errorHandler = writeln)(in Grammar g)
{
    // NOTE: bitSlice is kinda bad, should use core.bitop
    import mir.ndslice;
    import std.stdio;
    import std.range;

    auto metSymbol = bitSlice(g.symbols.length);
    size_t[] toProcess = [g.initialSymbolId];
    metSymbol[g.initialSymbolId] = true;
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
            errorHandler("Symbol ", g.symbols[index].name, " is unreachable.");
            isBad = true;
        }
    }
    return isBad;
}


bool checkForUnproductiveSymbols(alias errorHandler = writeln)(in Grammar g)
{
    // NOTE: bitSlice is kinda bad, should use core.bitop
    import mir.ndslice;
    import std.stdio;
    import std.range;

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
            errorHandler("Symbol ", g.symbols[index].name, " is unproductive.");
            isBad = true;
        }
    }
    return isBad;
}

import std.typecons : Nullable, nullable;
Nullable!(size_t[]) tokenize(const Grammar g, string input)
{
    import std.range;
    import std.string;
    import std.algorithm;
    import std.stdio;

    auto tokens = appender!(size_t[]);
    int index = 0;

    while (index != input.length)
    {
        bool matched = false;
        foreach (length; 1 .. input.length - index + 1)
        {
            auto slice = input[index .. index + length];
            if (auto tid = slice in g.indexMap)
            {
                tokens ~= *tid;
                index += length;
                matched = true;
                break;
            }
        }

        if (!matched)
        {
            writeln("Bad input around '", input[0 .. index], "'",
                ". Expected one of ", g.terminals.map!(t => t.name).join(','), " got ", input[index .. $]);
            return typeof(return).init;
        }
    }
    return nullable(tokens[]);
}

Nullable!GrammarBuilder parseGrammarFile(string fileName)
{
    import std.stdio;
    import std.file;
    if (!exists(fileName))
    {
        writeln("The file ", fileName, " does not exist.");
        return typeof(return).init;
    }
    return File(fileName).byLineCopy.parseGrammar;
}

import std.range;

Nullable!GrammarBuilder parseGrammar(TLineRange)(TLineRange lines)
    if (isInputRange!TLineRange && is(ElementType!TLineRange : string))
{
    import std.range;
    import std.stdio;
    import std.string;
    import std.algorithm;
    import std.uni;
    
    GrammarBuilder g;
    bool isGood = true;
    foreach (lineIndex, line; lines.map!(l => l.strip).enumerate)
    {
        if (line.startsWith("//"))
            continue;

        void skipWhitespace(T)(ref T range)
        {
            while (!range.empty)
            {
                if (!isWhite(range.front))
                    break;
                range.popFront();
            }
        }
        string input = line;
        skipWhitespace(input);

        size_t nonTerminalLength = 0;
        while (nonTerminalLength < input.length
            && input[nonTerminalLength] != '-'
            && !isWhite(input[nonTerminalLength]))
        {
            nonTerminalLength++;
        }

        if (nonTerminalLength == 0)
        {
            writeln("Terminal expected at ", input, " line ", lineIndex + 1);
            isGood = false;
            continue;
        }

        string lhsSymbol = input[0 .. nonTerminalLength];
        input = input[nonTerminalLength .. $];
        skipWhitespace(input);

        if (input.length == 0 || !input.startsWith("-->"))
        {
            writeln("Expected an arrow --> at ", input, " ", lineIndex + 1);
            isGood = false;
            continue;
        }

        input = input["-->".length .. $];
        skipWhitespace(input);

        size_t lhsId = g.addOrGetSymbolId(lhsSymbol);
        foreach (production; input[]
            .splitter("|")
            .map!(p => p.strip
                .splitter(" ")
                .map!(s => s.strip)
                .map!(s => g.addOrGetSymbolId(s))
                .array))
        {
            g._symbols[lhsId].productions ~= Production(production);
        }
    }

    // // The epsilon is not implicitly defined.
    // auto epsIndex = g.symbols[].countUntil!(s => s.name == "eps");
    // if (epsIndex != -1)
    //     g.symbols[epsIndex].productions ~= [];

    if (!isGood)
        return typeof(return).init;

    return nullable(g);
}