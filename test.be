fun fib( a: int ,b:int  ) : int {

    dbg a;
    dbg b;

    ret a;
} 

fun main() : int {
    if 1 {
        dbg 1;
    } else {
        dbg 2;
    }
    fib( 1 , 2);
}