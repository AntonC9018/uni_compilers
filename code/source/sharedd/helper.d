module sharedd.helper;

size_t ceilDivide(size_t a, size_t b)
{
    return (a + b - 1) / b;
}

import core.bitop;
int getBit(const(size_t)[] slice, size_t bitIndex)
{
    assert(slice.length * size_t.sizeof * 8 > bitIndex);
    return bt(slice.ptr, bitIndex);
}

int clearBit(size_t[] slice, size_t bitIndex)
{
    assert(slice.length * size_t.sizeof * 8 > bitIndex);
    return btr(slice.ptr, bitIndex);
}

int setBit(size_t[] slice, size_t bitIndex, bool value)
{
    assert(slice.length * size_t.sizeof * 8 > bitIndex);
    if (value)
        return bts(slice.ptr, bitIndex);
    else
        return btr(slice.ptr, bitIndex);
}

int setBit(size_t[] slice, size_t bitIndex)
{
    assert(slice.length * size_t.sizeof * 8 > bitIndex);
    return bts(slice.ptr, bitIndex);
}

size_t getBitMemoryLength(size_t numBits)
{
    return ceilDivide(numBits, size_t.sizeof * 8);
}

size_t[] bitMemory(size_t numBits)
{
    return new size_t[](getBitMemoryLength(numBits));
}

void setBitRange(size_t[] slice, size_t bitFrom, size_t bitTo, bool value)
{
    import std.bitmanip;
    BitArray(cast(void[]) slice, bitTo)[bitFrom .. bitTo] = value;
}

size_t getChunkOfBit(size_t bitIndex)
{
    return bitIndex / (size_t.sizeof * 8);
}

BitRange iterateSetBits(size_t[] slice, size_t length)
{
    assert(slice.length * size_t.sizeof * 8 >= length);
    return BitRange(slice.ptr, length);
}