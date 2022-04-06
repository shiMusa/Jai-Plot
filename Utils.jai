
NewResizableArray :: (count: s64, $T: Type, $initialized := true, allocator: Allocator = .{}, alignment: s32 = -1) -> [..]T {
    arr := NewArray(count, T, initialized, allocator, alignment); // ! alloc
    res := resizable(arr);
    res.count = 0;
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


inv_log_of_10 :: #run cast(float32)1.0/Math.log(10.0);
log10 :: inline (x: float32) -> float32 {
    return cast(float32)(Math.log(x)*inv_log_of_10);
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