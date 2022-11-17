module ll1.app;

import sharedd.grammar;
import sharedd.helper;

import std.stdio;
import std.algorithm;
import std.range;
import std.typecons : Nullable, nullable;

void main(string[] args)
{
    if (args.length == 1)
    {
        writeln("Usage: ", args[0], " grammar-path");
        writeln("Example grammar file:");
        writeln("A --> a B c | D e F");
        writeln("B --> D | c");
        writeln("F --> a");
        return;
    }

    string grammarPath = args[1];
    auto maybeGrammarBuilder = parseGrammarFile(grammarPath);
    if (maybeGrammarBuilder.isNull)
        return;
    auto grammarBuilder = maybeGrammarBuilder.get();
    bool addEpsilon = true;
    auto maybeGrammar = grammarBuilder.build(addEpsilon);
    if (maybeGrammar.isNull)
        return;
    const(Grammar) g = maybeGrammar.get();
    
    auto firstTable = makeFirstTable(g);

    // This is not ideal, might alocate a few more size_t's than necessary.
    size_t[] tokenMask = bitMemory(g.symbols.length);
    setBitRange(tokenMask, g.numNonTerminals, g.symbols.length, true);
    clearBit(tokenMask, g.epsilonId);
    auto followTable = makeFollowTable(g, firstTable, tokenMask);
    
    writeProductions(stdout.lockingTextWriter, g);
    firstTable.writeTo(stdout.lockingTextWriter, g, "First");
    followTable.writeTo(stdout.lockingTextWriter, i => getPrecedenceSymbolName(g, i), "Follow");

    {
        auto ll1Result = buildLL1Table(g, tokenMask, firstTable, followTable);
        auto ll1 = &ll1Result.ll1;
        writeLL1Table(g, *ll1);

        if (!ll1Result.isValid)
            return;

        while (true)
        {
            import std.string;
            
            write("Enter input: ");
            string inputLine = readln().strip;

            auto maybeInput = tokenize(g, inputLine);
            if (maybeInput.isNull)
                continue;
            size_t[] input = maybeInput.get();
            
            SyntaxTree syntaxTree = matchInput(g, *ll1, input);
            foreach (index, node; syntaxTree.nodes)
            {
                write("A", index, "(\"", g.symbols[node.symbolId].name, "\")");
                if (node.children.length > 0)
                {
                    write(" --");
                    if (false
                        && node.productionIndex != SpecialProduction.none)
                    {
                        write(`"`);
                        writeEpsilonProduction(g, node.symbolId, node.productionIndex);
                        write(`"--`);
                    }
                    write("> ");
                    foreach (childIndex, childId; node.children)
                    {
                        write("A", childId);
                        if (childIndex != node.children.length - 1)
                            write(" & ");
                    }
                }
                writeln();
            }
            {
                void printTree(const(SyntaxNode)* node, string indentation)
                {
                    auto symbol = g.symbols[node.symbolId];
                    write(indentation);
                    write(symbol.name);
                    if (node.productionIndex != SpecialProduction.none)
                    {
                        write(" matched production: ");
                        writeEpsilonProduction(g, node.symbolId, node.productionIndex);
                    }
                    writeln();
                    indentation ~= "  ";
                    foreach (size_t childIndex; node.children)
                        printTree(&syntaxTree.nodes[childIndex], indentation);
                }

                printTree(syntaxTree.root, "");
                writeln();
            }
        }
    }
}

import sharedd.parsing;


static struct SyntaxNode
{
    ssize_t productionIndex = SpecialProduction.none;
    size_t[] children;
    ssize_t parent;
    size_t symbolId;
}

static struct SyntaxTree
{
    SyntaxNode[] nodes;
    enum size_t rootIndex = 0;

    const(SyntaxNode)* root() const
    {
        return &nodes[rootIndex];
    }

    this(size_t initialCapacity, size_t initialSymbolId)
    {
        nodes ~= SyntaxNode(SpecialProduction.none, null, -1, initialSymbolId); 
    }

    const(size_t)[] addNodes(T)(size_t parent, size_t productionIndex, auto ref T range)
    {
        nodes[parent].productionIndex = productionIndex;
        
        foreach (size_t childSymbolId; range)
        {
            nodes[parent].children ~= nodes.length;
            nodes ~= SyntaxNode(SpecialProduction.none, null, parent, childSymbolId);
        }

        return nodes[parent].children;
    }

    const(size_t)[] addEpsilonNode(size_t parent, size_t epsilonId, ssize_t epsilonRuleIndex = SpecialProduction.epsilon)
    {
        nodes[parent].productionIndex = epsilonRuleIndex;
        nodes[parent].children ~= nodes.length;
        nodes ~= SyntaxNode(SpecialProduction.none, null, parent, epsilonId);
        return nodes[parent].children;
    }
}

