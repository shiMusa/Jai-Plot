

// ##     ##    ###    ########  ########  ########  ######## ########
// ###   ###   ## ##   ##     ## ##     ## ##     ## ##       ##     ##
// #### ####  ##   ##  ##     ## ##     ## ##     ## ##       ##     ##
// ## ### ## ##     ## ########  ########  ########  ######   ########
// ##     ## ######### ##        ##        ##        ##       ##   ##
// ##     ## ##     ## ##        ##        ##        ##       ##    ##
// ##     ## ##     ## ##        ##        ##        ######## ##     ##


Mapper_Type :: enum u8 {
    LINEAR;
    CONSTRAINT;
    LOGARITHMIC;
}
#scope_export
Mapper :: struct {
    type: Mapper_Type = .LINEAR;
}
#scope_module
clone :: (m: *Mapper) -> *Mapper {
    if m.type == {
        case .LINEAR;
            lm := cast(*Mapper_Linear)m;
            return cast(*Mapper)clone(lm);
        case .CONSTRAINT;
            cm := cast(*Mapper_Constraint)m;
            return cast(*Mapper)clone(cm);
        case .LOGARITHMIC;
            ml := cast(*Mapper_Logarithmic)m;
            return cast(*Mapper)clone(ml);
    }
}
get_inner_type :: (m: *Mapper) -> Mapper_Type {
    if m.type == {
        case .LINEAR; #through;
        case .LOGARITHMIC;
            return m.type;
        case .CONSTRAINT;
            cm := cast(*Mapper_Constraint)m;
            return get_inner_type(cm.inner);
    }
}
map :: (m: *Mapper, x: []float32) -> []float32 {
    res := NewArray(x.count, float32, false);
    if m.type == {
        case .LINEAR;
            lm := cast(*Mapper_Linear)m;
            for *res {
                <<it = map(lm, x[it_index]);
            }
        case .CONSTRAINT;
            cm := cast(*Mapper_Constraint)m;
            for *res {
                <<it = map(cm, x[it_index]);
            }
        case .LOGARITHMIC;
            ml := cast(*Mapper_Logarithmic)m;
            for *res {
                <<it = map(ml, x[it_index]);
            }
    }
    return res;
}
map :: (m: *Mapper, x: float32) -> float32 {
    if m.type == {
        case .LINEAR;
            lm := cast(*Mapper_Linear)m;
            return map(lm, x);
        case .CONSTRAINT;
            cm := cast(*Mapper_Constraint)m;
            return map(cm, x);
        case .LOGARITHMIC;
            ml := cast(*Mapper_Logarithmic)m;
            return map(ml, x);
    }
}
map_inv :: (m: *Mapper, y: []float32) -> []float32 {
    res := NewArray(x.count, float32, false);
    if m.type == {
        case .LINEAR;
            lm := cast(*Mapper_Linear)m;
            for *res {
                <<it = map_inv(lm, x[it_index]);
            }
        case .CONSTRAINT;
            cm := cast(*Mapper_Constraint)m;
            for *res {
                <<it = map_inv(cm, x[it_index]);
            }
        case .LOGARITHMIC;
            ml := cast(*Mapper_Logarithmic)m;
            for *res {
                <<it = map_inv(ml, x[it_index]);
            }
    }
    return res;
}
map_inv :: (m: *Mapper, y: float32) -> float32 {
    if m.type == {
        case .LINEAR;
            lm := cast(*Mapper_Linear)m;
            return map_inv(lm, y);
        case .CONSTRAINT;
            cm := cast(*Mapper_Constraint)m;
            return map_inv(cm, y);
        case .LOGARITHMIC;  
            ml := cast(*Mapper_Logarithmic)m;
            return map_inv(ml, y);
    }
}
fit :: (m: *Mapper, x: float32, y: float32) {
    if m.type == {
        case .LINEAR;
            lm := cast(*Mapper_Linear)m;
            fit(lm, x, y);
        case .CONSTRAINT;
            cm := cast(*Mapper_Constraint)m;
            fit(cm, x, y);
        case .LOGARITHMIC;
            ml := cast(*Mapper_Logarithmic)m;
            fit(ml, x, y);
    }
}
fit_bounds :: (m: *Mapper, min_x: float32, max_x: float32, min_y: float32, max_y: float32, overwrite_constraints: bool = false) {
    if m.type ==  {
        case .LINEAR;
            lm := cast(*Mapper_Linear)m;
            fit_bounds(lm, min_x, max_x, min_y, max_y);
        case .CONSTRAINT;
            cm := cast(*Mapper_Constraint)m;
            fit_bounds(cm, min_x, max_x, min_y, max_y, overwrite_constraints);
        case .LOGARITHMIC;
            ml := cast(*Mapper_Logarithmic)m;
            fit_bounds(ml, min_x, max_x, min_y, max_y);
    }
}






