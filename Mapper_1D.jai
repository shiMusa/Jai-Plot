

// ##     ##    ###    ########  ########  ######## ########        ##   ########
// ###   ###   ## ##   ##     ## ##     ## ##       ##     ##     ####   ##     ##
// #### ####  ##   ##  ##     ## ##     ## ##       ##     ##       ##   ##     ##
// ## ### ## ##     ## ########  ########  ######   ########        ##   ##     ##
// ##     ## ######### ##        ##        ##       ##   ##         ##   ##     ##
// ##     ## ##     ## ##        ##        ##       ##    ##        ##   ##     ##
// ##     ## ##     ## ##        ##        ######## ##     ##     ###### ########

Mapper_1D_Types :: Type.[
    Mapper_1D_Identity,
    Mapper_1D_Linear,
    Mapper_1D_Logarithmic,
    Mapper_1D_Constraint
];


#scope_export
Mapper_1D :: struct {
    type: Type;
}
#scope_module
clone :: (b: *Mapper_1D) -> *Mapper_1D {
    #insert #run specialize(Mapper_1D_Types, "clone", .[], 1);
}
get_inner_type :: (b: *Mapper_1D) -> Type {
    #insert #run specialize(Mapper_1D_Types, "get_inner_type", .[], 1);
}
map :: (b: *Mapper_1D, x: []float32) -> []float32 {
    res := NewArray(x.count, float32, false);
    for x {
        res[it_index] = map(b, it);
    }
    return res;
}
map :: (b: *Mapper_1D, x: float32) -> float32 {
    #insert #run specialize(Mapper_1D_Types, "map", .["x"], 1);
}
map_inv :: (b: *Mapper_1D, y: []float32) -> []float32 {
    res := NewArray(x.count, float32, false);
    for x {
        res[it_index] = map_inv(b, it);
    }
    return res;
}
map_inv :: (b: *Mapper_1D, y: float32) -> float32 {
    #insert #run specialize(Mapper_1D_Types, "map_inv", .["y"], 1);
}
match :: (b: *Mapper_1D, x: float32, to_y: float32) {
    #insert #run specialize(Mapper_1D_Types, "match", .["x", "to_y"]);
}
fit_bounds :: (b: *Mapper_1D, min_x: float32, max_x: float32, min_y: float32, max_y: float32, overwrite_constraints: bool = false) {
    #insert #run specialize(Mapper_1D_Types, "fit_bounds", .["min_x", "max_x", "min_y", "max_y", "overwrite_constraints"]);
}



// #### ########  ######## ##    ## ######## #### ######## ##    ##
//  ##  ##     ## ##       ###   ##    ##     ##     ##     ##  ##
//  ##  ##     ## ##       ####  ##    ##     ##     ##      ####
//  ##  ##     ## ######   ## ## ##    ##     ##     ##       ##
//  ##  ##     ## ##       ##  ####    ##     ##     ##       ##
//  ##  ##     ## ##       ##   ###    ##     ##     ##       ##
// #### ########  ######## ##    ##    ##    ####    ##       ##


#scope_export
Mapper_1D_Identity :: struct {
    using _m : Mapper_1D;
}
#scope_module
clone :: (m: *Mapper_1D_Identity) -> *Mapper_1D_Identity {
    res := New(Mapper_1D_Identity);
    res.type = Mapper_1D_Identity;
    return res;
}
#scope_export
mapper_1d_identity :: () -> *Mapper_1D_Identity {
    res := New(Mapper_1D_Identity);
    res.type = Mapper_1D_Identity;
    return res;
}
#scope_module
map :: inline (using lm: *Mapper_1D_Identity, x: float32) -> float32 {
    return x;
}
map_inv :: inline (using lm: *Mapper_1D_Identity, y: float32) -> float32 {
    return y;
}
match :: inline (lm: *Mapper_1D_Identity, x: float32, to_y: float32) {}
fit_bounds :: inline (using lm: *Mapper_1D_Identity, min_x: float32, max_x: float32, min_y: float32, max_y: float32, overwrite_constraints: bool) {}
get_inner_type :: inline (m: *Mapper_1D_Identity) -> Type {
    return Mapper_1D_Identity;
}





// ##       #### ##    ## ########    ###    ########
// ##        ##  ###   ## ##         ## ##   ##     ##
// ##        ##  ####  ## ##        ##   ##  ##     ##
// ##        ##  ## ## ## ######   ##     ## ########
// ##        ##  ##  #### ##       ######### ##   ##
// ##        ##  ##   ### ##       ##     ## ##    ##
// ######## #### ##    ## ######## ##     ## ##     ##

