module precedence.grammar;

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

    auto terminals(this This)()
    {
        import std.range;
        import std.algorithm;
        import std.typecons;
        return symbols[]
            .enumerate
            .filter!(t => t.value.isTerminal)
            .map!(t => tuple!("index", "name")(t.index, t.value.name));
    }

    enum size_t initialSymbolId = 0;
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

void addProduction(ref Grammar g, size_t lhsId, scope const(string)[] rhs)
{
    size_t[] rhsIds;
    foreach (symbolName; rhs)
    {
        size_t id = g.addOrGetSymbolId(symbolName);
        rhsIds ~= id;
    }
    g.symbols[lhsId].productions ~= Production(rhsIds);
}

void writeProduction(TWriter)(auto ref TWriter w, in Grammar g, size_t lhs, scope const(size_t)[] rhs)
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

void addProduction(ref Grammar g, string lhs, scope const(string)[] rhs)
{
    addProduction(g, g.addOrGetSymbolId(lhs), rhs);
}

bool checkForEpsilonProductions(in Grammar g)
{
    bool isBad = false;
    foreach (s; g.symbols)
    foreach (p; s.productions)
    {
        if (p.rhsIds.length == 0)
        {
            import std.stdio;
            isBad = true;
            writeln("Epsilon productions are not allowed, at ", 
                s.name, " --> eps");
        }
    }
    return isBad;
}

bool checkForUnreachableSymbols(in Grammar g)
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
            writeln("Symbol ", g.symbols[index].name, " is unreachable.");
            isBad = true;
        }
    }
    return isBad;
}


bool checkForUnproductiveSymbols(in Grammar g)
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
            writeln("Symbol ", g.symbols[index].name, " is unproductive.");
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
        foreach (tid, terminal; g.terminals)
        {
            if (input[index .. $].startsWith(terminal))
            {
                tokens ~= tid;
                index += terminal.length;
                matched = true;
                break;
            }
        }

        if (!matched)
        {
            writeln("Bad input around ", input[0 .. index],
                ". Expected one of ", g.terminals.map!(t => t.name).join(','), " got ", input[index .. $]);
            return typeof(return).init;
        }
    }
    return nullable(tokens[]);
}

Nullable!Grammar parseGrammarFile(string fileName)
{
    import std.stdio;
    return File(fileName).byLineCopy.parseGrammar;
}

import std.range;

Nullable!Grammar parseGrammar(TLineRange)(TLineRange lines)
    if (isInputRange!TLineRange && is(ElementType!TLineRange : string))
{
    import std.range;
    import std.stdio;
    import std.string;
    import std.algorithm;
    import std.uni;
    
    Grammar g;
    bool isGood = true;
    foreach (lineIndex, line; lines.map!(l => l.strip).enumerate)
    {
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
            g.symbols[lhsId].productions ~= Production(production);
        }
    }

    if (!isGood)
        return typeof(return).init;

    return nullable(g);
}