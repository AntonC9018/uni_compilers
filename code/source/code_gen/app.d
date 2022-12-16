import std.stdio;
import acd.arithmetic;

void main(string[] args)
{
    import std.getopt;

    size_t numRegisters = 2;
    string inputExpression;

    auto result = getopt(args,
        "r|maxregisters|numregisters|registers", "Number of registers to use", &numRegisters,
        "e|expression|expr", "Expression to parse", &inputExpression
    );
    bool help = result.helpWanted;

    if (inputExpression == "")
    {
        help = true;
        writeln("Expecting an expression.");
    }

    if (help)
    {
        defaultGetoptPrinter("codegen", result.options);
        return;
    }


    // The default operators include the basic arithmetic operators.
    OperatorGroup[] operatorGroups = createDefaultOperatorGroups();

    auto expressionTree = parseExpression(inputExpression, operatorGroups);
    if (expressionTree.thereHaveBeenErrors || expressionTree.root is null)
    {
        writeln("Error parsing expression");
        return;
    }

    // Prints the expression back in text form.
    writeExpression(expressionTree.root);

    writeln("Mermaid diagram:");
    auto mermaid = new MermadDiagramSyntaxWalker();
    mermaid.walk(expressionTree.root);

    auto lattributeWalker = new AssignAttributesSyntaxWalker();
    lattributeWalker.walk(expressionTree.root);

    {
        writeln("L Attributes:");
        foreach (node, l; lattributeWalker.ls.map)
        {
            writef!`A%s: %s`(mermaid.getId(node), l);
            if (node.kind == SyntaxNodeKind.identifier)
                writef!` (%s)`((cast(IdentifierNode*) node).name);
            writeln();
        }
    }

    auto codeGenerator = new CodeGenerationSyntaxWalker(lattributeWalker.ls, numRegisters);
    codeGenerator.walk(expressionTree.root);
    auto instructions = codeGenerator.output[];

    writeln("Code:");
    writeCode(instructions, numRegisters);
}

struct IdMap(T)
{
    size_t[T] _map;

    size_t get(T value)
    {
        if (size_t* p = value in _map)
            return *p;
        return _map[value] = _map.length;
    }
}

inout(SyntaxNode)* getKey(inout(SyntaxNode)* node)
{
    while (node.kind == SyntaxNodeKind.parenthesizedExpression)
        node = (cast(inout(ParenthesizedExpressionNode)*) node).innerExpression;
    return node;
}

string getNodeText(SyntaxNode* node)
{
    switch (node.kind)
    {
        case SyntaxNodeKind.identifier:
            return (cast(IdentifierNode*) node).name;
        case SyntaxNodeKind.integerLiteral:
        case SyntaxNodeKind.floatLiteral:
            return (cast(LiteralNode*) node).token.text;
        case SyntaxNodeKind.operator:
            return (cast(OperatorNode*) node).operator.name;
        default:
            return "";
    }
}

class MermadDiagramSyntaxWalker : SyntaxWalker
{
    IdMap!(const(SyntaxNode)*) nodeIds;

    size_t getId(const(SyntaxNode)* node)
    {
        return nodeIds.get(getKey(node));
    }

    override void visit(OperatorNode* node)
    {
        size_t id = getId(node.asSyntaxNode);
        write("A", id, " --> ");
        foreach (i; 0 .. node.operands.length)
        {
            size_t operandId = getId(node.operands[i]);
            write("A", operandId);
            if (i < node.operands.length - 1)
                write(" & ");
        }
        writeln();
        super.visit(node);
    }

    override void visit(SyntaxNode* node)
    {
        size_t id = getId(node);
        string value = getNodeText(node);

        if (value != "")
            writefln!`A%s("%s (A%s)")`(id, value, id);

        return super.visit(node);
    }
}

struct AttributeMap
{
    int[const SyntaxNode*] map;

    int getl(const(SyntaxNode)* node, int default_ = 0)
    {
        node = getKey(node);
        if (int* p = node in map)
            return *p;
        return map[node] = default_;
    }

    int setl(const SyntaxNode* node, int value)
    {
        return map[getKey(node)] = value;
    }
}

class AssignAttributesSyntaxWalker : SyntaxWalker
{
    AttributeMap ls;

    override void visit(OperatorNode* node)
    {
        super.visit(node);

        import std.algorithm : max;
        int left = ls.getl(node.operands[0], 1);
        int right = ls.getl(node.operands[1], 0);

        if (left == right)
            ls.setl(node.asSyntaxNode, left + 1);
        else
            ls.setl(node.asSyntaxNode, max(left, right));
    }
}

import std.sumtype;
struct Instruction
{
    Operator* operator;
    bool isMov() const { return operator is null; }

    size_t lhs;
    SumType!(size_t, SyntaxNode*) rhs;
}

Instruction instruction(Operator* op, size_t lhs, size_t rhs)
{
    return Instruction(op, lhs, typeof(Instruction.rhs)(rhs));
}

Instruction instruction(Operator* op, size_t lhs, SyntaxNode* value)
{
    return Instruction(op, lhs, typeof(Instruction.rhs)(value));
}

Instruction mov(size_t lhs, size_t rhs)
{
    return Instruction(null, lhs, typeof(Instruction.rhs)(rhs));
}

