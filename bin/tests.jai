#import "Basic";


Option :: struct(T: Type) {
    is_some: bool;
    val: T;
}
some :: (val: $T) -> Option(T) {
    res : Option(T) = ---;
    res.is_some = true;
    res.val = val;
    return res;
}
none :: ($T: Type) -> Option(T) {
    res : Option(T) = ---;
    res.is_some = false;
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
foo :: (x: Option(int)) -> Result(int) {
    if x.is_some {
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
    if x.is_some {
        print("ok: val = %\n", x.val);
        y += 1;
    }
    print("y = %\n", y);
}


#import "Program_Print";  
#import "Compiler";       
#import "String";

some_macro :: ($x: string, $code_some: Code = #code{}, $code_none: Code = #code{}) -> string {
    return #run ()->string {
        builder: String_Builder;

        print_to_builder(*builder, "if %.is_some {\n", x);
        print_to_builder(*builder, "it := %.val;\n", x);

        some_root, some_expressions := compiler_get_nodes(code_some);
        print_expression(*builder, some_root);

        append(*builder, "\n} else {\n");

        none_root, none_expressions := compiler_get_nodes(code_none);
        print_expression(*builder, none_root);

        append(*builder, "\n}\n");

        res := builder_to_string(*builder);
        print(res);

        return res;
    }();
}


main :: () {
    x := some(42);
    print("foo(%) = %\n", x, foo(x));

    y := 0;
    #insert #run some_macro("x", #code {
        print("x is some(%)\n", it);
        y += 1;
    }, #code {
        print("x is none.\n");    
    });

    print("y = %\n", y);

    f := foo(x);
    if f.is_ok then print("foo(x) = %\n", x);
    f = foo(none(int));
    if !f.is_ok then print("foo(none(int)) = %\n", x);

    bar(x);
}