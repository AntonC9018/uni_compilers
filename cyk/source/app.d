module app;

import cyk;
import std.stdio;
import pegged.grammar;

mixin(grammar(`
NormalizedGrammar:
	Line		    <  Rules / Comment
	Rules 	        <  NonTerminal "->" ProductionList
	Comment		    <- "//" ~(.*)
	ProductionList  <  Production ("|" Production)*
	NonTerminal     <- ~([A-Z][A-Z_0-9]*)
	Production      <  (NonTerminal NonTerminal) / Terminal
	Terminal        <- ~([a-z!@#$%^&*()]+)
`));

import std.typecons : Nullable, nullable;
struct Line
{
    enum Kind
    {
        Rules,
        Comment,
    }

    Kind _kind;
    ParseTree _node;

    static Nullable!Line create(ParseTree node)
    {
        enum null_ = typeof(return).init;
        if (node.children.length != 1)
            return null_;
        
        auto or = node.children[0];
        if (or.children.length != 1)
            return null_;
        
        Line line;
        line._node = node;
        switch (or.children[0].name)
        {
            case "NormalizedGrammar.Rules":
            {
                line._kind = Kind.Rules;
                break;
            }
            case "NormalizedGrammar.Comment":
            {
                line._kind = Kind.Comment;
                break;
            }
            default:
            {
                return null_;
            }
        }

        return nullable(line);
    }

    Rules rules()
    {
        auto or = _node.children[0];
        switch (_kind)
        {
            case Kind.Rules:
                return Rules.create(or.children[0]).get();
            default:
                return typeof(return).init;
        }
    }

    Comment comment()
    {
        auto or = _node.children[0];
        switch (_kind)
        {
            case Kind.Comment:
                return Comment.create(or.children[0]).get();
            default:
                return typeof(return).init;
        }
    }
}

struct Rules
{
    ParseTree _node;

    static Nullable!Rules create(ParseTree node)
    {
        enum null_ = typeof(return).init;

        if (node.children.length != 1)
            return null_;

        auto and = node.children[0];
        if (and.children.length != 3)
            return null_;

        return nullable(Rules(node));
    }

    string nonTerminal()
    {
        return _node.children[0].children[0].matches[0];
    }

    ProductionList productionList()
    {
        return ProductionList.create(_node.children[0].children[2]).get();
    }
}

struct ProductionList
{
    static Nullable!ProductionList create(ParseTree node)
    {
        return typeof(return).init;
    }
}


struct Comment
{
    static Nullable!Comment create(ParseTree node)
    {
        return typeof(return).init;
    }
}


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
        writeln("Adding terminal ", name);
        return result;
    }

    size_t addOrGetNonTerminal(string name)
    {
        if (auto p = name in symbolMap)
            return *p;
        
        size_t result = symbolMap.length;
        symbolMap[name] = result;
        productions.length = result + 1;
        writeln("Added symbol ", name);
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

        if (!parsedLine.successful)
        {
            writeln("Bad syntax on line ", lineIndex);
            writeln(parsedLine.failMsg);
            writeln(parsedLine);
            badInput = true;
            continue;
        }

		foreach (child; parsedLine.children[0])
		{
            switch (child.name)
            {
                case "NormalizedGrammar.Rules":
                {
                    // name
                    // successful
                    // matches
                    // input
                    // begin
                    // end
                    // children
                    // failEnd
                    // failedChild
                    // toString
                    // toStringThisNode
                    // failMsg

                    auto rules = child.children[0];
                    auto nonTerminal = rules.children[0].children[0];

                    string nonTerminalName = nonTerminal.matches[0];
                    size_t ntIndex = addOrGetNonTerminal(nonTerminalName);

                    void process(ParseTree prod)
                    {
                        auto symbols = prod.children[0].children[0].children;

                        // terminal
                        if (symbols.length == 1)
                        {
                            auto tindex = addOrGetTerminal(symbols[0].matches[0]);
                            productions[ntIndex] ~= Production(tindex);
                        }

                        // non-terminal
                        else
                        {
                            auto nt0 = addOrGetNonTerminal(symbols[0].matches[0]);
                            auto nt1 = addOrGetNonTerminal(symbols[1].matches[0]);
                            productions[ntIndex] ~= Production([nt0, nt1]);
                        }
                    }
                    
                    auto prodList = rules.children[2].children[0].children;
                    process(prodList[0]);

                    // (| other)*
                    auto others = prodList[1].children;
                    foreach (prod; iota(0, others.length, 2).map!(i => others[i].children[1]))
                        process(prod);

                    break;
                }

                case "NormalizedGrammar.Comment":
                    break;
                
                default:
                    assert(0);
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

    {
        import std.stdio;
        import std.string;
        
        while (true)
        {
            write("Enter word (q to quit): ");
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