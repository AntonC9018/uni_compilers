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
        return writeTo(w, i => g.symbols[i].name, funcName);
    }

    void writeTo(TWriter)(auto ref TWriter w, scope string delegate(size_t) getName, string funcName)
    {
        import std.format.write;
        import std.range;
        foreach (i; 0 .. _memory.length / _dimensionSizeTs)
        {
            w.formattedWrite!"%s(%s) = {"(funcName, getName(i));
            foreach (index, j; getBitArray(i).bitsSet.enumerate)
            {
                if (index != 0)
                    w.put(", ");
                w.put(getName(j));
            }
            w.put("}\n");
        }
    }
}


static struct Stack(T)
{
    T[] _underlyingArray = null;
    size_t _currentLength = 0;

    auto opSlice(this This)()
    {
        return _underlyingArray[0 .. _currentLength];
    }
    void push(V : T)(auto ref V el)
    {
        import std.algorithm;
        maybeGrow(_currentLength + 1);
        _underlyingArray[_currentLength++] = el;
    }
    void pushN(V)(auto ref V elements)
        if (is(ElementType!V : T))
    {
        import std.algorithm;
        maybeGrow(_currentLength + elements.length);
        foreach (i; _currentLength .. _currentLength + elements.length)
        {
            _underlyingArray[i] = elements.front;
            elements.popFront();
        }
        _currentLength += elements.length;
    }
    private void maybeGrow(size_t desiredMinimumSize)
    {
        import std.algorithm;
        if (_underlyingArray.length < desiredMinimumSize)
            _underlyingArray.length = max(_underlyingArray.length * 2, desiredMinimumSize);
    }
    T pop()
    {
        assert(_currentLength >= 1);
        return _underlyingArray[--_currentLength];
    }
    T[] popN(size_t i)
    {
        size_t prev = _currentLength;
        assert(_currentLength >= i);
        _currentLength -= i;
        return _underlyingArray[_currentLength .. prev];
    }
    bool empty() const
    {
        return _currentLength == 0;
    }
    ref inout(T) top() inout
    {
        assert(_currentLength > 0);
        return _underlyingArray[_currentLength - 1];
    }
    size_t length() const
    {
        return _currentLength;
    }
}

