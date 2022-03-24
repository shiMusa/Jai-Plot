
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