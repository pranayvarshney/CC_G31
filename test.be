fun f(a:int) : int{
    if a {
        let b : short = 2;
        ret 1;
    } else {
        ret 2;
    }
}

fun main() : int {
    let k : short = 2;
    if k {
        dbg f(1);
    } else {
        dbg 2;
    }
}