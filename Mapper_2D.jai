
// ##     ##    ###    ########  ########  ######## ########      #######  ########
// ###   ###   ## ##   ##     ## ##     ## ##       ##     ##    ##     ## ##     ##
// #### ####  ##   ##  ##     ## ##     ## ##       ##     ##           ## ##     ##
// ## ### ## ##     ## ########  ########  ######   ########      #######  ##     ##
// ##     ## ######### ##        ##        ##       ##   ##      ##        ##     ##
// ##     ## ##     ## ##        ##        ##       ##    ##     ##        ##     ##
// ##     ## ##     ## ##        ##        ######## ##     ##    ######### ########

Mapper_2D_Types :: Type.[
    Mapper_2D_Polar,
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


//  ######     ###    ########  ######## ########  ######  ####    ###    ##    ##
// ##    ##   ## ##   ##     ##    ##    ##       ##    ##  ##    ## ##   ###   ##
// ##        ##   ##  ##     ##    ##    ##       ##        ##   ##   ##  ####  ##
// ##       ##     ## ########     ##    ######    ######   ##  ##     ## ## ## ##
// ##       ######### ##   ##      ##    ##             ##  ##  ######### ##  ####
// ##    ## ##     ## ##    ##     ##    ##       ##    ##  ##  ##     ## ##   ###
//  ######  ##     ## ##     ##    ##    ########  ######  #### ##     ## ##    ##

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