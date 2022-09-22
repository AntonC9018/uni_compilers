module app;

import cyk;
import std.stdio;
import pegged.grammar;

mixin(grammar(`
NormalizedGrammar:
	Line		   <- Rules / Comment
	Rules 	       <- (NonTerminal "->" ProductionList)
	Comment		   < "//" .*
	ProductionList <- Production ("|" Production)*
	NonTerminal    < [A-Z][A-Z_0-9]*
	Production     <- (NonTerminal NonTerminal) / Terminal
	Terminal       < ![A-Z]
`));

int main(string[] args)
{
    if (args.length != 2)
    {
        writeln("Usage: program path-to-grammar");
        return 1;
    }
	
    string grammarPath = args[1];
    auto lines = File(grammarPath).byLineCopy;
    int[string] symbolMap;
    
	import std.algorithm;
	import std.string;
	import std.range;

    foreach (lineIndex, line; lines
		.map!(l => l.strip)
		.filter!(l => !l.empty)
		.enumerate)
	{
		if (line.empty)
			continue;

		auto parsedLine = NormalizedGrammar.Line(line);
		foreach (child; parsedLine)
		{
			foreach (c2; child.children)
				writeln(c2);
		}
	}
    // {
    //     import std.array;
    //     import std.range;
    //     import std.utf;

    //     bool processSingle()
    //     {
    //         if (line.empty)
    //             return true;

    //         while (isWhite(line.front))
    //         {
    //             line.popFront();
    //             if (line.empty)
    //                 return true;
    //         }

    //         while (!line.empty)
    //         {
    //             dchar ch = line.front;
    //             if (isAlpha(line.front) && isUpper(line.front))
    //             {
    //             }
    //         }
    //     }

    //     auto symbolName = appender!string;
    //     if (!processSingle())
    //         return;
    // }

    // let the input be a string I consisting of n characters: a1 ... an.
    string input = "baaba";
    Grammar grammar;

    int S = 0;
    int A = 1;
    int B = 2;
    int C = 3;
    grammar.productions.length = 4;

    alias p = Production;
    // S -> AB | BC
    grammar.productions[S] ~= [ p([A, B]), p([B, C]) ];
    // A -> BA | a
    grammar.productions[A] ~= [ p([B, A]), p('a') ];
    // B -> CC | b
    grammar.productions[B] ~= [ p([C, C]), p('b') ];
    // C -> AB | a
    grammar.productions[C] ~= [ p([A, B]), p('a') ];

    grammar.symbolNames.length = 4;
    grammar.symbolNames[S] = "S";
    grammar.symbolNames[A] = "A";
    grammar.symbolNames[B] = "B";
    grammar.symbolNames[C] = "C";

    auto derivation = getDerivation(grammar, input);
    writeln(derivation.isPartOfLanguage);
    writeDerivation(grammar, derivation);

    return 0;
}