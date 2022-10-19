module cyk;

import std.stdio;
import std.sumtype;

alias Production = SumType!(size_t[2], size_t);

// let the grammar contain r nonterminal symbols R1 ... Rr, with start symbol R1.
static struct Grammar
{
    Production[][] productions;
    string[] terminals;
    string[] symbolNames;
}

struct Triple
{
    size_t[3] indices;
}

import mir.ndslice;

struct Derivation
{
    const(size_t)[] tokenizedInput;
    import std.traits : ReturnType;
    ReturnType!(bitSlice!3) P;
    Slice!(Triple[]*, 3) back;
    bool isPartOfLanguage() const { return P[$ - 1, 0, 0]; }
}

import std.typecons : Nullable, nullable;

Nullable!(size_t[]) tokenizeInput(const(string)[] terminals, string input)
{
    import std.range;
    import std.string;

    auto tokens = appender!(size_t[]);
    int index = 0;

    while (index < input.length)
    {
        bool matched = false;
        foreach (tindex, terminal; terminals)
        {
            if (input[index .. $].startsWith(terminal))
            {
                tokens ~= tindex;
                index += terminal.length;
                matched = true;
                break;
            }
        }

        if (!matched)
        {
            import std.algorithm;
            writeln("Bad input around ", input[0 .. index],
                ". Expected one of ", terminals.join(','), " got ", input[index .. $]);
            return typeof(return).init;
        }
    }
    return nullable(tokens[]);
}

Derivation getDerivation(const typeof(Grammar.productions) productions, const(size_t)[] tokenizedInput)
{
    int n = cast(int) tokenizedInput.length;
    int r = cast(int) productions.length;

    // let P[n,n,r] be an array of booleans. Initialize all elements of P to false.
    auto P = bitSlice(n, n, r);

    // let back[n,n,r] be an array of lists of backpointing triples.
    // Initialize all elements of back to the empty list.
    auto back = slice!(Triple[])(n, n, r);

    // for each s = 1 to n
    //     for each unit production Rv → as
    //         set P[1,s,v] = true
    foreach (s, size_t token; tokenizedInput)
    {
        foreach (v, const(Production)[] prods; productions)
        {
            foreach (Production p; prods)
            {
                if (p.match!(
                    (size_t outToken) => token == outToken,
                    _ => false
                ))
                {
                    P[0, s, v] = true;
                }
            }
        }
    }

    // for each l = 2 to n -- Length of span
    //     for each s = 1 to n-l+1 -- Start of span
    //         for each p = 1 to l-1 -- Partition of span
    //             for each production Ra    → Rb Rc
    //                 if P[p,s,b] and P[l-p,s+p,c] then
    //                     set P[l,s,a] = true, 
    //                     append <p,b,c> to back[l,s,a]

    // all rows, except the first one
    foreach (rowIndex; 1 .. n)
    {
        // all columns, the max decreasing by one each row
        foreach (colIndex; 0 .. n - rowIndex)
        {
            // all previous rows
            foreach (prevRowIndex; 0 .. rowIndex)
            {
                foreach (nonTerminalSymbolIndex, const(Production)[] prods; productions)
                {
                    foreach (Production prod; prods)
                    {
                        prod.match!(
                            (size_t[2] indices)
                            {
                                bool aboveSet = P[prevRowIndex, colIndex, indices[0]];
                                bool diagonalSet = P[rowIndex - prevRowIndex - 1, colIndex + prevRowIndex + 1, indices[1]];
                                if (aboveSet && diagonalSet)
                                {
                                    P[rowIndex, colIndex, nonTerminalSymbolIndex] = true;
                                    back[rowIndex, colIndex, nonTerminalSymbolIndex] ~= Triple([prevRowIndex, indices[0], indices[1]]);
                                }
                            },
                            (_){}
                        );
                    }
                }
            }
        }
    }    

    // if P[n,1,1] is true then
    //     I is member of language
    //     return back -- by retracing the steps through back, one can easily construct all possible parse trees of the string.
    // else
    //     return "not a member of language"
    return Derivation(tokenizedInput, P, back);
}


void writeDerivation(Grammar grammar, in Derivation d)
{
    import std.algorithm;
    import std.range;

    string[][] things = new string[][d.P.length + 1];
    size_t maxLength = size_t.min;

    things[0].length = d.tokenizedInput.length;
    foreach (tokenIndex, ref token; things[0])
    {
        token = grammar.terminals[d.tokenizedInput[tokenIndex]];
        maxLength = max(maxLength, token.length);
    }

    foreach (rowIndex, ref row; things[1 .. $])
    {
        row.length = d.P.length - rowIndex;

        foreach (colIndex, ref cell; row)
        {
            foreach (size_t i, bool isSet; d.P[rowIndex, colIndex].enumerate)
            {
                if (isSet)
                {
                    if (cell.length != 0)
                        cell ~= ",";
                    cell ~= grammar.symbolNames[i];
                }
            }
            maxLength = max(maxLength, cell.length);
        }
    }

    foreach (rowIndex, row; things)
    {
        foreach (colIndex, cell; row)
        {
            write("|");
            write(cell);
            foreach (i; cell.length .. maxLength)
                write(" "); 
        }
        write("\n");
    }
    
}