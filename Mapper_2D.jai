
// ##     ##    ###    ########  ########  ######## ########      #######  ########
// ###   ###   ## ##   ##     ## ##     ## ##       ##     ##    ##     ## ##     ##
// #### ####  ##   ##  ##     ## ##     ## ##       ##     ##           ## ##     ##
// ## ### ## ##     ## ########  ########  ######   ########      #######  ##     ##
// ##     ## ######### ##        ##        ##       ##   ##      ##        ##     ##
// ##     ## ##     ## ##        ##        ##       ##    ##     ##        ##     ##
// ##     ## ##     ## ##        ##        ######## ##     ##    ######### ########

Mapper_2D_Types :: Type.[
    Mapper_2D_Polar,
    Mapper_2D_Cartesian
];


#scope_export
Mapper_2D :: struct {
    type: Type;
}
#scope_module
clone :: (b: *Mapper_2D) -> *Mapper_2D {
    #insert #run specialize(Mapper_2D_Types, "clone", .[], 1);
}
map :: (b: *Mapper_2D, x: Vector2) -> Vector2 {
    #insert #run specialize(Mapper_2D_Types, "map", .["x"], 1);
}
map_inv :: (b: *Mapper_2D, y: Vector2) -> Vector2 {
    #insert #run specialize(Mapper_2D_Types, "map_inv", .["y"], 1);
}




map :: (b: *Mapper_2D, x: []Vector2) -> []Vector2 {
    res := NewArray(x.count, Vector2, false);
    for x {
        res[it_index] = map(b, it);
    }
    return res;
}
map :: (b: *Mapper_2D, x: *[]Vector2) {
    for *(<<x) {
        <<it = map(b, <<it);
    }
}
map :: (b: *Mapper_2D, x: []float32, y: []float32) -> []Vector2 {
    assert(x.count == y.count);
    res := NewArray(x.count, Vector2, false);
    for i:0..x.count-1 {
        res[i] = map(b, vec2(x[i], y[i]));
    }
    return res;
}
map_inv :: (b: *Mapper_2D, y: []Vector2) -> []Vector2 {
    res := NewArray(x.count, Vector2, false);
    for x {
        res[it_index] = map_inv(b, it);
    }
    return res;
}
map_inv :: (b: *Mapper_2D, x: *[]Vector2) {
    for *x {
        <<it = map_inv(b, <<it);
    }
}
map_inv :: (b: *Mapper_2D, x: []float32, y: []float32) -> []Vector2 {
    assert(x.count == y.count);
    res := NewArray(x.count, Vector2, false);
    for i:0..x.count-1 {
        res[i] = map_inv(b, vec2(x[i], y[i]));
    }
    return res;
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

mapper_2d_cartesian :: (x_mapper: *Mapper_1D = null, y_mapper: *Mapper_1D = null) ->  *Mapper_2D_Cartesian {
    res := New(Mapper_2D_Cartesian);
    res.type = Mapper_2D_Cartesian;
    res.x_mapper = ifx x_mapper then x_mapper else mapper_1d_linear();
    res.y_mapper = ifx y_mapper then y_mapper else mapper_1d_linear();
    return res;
}

clone :: inline (using cm: *Mapper_2D_Cartesian) -> *Mapper_2D_Cartesian {
    return mapper_2d_cartesian(clone(x_mapper), clone(y_mapper));
}
map :: inline (using b: *Mapper_2D_Cartesian, p: Vector2) -> Vector2 {
    return vec2(map(x_mapper, p.x), map(y_mapper, p.y));
}
map_inv :: inline (b: *Mapper_2D_Cartesian, p: Vector2) -> Vector2 {
    return vec2(map_inv(x_mapper, p.x), map_inv(y_mapper, p.y));
}

match :: (using cm: *Mapper_2D_Cartesian, from: Vector2, to: Vector2) {
    match(x_mapper, from.x, to.x);
    match(y_mapper, from.y, to.y);
}
fit_bounds :: (using cm: *Mapper_2D_Cartesian, min_from: Vector2, max_from: Vector2, min_to: Vector2, max_to: Vector2, overwrite_constraints: bool = false) {
    fit_bounds(x_mapper, min_from.x, max_from.x, min_to.x, max_to.x);
    fit_bounds(y_mapper, min_from.y, max_from.y, min_to.y, max_to.y);
}


// ########   #######  ##          ###    ########
// ##     ## ##     ## ##         ## ##   ##     ##
// ##     ## ##     ## ##        ##   ##  ##     ##
// ########  ##     ## ##       ##     ## ########
// ##        ##     ## ##       ######### ##   ##
// ##        ##     ## ##       ##     ## ##    ##
// ##         #######  ######## ##     ## ##     ##

Mapper_2D_Polar :: struct {
    using _m: Mapper_2D;
}

mapper_2d_polar :: () -> *Mapper_2D_Polar {
    res := New(Mapper_2D_Polar);
    res.type = Mapper_2D_Polar;
    return res;
}

clone :: (using cm: *Mapper_2D_Polar) -> *Mapper_2D_Polar {
    res := New(Mapper_2D_Polar);
    res.type = Mapper_2D_Polar;
    return res;
}
// angle, radius
map :: (using b: *Mapper_2D_Polar, p: Vector2) -> Vector2 {
    return p.y * vec2(Math.cos(p.x), Math.sin(p.x));
}
map_inv :: (b: *Mapper_2D_Polar, p: Vector2) -> Vector2 {
    return vec2(Math.atan2(p.y,p.x), Math.sqrt(p.x*p.x+p.y*p.y));
}