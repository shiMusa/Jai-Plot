
// ##     ##    ###    ########  ########  ######## ########      #######  ########
// ###   ###   ## ##   ##     ## ##     ## ##       ##     ##    ##     ## ##     ##
// #### ####  ##   ##  ##     ## ##     ## ##       ##     ##           ## ##     ##
// ## ### ## ##     ## ########  ########  ######   ########      #######  ##     ##
// ##     ## ######### ##        ##        ##       ##   ##      ##        ##     ##
// ##     ## ##     ## ##        ##        ##       ##    ##     ##        ##     ##
// ##     ## ##     ## ##        ##        ######## ##     ##    ######### ########

Mapper_2D_Types :: Type.[
    Mapper_2D_Cartesian,
];


#scope_export
Mapper_2D :: struct {
    type: Type;
}
#scope_module
clone :: (b: *Mapper_2D) -> *Mapper_2D {
    #insert #run specialize(Mapper_2D_Types, "clone", .[], 1);
}
map :: (b: *Mapper_2D, x: []Vector2) -> []Vector2 {
    res := NewArray(x.count, Vector2, false);
    for x {
        res[it_index] = map(b, it);
    }
    return res;
}
map :: (b: *Mapper_2D, x: Vector2) -> Vector2 {
    #insert #run specialize(Mapper_2D_Types, "map", .["x"], 1);
}
map_inv :: (b: *Mapper_2D, y: []Vector2) -> []Vector2 {
    res := NewArray(x.count, Vector2, false);
    for x {
        res[it_index] = map_inv(b, it);
    }
    return res;
}
map_inv :: (b: *Mapper_2D, y: Vector2) -> Vector2 {
    #insert #run specialize(Mapper_2D_Types, "map_inv", .["y"], 1);
}
match :: (b: *Mapper_2D, x: Vector2, to_y: Vector2) {
    #insert #run specialize(Mapper_2D_Types, "match", .["x", "to_y"]);
}


//  ######     ###    ########  ######## ########  ######  ####    ###    ##    ##
// ##    ##   ## ##   ##     ##    ##    ##       ##    ##  ##    ## ##   ###   ##
// ##        ##   ##  ##     ##    ##    ##       ##        ##   ##   ##  ####  ##
// ##       ##     ## ########     ##    ######    ######   ##  ##     ## ## ## ##
// ##       ######### ##   ##      ##    ##             ##  ##  ######### ##  ####
// ##    ## ##     ## ##    ##     ##    ##       ##    ##  ##  ##     ## ##   ###
//  ######  ##     ## ##     ##    ##    ########  ######  #### ##     ## ##    ##

Mapper_2D_Cartesian :: struct {
    using _m: Mapper_2D;
    x_mapper: *Mapper_1D;
    y_mapper: *Mapper_1D;
}

mapper_2d_cartesian :: (x_mapper: *Mapper_1D, y_mapper: *Mapper_1D) -> *Mapper_2D_Cartesian {
    res := New(Mapper_2D_Cartesian);
    res.type = Mapper_2D_Cartesian;
    res.x_mapper = x_mapper;
    res.y_mapper = y_mapper;
    return res;
}

clone :: (using cm: *Mapper_2D_Cartesian) -> *Mapper_2D_Cartesian {
    res := New(Mapper_2D_Cartesian);
    res.type = Mapper_2D_Cartesian;
    res.x_mapper = x_mapper;
    res.y_mapper = y_mapper;
    return res;
}
map :: inline (using b: *Mapper_2D_Cartesian, x: Vector2) -> Vector2 {
    return vec2(map(x_mapper, x.x), map(y_mapper, x.y));
}
map_inv :: inline (b: *Mapper_2D_Cartesian, y: Vector2) -> Vector2 {
    return vec2(map_inv(x_mapper, x.x), map_inv(y_mapper, x.y));
}
match :: inline (b: *Mapper_2D_Cartesian, x: Vector2, to_y: Vector2) {
    match(x_mapper, x.x, y.x);
    match(x_mapper, x.y, y.y);
}