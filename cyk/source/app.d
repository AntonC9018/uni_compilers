module app;

import cyk;
import std.stdio;
import grammar_grammar;

int main(string[] args)
{
    if (args.length != 2)
    {
        writeln("Usage: program path-to-grammar");
        return 1;
    }
	
    string grammarPath = args[1];
    auto lines = File(grammarPath).byLineCopy;
    size_t[string] symbolMap;
    size_t[string] terminalsMap;
    Production[][] productions;

    size_t addOrGetTerminal(string name)
    {
        if (auto p = name in terminalsMap)
            return *p;
        
        size_t result = terminalsMap.length;
        terminalsMap[name] = result;
        return result;
    }

    size_t addOrGetNonTerminal(string name)
    {
        if (auto p = name in symbolMap)
            return *p;
        
        size_t result = symbolMap.length;
        symbolMap[name] = result;
        productions.length = result + 1;
        return result;
    }
    
	import std.algorithm;
	import std.string;
	import std.range;

    bool badInput = false;

    foreach (lineIndex, line; lines
		.map!(l => l.strip)
		.filter!(l => !l.empty)
		.enumerate)
	{
		if (line.empty)
			continue;

		auto parsedLine = NormalizedGrammar.Line(line);
        if (parsedLine.end != line.length)
        {
            writeln("Did not parse the whole line, okay until ", line[parsedLine.end .. $],
                " (position ", parsedLine.end, ")");
            badInput = true;
            continue;
        }
        if (!parsedLine.successful)
        {
            writeln("Bad syntax on line ", lineIndex);
            writeln(parsedLine.failMsg);
            writeln(parsedLine);
            badInput = true;
            continue;
        }

        auto maybeRules = Line(parsedLine).rules;
        if (maybeRules.isNull)
            continue;
        auto rules = maybeRules.get();

        size_t ntIndex = addOrGetNonTerminal(rules.nonTerminal);

        foreach (prod; rules.productionList[])
        {
            auto terminal = prod.terminal;
            if (!terminal.isNull)
            {
                auto tindex = addOrGetTerminal(terminal.get());
                productions[ntIndex] ~= Production(tindex);
                continue;
            }

            auto nonTerminal2 = prod.nonTerminal2;
            if (!nonTerminal2.isNull)
            {
                auto nts = nonTerminal2.get();
                auto nt0 = addOrGetNonTerminal(nts[0]);
                auto nt1 = addOrGetNonTerminal(nts[1]);
                productions[ntIndex] ~= Production([nt0, nt1]);
                continue;
            }
        }
	}

    if (badInput)
        return 1;

    string[] nonTerminalNames;
    nonTerminalNames.length = symbolMap.length;
    foreach (name, index; symbolMap)
        nonTerminalNames[index] = name;

    string[] terminals;
    terminals.length = terminalsMap.length;
    foreach (name, index; terminalsMap)
        terminals[index] = name;

    Grammar grammar = Grammar(productions, terminals, nonTerminalNames);
    
    writeln("Terminals: ", terminals.join(','));

    {
        import std.stdio;
        import std.string;
        
        while (true)
        {
            write("Enter a word (q to quit): ");
            string input = readln().strip;
            if (input == "q")
                return 0;
            
            auto tokenization = tokenizeInput(grammar.terminals, input);
            if (tokenization.isNull)
                continue;

            auto derivation = getDerivation(grammar.productions, tokenization.get());
            writeln("Is part of language? ", derivation.isPartOfLanguage);
            writeDerivation(grammar, derivation);
        }
    }
}