// ##       #### ##    ## ########    ###    ########
// ##        ##  ###   ## ##         ## ##   ##     ##
// ##        ##  ####  ## ##        ##   ##  ##     ##
// ##        ##  ## ## ## ######   ##     ## ########
// ##        ##  ##  #### ##       ######### ##   ##
// ##        ##  ##   ### ##       ##     ## ##    ##
// ######## #### ##    ## ######## ##     ## ##     ##

#scope_export
Mapper_Linear :: struct {
    using _m : Mapper;
    y0, dydx : float32;
}
#scope_module
clone :: (m: *Mapper_Linear) -> *Mapper_Linear {
    res := New(Mapper_Linear);
    res.type = .LINEAR;
    res.y0 = m.y0;
    res.dydx = m.dydx;
    return res;
}
#scope_export
mapper_linear :: (y0: float = 0.0, dydx: float32 = 1.0) -> *Mapper_Linear {
    res := New(Mapper_Linear);
    res.type = .LINEAR;
    res.y0 = y0;
    res.dydx = dydx;
    return res;
}
mapper_linear :: (min_x: float32, max_x: float32, min_y: float32, max_y: float32) -> *Mapper_Linear {
    res := New(Mapper_Linear);
    res.type = .LINEAR;
    fit_bounds(res, min_x, max_x, min_y, max_y);
    return res;
}
#scope_module
map :: inline (using lm: *Mapper_Linear, x: float32) -> float32 {
    return y0 + dydx * x;
}
map_inv :: inline (using lm: *Mapper_Linear, y: float32) -> float32 {
    return (y - y0)/dydx;
}
fit :: inline (lm: *Mapper_Linear, x: float32, y: float32) {
    yt := map(lm, x);
    lm.y0 += y-yt;
}
fit_bounds :: (using lm: *Mapper_Linear, min_x: float32, max_x: float32, min_y: float32, max_y: float32) {
    dydx = (max_y-min_y)/(max_x-min_x);
    // dydx * max_x + y0 = max_y => y0 = max_y - dydx * max_x
    y0 = max_y - dydx * max_x;
}



// ##        #######   ######
// ##       ##     ## ##    ##
// ##       ##     ## ##
// ##       ##     ## ##   ####
// ##       ##     ## ##    ##
// ##       ##     ## ##    ##
// ########  #######   ######