#scope_export
Mapper_1D_Linear :: struct {
    using _m : Mapper_1D;
    y0, dydx : float32;
}
#scope_module
clone :: (m: *Mapper_1D_Linear) -> *Mapper_1D_Linear {
    res := New(Mapper_1D_Linear);
    res.type = Mapper_1D_Linear;
    res.y0 = m.y0;
    res.dydx = m.dydx;
    return res;
}
#scope_export
mapper_1d_linear :: (y0: float = 0.0, dydx: float32 = 1.0) -> *Mapper_1D_Linear {
    res := New(Mapper_1D_Linear);
    res.type = Mapper_1D_Linear;
    res.y0 = y0;
    res.dydx = dydx;
    return res;
}
mapper_1d_linear :: (min_x: float32, max_x: float32, min_y: float32, max_y: float32) -> *Mapper_1D_Linear {
    res := New(Mapper_1D_Linear);
    res.type = .LINEAR;
    fit_bounds(res, min_x, max_x, min_y, max_y);
    return res;
}
#scope_module
map :: inline (using lm: *Mapper_1D_Linear, x: float32) -> float32 {
    return y0 + dydx * x;
}
map_inv :: inline (using lm: *Mapper_1D_Linear, y: float32) -> float32 {
    return (y - y0)/dydx;
}
match :: inline (lm: *Mapper_1D_Linear, x: float32, to_y: float32) {
    lm.y0 += to_y-map(lm,x);
}
fit_bounds :: (using lm: *Mapper_1D_Linear, min_x: float32, max_x: float32, min_y: float32, max_y: float32, overwrite_constraints: bool) {
    dydx = (max_y-min_y)/(max_x-min_x);
    // dydx * max_x + y0 = max_y => y0 = max_y - dydx * max_x
    y0 = max_y - dydx * max_x;
}
get_inner_type :: inline (m: *Mapper_1D_Linear) -> Type {
    return Mapper_1D_Linear;
}



// ##        #######   ######
// ##       ##     ## ##    ##
// ##       ##     ## ##
// ##       ##     ## ##   ####
// ##       ##     ## ##    ##
// ##       ##     ## ##    ##
// ########  #######   ######

#scope_export
Mapper_1D_Logarithmic :: struct {
    using mapper: Mapper_1D;
    mapper_1d_linear: *Mapper_1D_Linear;
    base: float32;
    invlogbase: float32;
}
#scope_module
clone :: (m: *Mapper_1D_Logarithmic) -> *Mapper_1D_Logarithmic {
    res := New(Mapper_1D_Logarithmic);
    res.type = Mapper_1D_Logarithmic;
    res.mapper_1d_linear = clone(m.mapper_1d_linear);
    res.base = m.base;
    res.invlogbase = m.invlogbase;
    return res;
}
#scope_export
mapper_1d_logarithmic :: (base: float32 = 10.0) -> *Mapper_1D_Logarithmic {
    res := New(Mapper_1D_Logarithmic);
    res.type = Mapper_1D_Logarithmic;
    res.mapper_1d_linear = mapper_1d_linear();
    res.base = base;
    res.invlogbase = 1.0/Math.log(base);
    return res;
}
#scope_module
map :: inline (using ml: *Mapper_1D_Logarithmic, x: float32) -> float32 {
    // if x <= 0.0 then return Math.FLOAT32_MIN;
    return map(mapper_1d_linear, Math.log(x) * invlogbase);
}
map_inv :: inline (using ml: *Mapper_1D_Logarithmic, y: float32) -> float32 {
    return Math.pow(base, map_inv(mapper_1d_linear, y));
}
match :: inline (using ml: *Mapper_1D_Logarithmic, x: float32, to_y: float32) {
    match(mapper_1d_linear, Math.log(x)*invlogbase, to_y);
}
fit_bounds :: (using ml: *Mapper_1D_Logarithmic, min_x: float32, max_x: float32, min_y: float32, max_y: float32, overwrite_constraints: bool) {
    if min_x <= 0.0 then return;
    if Math.isinf(max_x) then return;
    fit_bounds(
        mapper_1d_linear, 
        Math.log(min_x)*invlogbase,
        Math.log(max_x)*invlogbase,
        min_y, max_y
    );
}
get_inner_type :: inline (m: *Mapper_1D_Logarithmic) -> Type {
    return Mapper_1D_Logarithmic;
}



