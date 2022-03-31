#import "Basic";


Option :: struct(T: Type, is_some: bool) {
    val: T;
}
some :: (val: $T) -> Option(T, true) {
    res : Option(T, true) = ---;
    res.val = val;
    return res;
}
none :: ($T: Type) -> Option(T, false) {
    res : Option(T, false) = ---;
    return res;
}


Error :: struct {
    msg: string;
    data: *void;
}
Result :: struct(T: Type) {
    is_ok: bool;
    using _val: union {
        val: T;
        error: Error;
    }
}
ok :: (val: $T) -> Result(T) {
    res: Result(T) = ---;
    res.is_ok = true;
    res.val = val;
    return res;
}
err :: ($T: Type, msg: string = "", data: *void = null) -> Result(T) {
    res : Result(T) = ---;
    res.is_ok = false;
    e : Error = ---;
    e.msg = msg;
    e.data = data;
    res.error = e;
    return res;
}


// only allow `int` values
foo :: (x: Option(int, $is_some)) -> Result(int) {
    #if is_some {
        print("ok: val = %\n", x.val);
        return ok(x.val);
    } else {
        print("no\n");
        return err(int, "there is nothing...");
    }
}

// any `Option` allowed
bar :: (x: Option) {
    y := 0;
    #if x.is_some {
        print("ok: val = %\n", x.val);
        y += 1;
    }
    print("y = %\n", y);
}


main :: () {
    x := some(42);
    print("foo(%) = %\n", x, foo(x));

    f := foo(x);
    if f.is_ok then print("foo(x) = %\n", f.val);
    f = foo(none(int));
    if !f.is_ok then print("foo(none(int)) = %\n", f.error); 


    bar(x);
}