SyntaxTree matchInput(in Grammar g, in LL1Table ll1, const(size_t)[] input)
{
    import std.algorithm;
    import std.range;
    import std.array;
    import std.stdio;

    static struct StackItem
    {
        size_t symbolId;
        size_t nodeId;
    }

    Stack!StackItem stack;
    auto syntaxTree = SyntaxTree(input.length * 2, g.initialSymbolId);
    stack.push(StackItem(g.initialSymbolId, size_t(0)));

    static struct RuleApplication
    {
        size_t lhsId;
        ssize_t productionIndex;
    }
    // auto appliedRules = appender!(RuleApplication[]);

    void writeParsingState()
    {
        import std.string;
        auto i = input[].map!(i => g.getPrecedenceSymbolName(i)).joiner(" ");
        auto s = stack[].map!(s => getPrecedenceSymbolName(g, s.symbolId)).joiner(" ");
        writeln(padRight(s, ' ', 50), "  ", padRight(i, ' ', 50));
    }

    writeln(padRight("Stack", ' ', 50), "  ", padRight("Input", ' ', 50));
    OuterLoop: while (!input.empty)
    {
        writeParsingState();

        size_t token = input.front;
        auto top = stack.pop();
        if (top.symbolId == token)
        {
            input.popFront();
            continue;
        }

        auto symbol = g.symbols[top.symbolId];
        if (symbol.isTerminal)
        {
            writeln("Unexpected symbol '", g.symbols[token].name,
                "' while expecting a '", symbol.name, "'");
            return syntaxTree;
        }
        
        ssize_t productionIndex = ll1.table[g.getNonTerminalIndex(top.symbolId), g.getTerminalIndex(token)];
        switch (productionIndex)
        {
            case SpecialProduction.none:
            {
                writeln("Not matched");
                return syntaxTree;
            }
            case SpecialProduction.epsilon:
            {
                syntaxTree.addEpsilonNode(top.nodeId, g.epsilonId);
                if (stack.empty)
                {
                    writeln("Input didn't match fully.");
                    return syntaxTree;
                }
                break;
            }
            default:
            {
                auto production = symbol.productions[productionIndex];
                auto childNodeIds = syntaxTree.addNodes(top.nodeId, productionIndex, production.rhsIds);

                foreach (rhsId, childNodeId; production.rhsIds[].zip(childNodeIds[]).retro)
                    stack.push(StackItem(rhsId, childNodeId));

                break;
            }
        }

        // appliedRules ~= RuleApplication(top.symbolId, productionIndex);
    }

    // Apply final epsilon rules.
    while (!stack.empty)
    {
        writeParsingState();

        auto top = stack.pop();
        auto productions = g.symbols[top.symbolId].productions;
        auto epsilonRuleIndex = productions.countUntil!(p => p.rhsIds == [g.epsilonId]);
        if (epsilonRuleIndex == -1)
        {
            writeln("Final stack does not collapse, didn't match.");
            return syntaxTree;
        }

        syntaxTree.addEpsilonNode(top.nodeId, g.epsilonId, epsilonRuleIndex);
    }

    return syntaxTree;
}


OperationTable makeFirstTable(in Grammar g)
{
    const numSymbols = g.symbols.length;

    auto resultTable = OperationTable(numSymbols, numSymbols);
    auto temp = bitMemory(numSymbols);

    import std.container : DList;
    auto queue = DList!size_t();
    foreach (i, s; g.symbols)
    {
        if (!s.isTerminal)
            queue ~= i;
        else
            resultTable.getBitArray(i)[i] = true;
    } 

    while (!queue.empty)
    {
        size_t t = queue.front;
        queue.removeFront();
        temp[] = 0;

        productionLoop: foreach (p; g.symbols[t].productions)
        {
            size_t h = p.rhsIds[0];

            import std.bitmanip;
            if (g.hasEpsilon)
            {
                if (p.rhsIds.length == 1 && h == g.epsilonId)
                {
                    setBit(temp, g.epsilonId);
                    continue;
                }

                BitArray other;
                while ((other = resultTable.getBitArray(h))[g.epsilonId])
                {
                    other[g.epsilonId] = false;
                    temp[] |= resultTable.getSlice(h)[];
                    other[g.epsilonId] = true;
                    h += 1;

                    // Went off the array
                    if (h == p.rhsIds.length)
                    {
                        setBit(temp, g.epsilonId);
                        continue productionLoop;
                    }
                }
            }

            // The thing at h is not an epsilon.
            setBit(temp, h);
            temp[] |= resultTable.getSlice(h)[];
        }
        
        // whichever things were new.
        temp[] &= ~resultTable.getSlice(t)[];
        
        // Some new stuff was added.
        if (!iterateSetBits(temp, numSymbols).empty)
        {
            queue ~= t;
            resultTable.getSlice(t)[] |= temp[];
        }
    }

    return resultTable;
}

