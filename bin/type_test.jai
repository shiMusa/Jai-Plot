#import "Basic";
#import "String";

Types :: Type.[Foo, Zap];

Base :: struct {
    type: Type;
}
do_sth :: (b: *Base) {
    #insert #run specialize(Base, Types, "do_sth");
}
bar :: (b: *Base, msgs: []string) -> bool {
    #insert #run specialize(Base, Types, "bar", .["msgs"], 1);
}


Foo :: struct {
    using _b : Base;
}
foo :: () -> *Foo {
    res := New(Foo);
    res.type = Foo;
    return res;
}
do_sth :: (f: *Foo) {
    print("Foo!!!\n");
}
bar :: (f: *Foo, msgs: []string) -> bool {
    for msgs {
        print("Foo: %\n", it);
    }
    return true;
}


Zap :: struct {
    using _b : Base;
}
zap :: () -> *Zap {
    res := New(Zap);
    res.type = Zap;
    return res;
}
do_sth :: (f: *Zap) {
    print("Zap!!!\n");
}
bar :: (f: *Zap, msgs: []string) -> bool {
    for msgs {
        print("Zap: %\n", it);
    }
    return true;
}


main :: () {
    f := foo();
    b := cast(*Base)f;
    do_sth(b); 
    bar(b, .["hello", "world"]);

    z := zap();
    b = cast(*Base)z;
    do_sth(b); 
    bar(b, .["hello", "world"]);
}


specialize :: (base: Type, enum_array: []Type, fct_name: string, other_fct_args: []string = .[], num_rets: int = 0) -> string {
    builder : String_Builder;
    append(          *builder, "if b.type == {\n");

    for enum_array {
        print_to_builder(*builder, "    case %;\n", it);
        print_to_builder(*builder, "        s := cast(*%)b;\n", it);
        if num_rets != 0 {
            append(*builder, "        ");
            for i: 0..num_rets-1 {
                print_to_builder(*builder, "v%", i);
                if i != num_rets-1 then
                    append(*builder, ", ");
            }
            print_to_builder(*builder, " := %(s", fct_name);
            if other_fct_args.count != 0 {
                append(*builder, ", ");
                for a, ia: other_fct_args {
                    print_to_builder(*builder, "%", a);
                    if ia != other_fct_args.count-1 then 
                        append(*builder, ", ");
                }
            } 
            append(*builder, ");\n");

            append(*builder, "        return ");
            for i: 0..num_rets-1 {
                print_to_builder(*builder, "v%", i);
                if i != num_rets-1 then
                    append(*builder, ", ");
            }
            append(*builder, ";\n");
        } else {
            append(*builder, "        ");
            print_to_builder(*builder, "%(s", fct_name);
            if other_fct_args.count != 0 {
                append(*builder, ", ");
                for a, ia: other_fct_args {
                    print_to_builder(*builder, "%", a);
                    if ia != other_fct_args.count-1 then 
                        append(*builder, ", ");
                }
            } 
            append(*builder, ");\n");
        }
    }

    append(*builder, "}\n");

    res := builder_to_string(*builder);
    print(res);
    return res;
}