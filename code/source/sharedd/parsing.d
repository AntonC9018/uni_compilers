module sharedd.parsing;

import sharedd.grammar;

struct OperationTable
{
    import std.bitmanip;
    size_t[] _memory;
    size_t _dimensionBits;
    size_t _dimensionSizeTs;

    // this(size_t[] memory, size_t dimensionBits)
    // {
    //     import std.algorithm;
    //     _memory = memory;
    //     _dimensionBits = dimensionBits;
    // }

    this(size_t dimensionBits, size_t numRows)
    {
        import std.algorithm;
        import sharedd.helper;
        _dimensionSizeTs = ceilDivide(dimensionBits, 8 * size_t.sizeof);
        _memory = new size_t[](_dimensionSizeTs * numRows);
        _dimensionBits = dimensionBits;
    }
    
    inout(size_t[]) getSlice(size_t id) inout
    {
        return _memory[id * _dimensionSizeTs .. (id + 1) * _dimensionSizeTs];
    }

    inout(BitArray) getBitArray(size_t id) inout
    {
        return inout(BitArray)(cast(void[]) getSlice(id), _dimensionBits);
    }

    auto iterate(size_t id) inout
    {
        import core.bitop;
        return BitRange(getSlice(id).ptr, _dimensionBits);
    }

    void writeTo(TWriter)(auto ref TWriter w, in Grammar g, string funcName)
    {
        import std.format.write;
        import std.range;
        foreach (i, s; g.symbols)
        {
            w.formattedWrite!"%s(%s) = {"(funcName, s.name);
            foreach (index, j; getBitArray(i).bitsSet.enumerate)
            {
                if (index != 0)
                    w.put(", ");
                w.put(g.symbols[j].name);
            }
            w.put("}\n");
        }
    }
}


