#def DEBUG2 10
#def DEBUG 30+DEBUG2
let x = DEBUG;
#ifdef DEBUG1
let y = DEBUG1;
dbg y;
#elif DEBUG2
dbg 5;
#else
dbg 10;
#endif