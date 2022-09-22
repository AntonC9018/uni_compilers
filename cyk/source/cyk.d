module cyk;

import std.stdio;
import std.sumtype;

alias Production = SumType!(int[2], char);

// let the grammar contain r nonterminal symbols R1 ... Rr, with start symbol R1.
static struct Grammar
{
    Production[][] productions;
    string[] symbolNames;
}

struct Triple
{
    int[3] indices;
}

import mir.ndslice;

struct Derivation
{
    Slice!(bool*, 3) P;
    Slice!(Triple[]*, 3) back;
    bool isPartOfLanguage() const { return P[$ - 1, 0, 0]; }
}

Derivation getDerivation(Grammar grammar, string input)
{
    int n = cast(int) input.length;
    int r = cast(int) grammar.productions.length;

    // let P[n,n,r] be an array of booleans. Initialize all elements of P to false.
    auto P = slice!bool(n, n, r);

    // let back[n,n,r] be an array of lists of backpointing triples.
    // Initialize all elements of back to the empty list.
    auto back = slice!(Triple[])(n, n, r);

    // for each s = 1 to n
    //     for each unit production Rv → as
    //         set P[1,s,v] = true
    foreach (s, char inputChar; input)
    {
        foreach (v, Production[] productions; grammar.productions)
        {
            foreach (Production p; productions)
            {
                if (p.match!(
                    (char c) => inputChar == c,
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
                foreach (nonTerminalSymbolIndex, Production[] productions; grammar.productions)
                {
                    foreach (Production production; productions)
                    {
                        production.match!(
                            (int[2] indices)
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
    return Derivation(P, back);
}


void writeDerivation(Grammar grammar, in Derivation d)
{
    import std.algorithm;
    import std.range;

    string[][] things = new string[][d.P.length];
    int maxLength = int.min;
    foreach (rowIndex, ref row; things)
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
            maxLength = max(maxLength, cast(int) cell.length);
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