// http://www.cs.ecu.edu/karl/5220/spr16/Notes/Top-down/follow.html
OperationTable makeFollowTable(in Grammar g, in OperationTable firstTable, const(size_t)[] tokenMask)
{
    const eofId = g.symbols.length;
    const numSymbols = g.symbols.length + 1;
    auto resultTable = OperationTable(numSymbols, g.numNonTerminals);

    // 1. Add $ to FOLLOW(S), where S is the start nonterminal.
    resultTable.getBitArray(g.initialNonTerminalIndex)[eofId] = true;

    import std.container : DList;
    auto queue = DList!size_t();
    foreach (i, s; g.symbols)
    {
        if (!s.isTerminal)
            queue ~= i;
    }

    size_t[] temp = bitMemory(numSymbols);
    size_t[] hasBeenQueued = bitMemory(numSymbols);
    assert(!getBit(tokenMask, g.epsilonId));

    while (!queue.empty)
    {
        size_t aid = queue.front;
        size_t aIndex = g.getNonTerminalIndex(aid);
        queue.removeFront();
        clearBit(hasBeenQueued, aid);

        productionLoop: foreach (p; g.symbols[aid].productions)
        {
            auto rhsIds = p.rhsIds;

            import std.typecons : No;
            foreach (chunk; rhsIds.slide!(No.withPartial)(2))
            {
                size_t bIndex = g.getNonTerminalIndex(chunk[0]);

                if (g.symbols[chunk[0]].isTerminal)
                    continue;

                // 2. If there is a production A → αBβ,
                // then add every token that is in FIRST(β) to FOLLOW(B).
                // Do not add ε to FOLLOW(B). 
                {
                    auto B = resultTable.getSlice(bIndex);
                    auto beta = firstTable.getSlice(chunk[1]);

                    temp[0 .. beta.length] = beta[] & tokenMask[];
                    
                    // 4. If there is a production A → αBβ where FIRST(β) contains ε,
                    // then add all members of FOLLOW(A) to FOLLOW(B).
                    // (Reasoning is like rule 3. Just erase β.)
                    if (getBit(beta, g.epsilonId))
                    {
                        auto A = resultTable.getSlice(aIndex);
                        temp[] |= A[];
                    }

                    temp[] &= ~B[];

                    if (temp.any!(s => s != 0) && !setBit(hasBeenQueued, bIndex))
                    {
                        B[] |= temp[];
                        queue ~= bIndex;
                    }
                }
            }

            // 3. If there is a production A → αB, then add all members of FOLLOW(A) to FOLLOW(B).
            // (If t can follow A, then there must be a sentential form β A t γ
            // Using production A → αB gives sentential form β α B t γ, where B is followed by t.)
            if (!g.symbols[rhsIds[$ - 1]].isTerminal)
            {
                const bIdex = g.getNonTerminalIndex(rhsIds[$ - 1]);
                auto A = resultTable.getSlice(aIndex);
                auto B = resultTable.getSlice(bIdex);
                temp[] = A[] & ~B[];

                if (temp.any!(s => s != 0) && !setBit(hasBeenQueued, bIdex))
                {
                    B[] |= A[];
                    queue ~= bIdex;
                }
            }
        }
    }

    return resultTable;
}

string getPrecedenceSymbolName(in Grammar g, size_t i)
{
    if (i == g.symbols.length)
        return "$";
    else
        return g.symbols[i].name;
}

import mir.ndslice : Slice, slice;

struct LL1Table
{
    size_t eofTableIndex;
    Slice!(ssize_t*, 2) table;
}

enum SpecialProduction : ssize_t
{
    none = -1,
    epsilon = -2,
}