//  ######   #######  ##    ##  ######  ######## ########     ###    #### ##    ## ########
// ##    ## ##     ## ###   ## ##    ##    ##    ##     ##   ## ##    ##  ###   ##    ##
// ##       ##     ## ####  ## ##          ##    ##     ##  ##   ##   ##  ####  ##    ##
// ##       ##     ## ## ## ##  ######     ##    ########  ##     ##  ##  ## ## ##    ##
// ##       ##     ## ##  ####       ##    ##    ##   ##   #########  ##  ##  ####    ##
// ##    ## ##     ## ##   ### ##    ##    ##    ##    ##  ##     ##  ##  ##   ###    ##
//  ######   #######  ##    ##  ######     ##    ##     ## ##     ## #### ##    ##    ##

#scope_export
Mapper_1D_Constraint :: struct {
    using _m: Mapper_1D;
    inner: *Mapper_1D;

    fixed_min_x, fixed_max_x, fixed_min_y, fixed_max_y: bool = false;
    min_x, max_x, min_y, max_y : float32;
}
#scope_module
clone :: (m: *Mapper_1D_Constraint) -> *Mapper_1D_Constraint {
    res := New(Mapper_1D_Constraint);
    res.type = Mapper_1D_Constraint; 
    res.inner = clone(m.inner);
    res.fixed_min_x = m.fixed_min_x;
    res.fixed_max_x = m.fixed_max_x;
    res.fixed_min_y = m.fixed_min_y;
    res.fixed_max_y = m.fixed_max_y;
    res.min_x = m.min_x;
    res.max_x = m.max_x;
    res.min_y = m.min_y;
    res.max_y = m.max_y;
    return res;
}
#scope_export
mapper_1d_constraint :: (
    inner: *Mapper_1D, 
    min_x: float32 = Math.FLOAT32_NAN,
    max_x: float32 = Math.FLOAT32_NAN,
    min_y: float32 = Math.FLOAT32_NAN,
    max_y: float32 = Math.FLOAT32_NAN
) -> *Mapper_1D_Constraint {
    res := New(Mapper_1D_Constraint);
    res.type = Mapper_1D_Constraint;
    res.inner = inner;

    if !Math.isnan(min_x) { res.min_x = min_x; res.fixed_min_x = true; }
    if !Math.isnan(max_x) { res.max_x = max_x; res.fixed_max_x = true; }
    if !Math.isnan(min_y) { res.min_y = min_y; res.fixed_min_y = true; }
    if !Math.isnan(max_y) { res.max_y = max_y; res.fixed_max_y = true; }

    return res;
}
#scope_module
map :: inline (using cm: *Mapper_1D_Constraint, x: float32) -> float32 {
    return map(inner, x);
}
map_inv :: inline (using cm: *Mapper_1D_Constraint, y: float32) -> float32 {
    return map_inv(inner, y);
}
match :: inline (cm: *Mapper_1D_Constraint, x: float32, to_y: float32) {
    cm.fixed_min_x = true;
    cm.fixed_max_x = true;
    cm.fixed_min_y = true;
    cm.fixed_max_y = true;
    match(cm.inner, x, to_y);
    cm.min_x = map_inv(cm.inner, cm.min_y);
    cm.max_x = map_inv(cm.inner, cm.max_y);
}
fit_bounds :: (cm: *Mapper_1D_Constraint, min_x: float32, max_x: float32, min_y: float32, max_y: float32, overwrite_constraints: bool = false) {
    if overwrite_constraints {
        cm.min_x = min_x;
        cm.max_x = max_x;
        cm.min_y = min_y;
        cm.max_y = max_y;
        cm.fixed_min_x = true;
        cm.fixed_max_x = true;
        cm.fixed_min_y = true;
        cm.fixed_max_y = true;
    }
    mi_x := ifx cm.fixed_min_x then cm.min_x else min_x;
    ma_x := ifx cm.fixed_max_x then cm.max_x else max_x;
    mi_y := ifx cm.fixed_min_y then cm.min_y else min_y;
    ma_y := ifx cm.fixed_max_y then cm.max_y else max_y;

    fit_bounds(cm.inner, mi_x, ma_x, mi_y, ma_y, overwrite_constraints);
}
get_inner_type :: inline (m: *Mapper_1D_Constraint) -> Type {
    return get_inner_type(m.inner);
}



