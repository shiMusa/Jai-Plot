
NewResizableArray :: (count: s64, $T: Type, $initialized := true, allocator: Allocator = .{}, alignment: s32 = -1) -> [..]T {
    arr := NewArray(count, T, initialized, allocator, alignment); // ! alloc
    res := resizable(arr);
    res.count = 0;
    return res;
}

TempNewArray :: (count: s64, $T: Type, $initialized := true, allocator : Allocator = .{}, alignment: s32 = -1) -> []T #expand {
    res := NewArray(count, T, initialized, allocator, alignment);
    `defer array_free(res);
    return res;
}
TempNewResizableArray :: (count: s64, $T: Type, $initialized := true, allocator : Allocator = .{}, alignment: s32 = -1) -> [..]T #expand {
    res := NewResizableArray(count, T, initialized, allocator, alignment);
    `defer array_free(res);
    return res;
}




min :: (arr: []$T) -> T {
    assert(arr.count > 0);
    min := arr[0];
    for i: 1..arr.count-1 {
        min = ifx arr[i] < min then arr[i] else min;
    }
    return min;
}

max :: (arr: []$T) -> T {
    assert(arr.count > 0);
    max := arr[0];
    for i: 1..arr.count-1 {
        max = ifx arr[i] > max then arr[i] else max;
    }
    return max;
}

// see https://www.wikiwand.com/en/Polar_coordinate_system
atan2 :: (y: float32, x: float32) -> float32 {
    T :: float32;

    if x > 0 then return cast(T)Math.atan(y/x);
    if x < 0 {
        if y >= 0  { return cast(T)Math.atan(y/x)+PI32; }
        else       { return cast(T)Math.atan(y/x)-PI32; }
    }
    if y > 0 then return  0.5*PI32;
    if y < 0 then return -0.5*PI32;
    return Math.FLOAT32_NAN;
}

inv_log_of_10 :: #run cast(float32)(1.0/Math.log(10.0));
log10 :: inline (x: float32) -> float32 {
    return cast(float32)(Math.log(x)*inv_log_of_10);
}
inv_log_of_2 :: #run cast(float32)(1.0/Math.log(2.0));
log2 :: inline (x: float32) -> float32 {
    return cast(float32)(Math.log(x)*inv_log_of_2);
}

log10_of_5 :: #run log10(5.0);
round_to_base :: (x: float32, $$base: float32 = 10.0, exponent_shift: float32 = -log10_of_5 ) -> float32, float32 {
    #if is_constant(base) {
        inv_log_base :: #run 1.0/Math.log(base);
        exponent := Math.floor( Math.log(x) * inv_log_base + exponent_shift );
    } else {
        exponent := Math.floor( Math.log(x)/Math.log(base) + exponent_shift );
    }
    rx := Math.pow(base, exponent);
    return rx, exponent;
}

round :: (x: $T) -> T {
    return cast(T)(cast(s32)x);
}


// ######## ####  ######  ##    ##  ######
//    ##     ##  ##    ## ##   ##  ##    ##
//    ##     ##  ##       ##  ##   ##
//    ##     ##  ##       #####     ######
//    ##     ##  ##       ##  ##         ##
//    ##     ##  ##    ## ##   ##  ##    ##
//    ##    ####  ######  ##    ##  ######


ticks_linear :: (min_x: float32, max_x: float32, base: float32 = 10.0, exponent_shift: float32 = -log10_of_5) -> [..]float32 {
    range := max_x - min_x;
    dx, exp := round_to_base(range, 10.0, exponent_shift);

    if dx > 0.5 * range then dx /= base;

    res := NewResizableArray(cast(s32)(range/dx), float32);
    x := cast(float32)Math.ceil(min_x/dx) * dx;
    while x < max_x {
        array_add(*res, x);
        x += dx;
    }
    return res;
}

ticks_logarithmic :: (min_x: float32, max_x: float32, $$base: float32=10.0) -> [..]float32 {
    // print("ticks_logarithmic: %, %, %\n", min_x, max_x, base);
    #if is_constant(base) {
        invlogbase :: #run 1.0/Math.log(base);
    } else {
        invlogbase := 1.0/Math.log(base);
    }

    log_min_x := Math.log(min_x)*invlogbase;
    log_max_x := Math.log(max_x)*invlogbase;

    ticks := ticks_linear(log_min_x, log_max_x, base);
    for *ticks {
        <<it = Math.pow(base, <<it);
    }
    return ticks;
}



// ##     ##    ###     ######  ########   #######   ######
// ###   ###   ## ##   ##    ## ##     ## ##     ## ##    ##
// #### ####  ##   ##  ##       ##     ## ##     ## ##
// ## ### ## ##     ## ##       ########  ##     ##  ######
// ##     ## ######### ##       ##   ##   ##     ##       ##
// ##     ## ##     ## ##    ## ##    ##  ##     ## ##    ##
// ##     ## ##     ##  ######  ##     ##  #######   ######

specialize :: (
    enum_array: []Type, 
    fct_name: string, 
    other_fct_args: []string = .[], 
    num_return_vars: int = 0,
    base: string = "b", 
    base_pos: int = 0,
    type_var: string = "type"
) -> string {
    builder : String_Builder;
    print_to_builder(*builder, "if %.% == {\n", base, type_var);

    for enum_array {
        print_to_builder(*builder, "    case %;\n", it);
        print_to_builder(*builder, "        s := cast(*%)%;\n", it, base);
        if num_return_vars != 0 {
            append(*builder, "        ");
            for i: 0..num_return_vars-1 {
                print_to_builder(*builder, "v%", i);
                if i != num_return_vars-1 then
                    append(*builder, ", ");
            }




            print_to_builder(*builder, " := %(", fct_name);

            if other_fct_args.count == 0 {
                append(*builder, "s");
            } else {                
                i := 0;
                while i < other_fct_args.count {
                    if i == base_pos then 
                        append(*builder, "s, ");
                    
                    print_to_builder(*builder, "%", other_fct_args[i]);
                    
                    if i != other_fct_args.count-1 then 
                        append(*builder, ", ");

                    i += 1;
                }
                if base_pos == other_fct_args.count then 
                    append(*builder, ", s");
            } 
            append(*builder, ");\n");




            append(*builder, "        return ");
            for i: 0..num_return_vars-1 {
                print_to_builder(*builder, "v%", i);
                if i != num_return_vars-1 then
                    append(*builder, ", ");
            }
            append(*builder, ";\n");
        } else {
            append(*builder, "        ");
            
            print_to_builder(*builder, "%(", fct_name);

            if other_fct_args.count == 0 {
                append(*builder, "s");
            } else {                
                i := 0;
                while i < other_fct_args.count {
                    if i == base_pos then 
                        append(*builder, "s, ");
                    
                    print_to_builder(*builder, "%", other_fct_args[i]);
                    
                    if i != other_fct_args.count-1 then 
                        append(*builder, ", ");

                    i += 1;
                }
                if base_pos == other_fct_args.count then 
                    append(*builder, ", s");
            } 
            append(*builder, ");\n");
        }
    }

    append(*builder, "}\n");

    res := builder_to_string(*builder);
    print(res);
    return res;
}