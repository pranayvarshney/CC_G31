fun f(a : short , j : short) : int {
    let b : long = 1;
    dbg a+j ;
}
fun main() : int {
    let k : short = 2;
    dbg f(4, 1+k);
}