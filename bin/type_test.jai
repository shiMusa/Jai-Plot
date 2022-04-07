#import "Basic";
#import "String";

Types :: Type.[Foo];

Base :: struct {
    type: Type;
}
#insert #run specialize(Base, Types, "do_sth");

Foo :: struct {
    using _b: Base;
}
foo :: () -> *Foo {
    res := New(Foo);
    res.type = Foo;
    return res;
}
do_sth :: (f: *Foo) {
    print("Foo!!!\n");
}

main :: () {
    f := foo();
    b := cast(*Base)f;
    do_sth(b); // "Error: Type mismatch. Type wanted: *Foo; type given: *Base."
}




specialize :: (base: Type, enum_array: []Type, fct_name: string, other_fct_args: string = "", rets: []string = .[]) -> string {
    builder : String_Builder;

    print_to_builder(*builder, "% :: (b: *%", fct_name, base);
    if other_fct_args != "" {
        print_to_builder(*builder, ", %", other_fct_args);
    }
    append(*builder, ")");
    if rets.count != 0 {
        append(*builder, " -> ");
        for rets {
            print_to_builder(*builder, "%", it);
            if it_index != rets.count-1 then 
                append(*builder, ", ");
        }
    }
    append(          *builder, " {\n");
    append(          *builder, "    if b.type == {\n");

    for enum_array {
        print_to_builder(*builder, "        case %;\n", it);
        print_to_builder(*builder, "            s := cast(*%)b;\n", it);
        if rets.count != 0 {
            append(*builder, "            ");
            for rets {
                print_to_builder(*builder, "v%", it_index);
                if it_index != rets.count-1 then
                    append(*builder, ", ");
            }
            print_to_builder(*builder, " := %(s", fct_name);
            if other_fct_args != "" then 
                print_to_builder(*builder, ", %", other_fct_args);
            append(*builder, ");\n");

            append(*builder, "            return ");
            for rets {
                print_to_builder(*builder, "v%", it_index);
                if it_index != rets.count-1 then
                    append(*builder, ", ");
            }
            append(*builder, ";\n");
        } else {
            append(*builder, "            ");
            print_to_builder(*builder, "%(s", fct_name);
            if other_fct_args != "" then 
                print_to_builder(*builder, ", %", other_fct_args);
            append(*builder, ");\n");
        }
    }

    append(*builder, "    }\n");
    append(*builder, "}\n");

    res := builder_to_string(*builder);
    print(res);
    return res;
}