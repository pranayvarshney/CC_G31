#include <cstdio>

extern "C"
void printi(long long int i) {
    printf("%lld\n", i);
}
void printi(int i)
{
    printf("%d\n", i);
}
void printi(short i)
{
    printf("%hd\n", i);
}