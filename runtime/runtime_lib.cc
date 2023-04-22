#include <cstdio>

extern "C" void printi(long long int i) {
    printf("%lld\n", i);
}
extern "C"  void printi2(int i)
{
    printf("%d\n", i);
}
extern "C" void printi3(short i)
{
    printf("%hd\n", i);
}