Instruction mov(size_t lhs, SyntaxNode* value)
{
    return Instruction(null, lhs, typeof(Instruction.rhs)(value));
}

void writeCode(scope Instruction[] instructions, size_t maxRegister)
{
    foreach (i; instructions)
    {
        string name;
        if (i.isMov())
        {
            name = "mov";
        }
        else switch (i.operator.name)
        {
            case "+": name = "add"; break;
            case "-": name = "sub"; break;
            case "*": name = "mul"; break;
            case "/": name = "div"; break;
            default: assert(0);
        }

        void writeRegOrMem(size_t id)
        {
            if (id < maxRegister)
                write("R", id + 1);
            else
                write("Mem", id - maxRegister + 1);
        }

        write(name, " ");
        writeRegOrMem(i.lhs);
        write(", ");
        i.rhs.match!(
            (size_t id) => writeRegOrMem(id),
            (SyntaxNode* node) => write(getNodeText(node))
        );
        write(";");

        writeln();
    }
}

class CodeGenerationSyntaxWalker : SyntaxWalker
{
    import std.array;

    AttributeMap ls;
    size_t currentRegister;
    size_t numRegisters;
    size_t currentMemory;
    Appender!(Instruction[]) output; 

    this(AttributeMap ls, size_t maxRegisters)
    {
        currentRegister = 0;
        this.ls = ls;
        this.numRegisters = maxRegisters;
        this.output = Appender!(Instruction[])();
        currentMemory = maxRegisters;
    }

    override void visit(OperatorNode* node)
    {
        import std.algorithm : maxIndex, maxElement;

        int left = ls.getl(node.operands[0]);
        int right = ls.getl(node.operands[1]);

        assert(left != 0);
        if (right == 0)
        {
            super.visit(node.operands[0]);

            import std.algorithm;
            SyntaxNode* rightTerminalNode = getKey(node.operands[1]);
            assert([
                SyntaxNodeKind.floatLiteral,
                SyntaxNodeKind.identifier,
                SyntaxNodeKind.integerLiteral,
            ].canFind(rightTerminalNode.kind));

            output ~= instruction(node.operator, currentRegister, rightTerminalNode);
            return;
        }

        int[2] values = [left, right];
        size_t largestIndex = maxIndex([left, right]);
        int largest = values[largestIndex];

        void doWithMemory(size_t computedFirstIndex)
        {
            assert(computedFirstIndex == 0, "The other case is never used.");

            super.visit(node.operands[computedFirstIndex]);
            output ~= mov(currentMemory, currentRegister);

            currentMemory++;
            super.visit(node.operands[1 - computedFirstIndex]);
            currentMemory--;

            // If the left one was done first, the output will be computed into the memory,
            // and then copied into the register.
            // NOTE: I think hardware usually prohibits subtracting from memory directly,
            //       but has an instruction for swapping memory with a register, so that could be used instead.
            // if (computedFirstIndex == 1)
            // {
            //     output ~= instruction(node.operator, currentMemory, currentRegister);
            //     output ~= mov(currentRegister, currentMemory);
            // }

            // The left output is in the register, so just do the operation with the memory as the rhs.
            // else
            {
                output ~= instruction(node.operator, currentRegister, currentMemory);
            }
        }

        void doWithRegisters(size_t computedFirstIndex)
        {
            size_t computedSecondIndex = 1 - computedFirstIndex;

            // the output will be written into R_currentRegister
            super.visit(node.operands[computedFirstIndex]);
            
            currentRegister++;
            super.visit(node.operands[computedSecondIndex]);
            currentRegister--;

            // If the right one was done first, then we have to swap the registers at the end,
            // and perform the operation with them swapped too.
            if (computedFirstIndex == 1)
            {
                output ~= instruction(node.operator, currentRegister + 1, currentRegister);
                output ~= mov(currentRegister, currentRegister + 1);
            }
            // If the left one was done first, the output will be computed into the first register.
            else
            {
                output ~= instruction(node.operator, currentRegister, currentRegister + 1);
            }
        }

        // If the calculations can be fully done in registers, do them from left to right.
        if (largest + currentRegister < numRegisters)
        {
            doWithRegisters(0);
        }

        // The largest calculation exactly fits into the registers
        else if (largest + currentRegister == numRegisters)
        {
            // Only one of the calculations can fully fit into the registers,
            // the result of which shall be saved into memory. 
            if (left == right)
            {
                doWithMemory(0);
            }
            // Both fit into memory if the largest one is done prior to the smaller one.
            else
            {
                doWithRegisters(largestIndex);
            }
        }

        // The largest calculation does not fit into the registers.
        // It doesn't matter whether the smaller one fits into memory or not,
        // we have to conserve the registers in either case.
        else
        {
            doWithMemory(0);
        }
    }

    override void visit(IdentifierNode* node)
    {
        output ~= mov(currentRegister, node.asSyntaxNode);
    }

    override void visit(IntegerLiteralNode* node)
    {
        output ~= mov(currentRegister, node.asSyntaxNode);
    }

    override void visit(FloatLiteralNode* node)
    {
        output ~= mov(currentRegister, node.asSyntaxNode);
    }
}