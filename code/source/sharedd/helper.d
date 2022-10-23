module sharedd.helper;

size_t ceilDivide(size_t a, size_t b)
{
    return (a + b - 1) / b;
}