#scope_export
Mapper_Logarithmic :: struct {
    using mapper: Mapper;
    mapper_linear: *Mapper_Linear;
    base: float32;
    invlogbase: float32;
}
#scope_module
clone :: (m: *Mapper_Logarithmic) -> *Mapper_Logarithmic {
    res := New(Mapper_Logarithmic);
    res.type = .LOGARITHMIC;
    res.mapper_linear = clone(m.mapper_linear);
    res.base = m.base;
    res.invlogbase = m.invlogbase;
    return res;
}
#scope_export
mapper_logarithmic :: (base: float32 = 10.0) -> *Mapper_Logarithmic {
    res := New(Mapper_Logarithmic);
    res.type = .LOGARITHMIC;
    res.mapper_linear = mapper_linear();
    res.base = base;
    res.invlogbase = 1.0/Math.log(base);
    return res;
}
#scope_module
map :: inline (using ml: *Mapper_Logarithmic, x: float32) -> float32 {
    // if x <= 0.0 then return Math.FLOAT32_MIN;
    return map(mapper_linear, Math.log(x) * invlogbase);
}
map_inv :: inline (using ml: *Mapper_Logarithmic, y: float32) -> float32 {
    return Math.pow(base, map_inv(mapper_linear, y));
}
fit :: (using ml: *Mapper_Logarithmic, x: float32, y: float32) {
    fit(mapper_linear, Math.log(x)*invlogbase, y);
}
fit_bounds :: (using ml: *Mapper_Logarithmic, min_x: float32, max_x: float32, min_y: float32, max_y: float32) {
    if min_x <= 0.0 then return;
    if Math.isinf(max_x) then return;
    fit_bounds(
        mapper_linear, 
        Math.log(min_x)*invlogbase,
        Math.log(max_x)*invlogbase,
        min_y, max_y
    );
}



//  ######   #######  ##    ##  ######  ######## ########     ###    #### ##    ## ########
// ##    ## ##     ## ###   ## ##    ##    ##    ##     ##   ## ##    ##  ###   ##    ##
// ##       ##     ## ####  ## ##          ##    ##     ##  ##   ##   ##  ####  ##    ##
// ##       ##     ## ## ## ##  ######     ##    ########  ##     ##  ##  ## ## ##    ##
// ##       ##     ## ##  ####       ##    ##    ##   ##   #########  ##  ##  ####    ##
// ##    ## ##     ## ##   ### ##    ##    ##    ##    ##  ##     ##  ##  ##   ###    ##
//  ######   #######  ##    ##  ######     ##    ##     ## ##     ## #### ##    ##    ##

#scope_export
Mapper_Constraint :: struct {
    using _m: Mapper;
    inner: *Mapper;

    fixed_min_x, fixed_max_x, fixed_min_y, fixed_max_y: bool = false;
    min_x, max_x, min_y, max_y : float32;
}
#scope_module
clone :: (m: *Mapper_Constraint) -> *Mapper_Constraint {
    res := New(Mapper_Constraint);
    res.type = .CONSTRAINT; 
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
mapper_constraint :: (
    inner: *Mapper, 
    min_x: float32 = Math.FLOAT32_NAN,
    max_x: float32 = Math.FLOAT32_NAN,
    min_y: float32 = Math.FLOAT32_NAN,
    max_y: float32 = Math.FLOAT32_NAN
) -> *Mapper_Constraint {
    res := New(Mapper_Constraint);
    res.type = .CONSTRAINT;
    res.inner = inner;

    if !Math.isnan(min_x) { res.min_x = min_x; res.fixed_min_x = true; }
    if !Math.isnan(max_x) { res.max_x = max_x; res.fixed_max_x = true; }
    if !Math.isnan(min_y) { res.min_y = min_y; res.fixed_min_y = true; }
    if !Math.isnan(max_y) { res.max_y = max_y; res.fixed_max_y = true; }

    return res;
}
#scope_module
map :: inline (using cm: *Mapper_Constraint, x: float32) -> float32 {
    return map(inner, x);
}
map_inv :: inline (using cm: *Mapper_Constraint, y: float32) -> float32 {
    return map_inv(inner, y);
}
fit :: inline (cm: *Mapper_Constraint, x: float32, y: float32) {
    cm.fixed_min_x = true;
    cm.fixed_max_x = true;
    cm.fixed_min_y = true;
    cm.fixed_max_y = true;
    fit(cm.inner, x, y);
    cm.min_x = map_inv(cm.inner, cm.min_y);
    cm.max_x = map_inv(cm.inner, cm.max_y);
}
fit_bounds :: (cm: *Mapper_Constraint, min_x: float32, max_x: float32, min_y: float32, max_y: float32, overwrite_constraints: bool = false) {
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