auto buildLL1Table(TWriter)( 
    in Grammar g,
    const(size_t)[] tokenMask,
    in OperationTable firstTable,
    in OperationTable followTable,
    auto ref TWriter errorHandler = stdout.lockingTextWriter)
{
    struct Result
    {
        LL1Table ll1;
        bool isValid;
    }
    auto table = slice!ssize_t(g.numNonTerminals, g.numTerminals);
    size_t eofTableIndex = g.epsilonId;

    table[] = SpecialProduction.none;

    bool isError = false;
    void assignMaybeError(size_t lhsId, size_t rhsId, size_t productionIndex)
    {
        size_t rhsIndex;
        // $ = epsilon? still not sure.
        // if (rhsId == eofId)
        //     rhsId = g.epsilonId;
        // else
            rhsIndex = g.getTerminalIndex(rhsId);
        
        ssize_t* indexInTable = &table[lhsId, rhsIndex];
        if (*indexInTable == SpecialProduction.none)
        {
            *indexInTable = productionIndex;
            return;
        }
        if (*indexInTable == productionIndex)
            return;

        auto productions = g.symbols[lhsId].productions;
        if (productionIndex == SpecialProduction.epsilon
            && productions[*indexInTable].rhsIds == [g.epsilonId])
        {
            return;
        }
        if (*indexInTable == SpecialProduction.epsilon
            && productions[productionIndex].rhsIds == [g.epsilonId])
        {
            *indexInTable = productionIndex;
            return;
        }

        {
            errorHandler.put("This grammar is not an LL(1) grammar: Rule collision:\n");

            import std.format;
            writeEpsilonProduction(g, lhsId, productionIndex, errorHandler);
            writeln();
            writeEpsilonProduction(g, lhsId, *indexInTable, errorHandler);
            writeln();
            isError = true;
        }
    }

    size_t[] temp = bitMemory(g.symbols.length + 1);

    foreach (lhsId, lhsSymbol; g.symbols)
    {
        foreach (productionIndex, production; lhsSymbol.productions)
        {
            auto rhsIds = production.rhsIds;
            auto rhsFirst = firstTable.getSlice(rhsIds[0]);
            auto followA = followTable.getSlice(lhsId);

            temp[] = rhsFirst[] & tokenMask[];
            foreach (terminalId; iterateSetBits(temp, g.symbols.length))
                assignMaybeError(lhsId, terminalId, productionIndex);

            if (getBit(rhsFirst, g.epsilonId))
            {
                temp[] = followA[] & tokenMask[];
                foreach (terminalId; iterateSetBits(temp, g.symbols.length))
                    assignMaybeError(lhsId, terminalId, SpecialProduction.epsilon);

                if (getBit(followA, g.eofId))
                    assignMaybeError(lhsId, eofTableIndex, SpecialProduction.epsilon);
            }
        }
    }

    Result result;
    result.ll1 = LL1Table(eofTableIndex, table);
    result.isValid = !isError;

    return result;
}

size_t eofId(in Grammar g) { return g.symbols.length; }


void writeLL1Table(in Grammar g, in LL1Table ll1)
{
    import std.range;
    import std.algorithm;
    auto terminalColumns = g.iterateTerminals;
    auto nonTerminalRows = g.nonTerminals;
    
    auto strings = g.symbols[].enumerate.map!((s)
    {
        return s.value.productions.map!((p)
        {
            auto app = appender!string;
            writeProduction(app, g, s.index, p.rhsIds);
            return app[];
        }).array;
    }).array;

    size_t cellWidth = strings.joiner.map!(s => s.length).maxElement;
    size_t leftWidth = nonTerminalRows.map!(s => s.name.length).maxElement;

    write(' '.repeat(leftWidth));
    foreach (s; terminalColumns)
        writef!"|%*s"(cellWidth, s.id == g.epsilonId ? "$" : s.name);
    writeln();
    foreach (irow, s; nonTerminalRows.enumerate)
    {
        writef!"%*s"(leftWidth, s.name);
        foreach (icol, t; terminalColumns.enumerate)
        {
            const v = ll1.table[irow, icol];
            switch (v)
            {
                case SpecialProduction.none:
                {
                    write("|", ' '.repeat(cellWidth));
                    break;
                }
                case SpecialProduction.epsilon:
                {
                    writef!"|%*s"(cellWidth, g.symbols[irow].name ~ " --> eps");
                    break;
                }
                default:
                {
                    writef!"|%*s"(cellWidth, strings[irow][v]);
                    break;
                }
            }
        }
        writeln();
    }
}


void writeEpsilonProduction(TWriter)(
    in Grammar g,
    size_t lhsId,
    ssize_t productionIndex,
    auto ref TWriter w = stdout.lockingTextWriter)
{
    import std.format;
    auto productions = g.symbols[lhsId].productions;
    if (productionIndex == SpecialProduction.epsilon)
    {
        w.formattedWrite!"%s --> eps"(g.symbols[lhsId].name);
    }
    else
    {
        const(size_t)[] rhsIds = productions[productionIndex].rhsIds;
        writeProduction(w, g, lhsId, rhsIds);
    }
}