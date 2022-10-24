module grammar_grammar;

import pegged.grammar;

            import std.stdio;


mixin(grammar(`
NormalizedGrammar:
	Line		    <  Rules / Comment
	Rules 	        <  NonTerminal "-->" ProductionList
	Comment		    <- "//" ~(.*)
	ProductionList  <  Production ("|" Production)*
	NonTerminal     <- ~([A-Z][a-zA-Z_0-9]*)
	Production      <  (NonTerminal NonTerminal) / Terminal
	Terminal        <- ~((!("|") .)+)
`));

import std.typecons : Nullable, nullable, tuple, Tuple;

struct Line
{
    enum Kind
    {
        Rules,
        Comment,
    }

    Kind _kind;
    ParseTree _node;

    this(ParseTree node)
    {
        assert(node.children.length == 1);

        auto or = node.children[0];
        assert(or.children.length == 1);
        
        _node = node;
        switch (or.children[0].name)
        {
            case "NormalizedGrammar.Rules":
            {
                _kind = Kind.Rules;
                break;
            }
            case "NormalizedGrammar.Comment":
            {
                _kind = Kind.Comment;
                break;
            }
            default:
                assert(0);
        }
    }

    Nullable!Rules rules() 
    {
        auto or = _node.children[0];
        switch (_kind)
        {
            case Kind.Rules:
                return nullable(Rules(or.children[0]));
            default:
                return typeof(return).init;
        }
    }

    Nullable!Comment comment()
    {
        auto or = _node.children[0];
        switch (_kind)
        {
            case Kind.Comment:
                return nullable(Comment(or.children[0]));
            default:
                return typeof(return).init;
        }
    }
}

struct Rules
{
    ParseTree _node;

    this(ParseTree node)
    {
        assert(node.children.length == 1);

        auto and = node.children[0];
        assert(and.children.length == 3);

        _node = node;
    }

    string nonTerminal()
    {
        return _node.children[0].children[0].matches[0];
    }

    ProductionList productionList()
    {
        return ProductionList(_node.children[0].children[2]);
    }
}

struct ProductionList
{
    ParseTree _node;
    ParseTree _first;
    Nullable!ParseTree _oneOrMore;

    this(ParseTree node)
    {
        assert(node.children.length == 1);
        auto and = node.children[0];

        _first = and[0][0];
        if (and.children.length > 1)
            _oneOrMore = nullable(and[1]);
        _node = node;
    }

    size_t opDollar()
    {
        return _oneOrMore.isNull ? 1 : _oneOrMore.get().children.length / 2 + 1;
    }

    ProductionSyntax opIndex(size_t index)
    {
        if (index == 0)
            return ProductionSyntax(_first);

        return ProductionSyntax(_oneOrMore.get()[index - 1][1]);
    }

    auto opSlice()
    {
        import std.range;
        import std.algorithm;

        return only(_first)
            .chain(
                iota(0, _oneOrMore.isNull ? 0 : _oneOrMore.get().children.length)
                    .map!(i => _oneOrMore.get()[i][1][0]))
            .map!(e => ProductionSyntax(e));
    }
}

struct ProductionSyntax
{
    enum Kind
    {
        NonTerminal_NonTerminal,
        Terminal,
    }

    Kind _kind;
    ParseTree _node;
    ParseTree[] _children;

    this(ParseTree node)
    {
        _node = node;

        auto children = node.children[0].children;
        if (children.length == 1)
            _kind = Kind.Terminal;
        else if (children.length == 2)
            _kind = Kind.NonTerminal_NonTerminal;
        else
            assert(0);

        _children = children;
    }

    Nullable!(Tuple!(string, string)) nonTerminal2()
    {
        switch (_kind)
        {
            case Kind.NonTerminal_NonTerminal:
                return nullable(tuple(
                    _children[0][0].matches[0],
                    _children[1][0].matches[0]));
            default:
                return typeof(return).init;
        }
    }

    Nullable!string terminal()
    {
        switch (_kind)
        {
            case Kind.Terminal:
                return nullable(_children[0].matches[0]);
            default:
                return typeof(return).init;
        }
    }
}

struct Comment
{
    ParseTree _node;
}