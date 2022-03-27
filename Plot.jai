#import "Windows";
#import "Basic";
Math :: #import "Math";
#import "Thread";
#load "Utils.jai";
#load "jai-raylib.jai";


window_rect := Rectangle.{0,0,800,600};


fit_into_rectangle :: (r: *Rectangle, rectangle: Rectangle, padding: Vector4) {
    r.x = rectangle.x + padding.x;
    r.y = rectangle.y + padding.y;
    r.width  = rectangle.width  - (padding.x + padding.z);
    r.height = rectangle.height - (padding.y + padding.w);
}


//  ######   ##     ## ####
// ##    ##  ##     ##  ##
// ##        ##     ##  ##
// ##   #### ##     ##  ##
// ##    ##  ##     ##  ##
// ##    ##  ##     ##  ##
//  ######    #######  ####



gui_button :: (
    rect: Rectangle, 
    text := "", 
    font_size : s32 = 12, 
    line_color := GREY, 
    fill_color := RAYWHITE
) -> bool {
    m := vec2(cast(float32)_mouse.x, cast(float32)_mouse.y);
    over := CheckCollisionPointRec(m, rect);

    text_width := MeasureText(text, font_size);

    tx := cast(s32)(rect.width  * 0.5 + rect.x - 0.5 * text_width);
    ty := cast(s32)(rect.height * 0.5 + rect.y - 0.5 * font_size );

    if IsMouseButtonPressed(0) && over {
        DrawRectangleRec(rect, fill_color * 0.5);
        DrawRectangleLinesEx(rect, 2.0, line_color);
        DrawText(text, tx, ty, font_size, BLACK);
        return true;
    } else if over {
        DrawRectangleRec(rect, fill_color);
        DrawRectangleLinesEx(rect, 2.0, RED);
        DrawText(text, tx, ty, font_size, BLACK);
        return false;
    } else {
        DrawRectangleRec(rect, fill_color);
        DrawRectangleLinesEx(rect, 2.0, line_color);
        DrawText(text, tx, ty, font_size, BLACK);
        return false;
    }
}




//  ######  ######## ##    ## ##       ########     #######  ########
// ##    ##    ##     ##  ##  ##       ##          ##     ## ##     ##
// ##          ##      ####   ##       ##                 ## ##     ##
//  ######     ##       ##    ##       ######       #######  ##     ##
//       ##    ##       ##    ##       ##          ##        ##     ##
// ##    ##    ##       ##    ##       ##          ##        ##     ##
//  ######     ##       ##    ######## ########    ######### ########

Style2D :: struct{
    type: Style2D_Type;
}
Style2D_Type :: enum u8 {
    LINE;
    SYMBOLS;
    BARS;
    MULTI;
}
Style2D_Line :: struct {
    using _s: Style2D;
    color: Color;
    thickness: float32;
}
line :: (color: Color = RED, thickness: float32 = 2.0) -> *Style2D_Line {
    res := New(Style2D_Line);
    res.type = .LINE;
    res.color = color;
    res.thickness = thickness;
    return res;
}


SYMBOL_SIZE :: 128;
Symbols :: enum u8 {
    CIRCLE :: 0;
    SQUARE :: 1;
    PLUS   :: 2;
    X      :: 3;
}
symbol_render_textures : [4]RenderTexture2D;
init_symbol_texture :: () {
    for *symbol_render_textures {
        tex := LoadRenderTexture(SYMBOL_SIZE,SYMBOL_SIZE);
        TextureMode(tex, #code {
            ClearBackground(Color.{255,255,255,0});
            if cast(Symbols)it_index == {
                case .CIRCLE;
                    DrawCircleV(0.5*vec2(SYMBOL_SIZE+0.5, SYMBOL_SIZE+0.5), SYMBOL_SIZE/2, WHITE);
                case .SQUARE;
                    DrawRectangle(0, 0, SYMBOL_SIZE, SYMBOL_SIZE, WHITE);
                case .PLUS;
                    half_linewidth := SYMBOL_SIZE * 1.0 / 5.0 * 0.5;
                    mid := 0.5 * SYMBOL_SIZE;
                    DrawRectangleV(vec2(mid-half_linewidth, 0), vec2(2.0*half_linewidth, SYMBOL_SIZE), WHITE);
                    DrawRectangleV(vec2(0, mid-half_linewidth), vec2(SYMBOL_SIZE, 2.0*half_linewidth), WHITE);
                case .X;
                    DrawLineEx(vec2(), SYMBOL_SIZE*vec2(1.0,1.0), 0.3*SYMBOL_SIZE, WHITE);
                    DrawLineEx(SYMBOL_SIZE*vec2(0.0,1.0), SYMBOL_SIZE*vec2(1.0,0.0), 0.3*SYMBOL_SIZE, WHITE);
            }
        });
        <<it = tex;
    }
}
Style2D_Symbols :: struct {
    using _s: Style2D;
    color: Color;
    size: float32;
    symbol: Symbols;
}
symbols :: (symbol := Symbols.CIRCLE, color := RED, size: float32 = 4.0, symbol_resolution: s32 = 32) -> *Style2D_Symbols {
    res := New(Style2D_Symbols);
    res.type = .SYMBOLS;
    res.color = color;
    res.size = size;
    res.symbol = symbol;
    return res;
}



Style2D_Bars :: struct {
    using _s: Style2D;
    color: Color;
}
bars :: (color: Color) -> *Style2D_Bars {
    res := New(Style2D_Bars);
    res.type = .BARS;
    res.color = color;
    return res;
}
Style2D_Multi :: struct {
    using _s: Style2D;
    styles: []*Style2D;
}
multi :: (styles: ..*Style2D) -> *Style2D_Multi {
    res := New(Style2D_Multi);
    res.type = .MULTI;
    res.styles = styles;
    return res;
}





// ########     ###    ########    ###        #######  ########
// ##     ##   ## ##      ##      ## ##      ##     ## ##     ##
// ##     ##  ##   ##     ##     ##   ##            ## ##     ##
// ##     ## ##     ##    ##    ##     ##     #######  ##     ##
// ##     ## #########    ##    #########    ##        ##     ##
// ##     ## ##     ##    ##    ##     ##    ##        ##     ##
// ########  ##     ##    ##    ##     ##    ######### ########

Data2D :: struct {
    x: []float32;
    y: []float32;

    extra: [][]float32;
    extra_mappers: []Mapper;
    
    zero: Vector2;
    v: [..]Vector2;
    v_extra: [][..]float32;

    style: *Style2D;
}
data2d :: (
    x: []float32,
    y: []float32,
    extra: [][]float32, 
    extra_mappers: []Mapper,
    style: *Style2D
) -> Data2D {
    N := x.count;
    assert(N == y.count);
    for extra {
        assert(it.count == N);
    }
    K := extra.count;
    assert(K == extra_mappers.count);

    res : Data2D;
    res.x = x;
    res.y = y;
    res.extra = extra;
    res.extra_mappers = extra_mappers;
    res.zero = vec2();
    res.v = NewResizableArray(N, Vector2);
    res.v_extra = NewArray(K, [..]float32);
    for *res.v_extra {
        <<it = NewResizableArray(N, float32);
    }
    res.style = style;
    return res;
}
bounds_x :: (using data: Data2D) -> float32, float32 {
    return min(x), max(x);
}
bounds_y :: (using data: Data2D) -> float32, float32 {
    return min(y), max(y);
}
bounds_extra :: (using data: Data2D, index: int) -> float32, float32 {
    return min(extra[index]), max(extra[index]);
}
draw :: (data: Data2D) {

    draw_style :: (s: *Style2D) #expand {
        if s.type == {
            case .LINE;
                linestyle := cast(*Style2D_Line)s;
                DrawLines(data.v, linestyle.color, linestyle.thickness);
            case .SYMBOLS;
                symbolstyle := cast(*Style2D_Symbols)s;
                for data.v {
                    tex := symbol_render_textures[symbolstyle.symbol].texture;
                    // print("symbolstyle.symbol = %, tex = %\n", symbolstyle.symbol, tex);
                    s := symbolstyle.size;
                    DrawTextureEx( tex, it - vec2(s,s), 0.0, s/(0.5*SYMBOL_SIZE), symbolstyle.color);
                    // DrawCircleV(it, symbolstyle.size, symbolstyle.color);
                }
            case .BARS;
                barstyle := cast(*Style2D_Bars)s;
                for i: 0..data.v.count-2 {
                    h := data.v[i].y-data.zero.y;

                    if h > 0 {
                        DrawRectangleV(
                            vec2(data.v[i].x, data.zero.y), 
                            vec2(data.v[i+1].x-data.v[i].x, h), 
                            barstyle.color
                        );
                    } else {
                        DrawRectangleV(
                            vec2(data.v[i].x, data.zero.y+h), 
                            vec2(data.v[i+1].x-data.v[i].x, -h), 
                            barstyle.color
                        );
                    }
                }
        }
    }

    if data.style.type == .MULTI {
        multistyle := cast(*Style2D_Multi)data.style;
        for multistyle.styles {
            draw_style(it);
        }
    } else {
        draw_style(data.style);
    }
    
}









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

Mapper :: struct {
    type: Mapper_Type = .LINEAR;
}
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








Mapper_Linear :: struct {
    using _m: Mapper;
    y0, dydx : float32;
}
clone :: (m: *Mapper_Linear) -> *Mapper_Linear {
    res := New(Mapper_Linear);
    res.type = .LINEAR;
    res.y0 = m.y0;
    res.dydx = m.dydx;
    return res;
}
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




Mapper_Logarithmic :: struct {
    using mapper: Mapper;
    mapper_linear: *Mapper_Linear;
    base: float32;
    invlogbase: float32;
}
clone :: (m: *Mapper_Logarithmic) -> *Mapper_Logarithmic {
    res := New(Mapper_Logarithmic);
    res.type = .LOGARITHMIC;
    res.mapper_linear = clone(m.mapper_linear);
    res.base = m.base;
    res.invlogbase = m.invlogbase;
    return res;
}
mapper_logarithmic :: (base: float32 = 10.0) -> *Mapper_Logarithmic {
    res := New(Mapper_Logarithmic);
    res.type = .LOGARITHMIC;
    res.mapper_linear = mapper_linear();
    res.base = base;
    res.invlogbase = 1.0/Math.log(base);
    return res;
}
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
    if min_x < 0.0 then return;
    fit_bounds(
        mapper_linear, 
        Math.log(min_x)*invlogbase,
        Math.log(max_x)*invlogbase,
        min_y, max_y
    );
}






Mapper_Constraint :: struct {
    using _m: Mapper;
    inner: *Mapper;

    fixed_min_x, fixed_max_x, fixed_min_y, fixed_max_y: bool = false;
    min_x, max_x, min_y, max_y : float32;
}
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








ticks_linear :: (min_x: float32, max_x: float32, base: float32 = 10.0, exponent_shift: float32 = 0.0) -> [..]float32 {
    range := max_x - min_x;
    dx, exp := round_to_base(range);

    if dx > 0.5 * range then dx /= base;

    res := NewResizableArray(cast(s32)(range/dx), float32);
    x := cast(float32)Math.ceil(min_x/dx) * dx;
    while x < max_x {
        array_add(*res, x);
        x += dx;
    }
    return res;
}





//    ###    ##     ## ####  ######
//   ## ##    ##   ##   ##  ##    ##
//  ##   ##    ## ##    ##  ##
// ##     ##    ###     ##   ######
// #########   ## ##    ##        ##
// ##     ##  ##   ##   ##  ##    ##
// ##     ## ##     ## ####  ######

Axis_Type :: enum u8 {
    CARTESIAN_2D;
}
Axis :: struct {
    using rect: Rectangle;
    axis_type: Axis_Type;
    datasets: [..]Data2D;
}

reset :: (ax: *Axis) {
    if ax.axis_type == {
        case .CARTESIAN_2D;
            ca := cast(*CartesianAxis2D)ax;
            reset(ca);
    }
}
zoom :: (ax: *Axis, wheel: float32) {
    if ax.axis_type == {
        case .CARTESIAN_2D;
            ca := cast(*CartesianAxis2D)ax;
            zoom(ca, wheel);
    }
}
fit_data :: (ax: *Axis, overwrite_constraints: bool = false) {
    if ax.axis_type == {
        case .CARTESIAN_2D;
            ca := cast(*CartesianAxis2D)ax;
            fit_data(ca, overwrite_constraints);
    }
}




bounds_x :: (using ax: *Axis) -> float32, float32 {
    assert(datasets.count > 0);
    _min, _max := bounds_x(datasets[0]);
    for i:1..datasets.count-1 {
        mi, ma := bounds_x(datasets[i]);
        _min = min(_min, mi);
        _max = max(_max, ma);
    }
    return _min, _max;
}
bounds_y :: (using ax: *Axis) -> float32, float32 {
    assert(datasets.count > 0);
    _min, _max := bounds_y(datasets[0]);
    for i:1..datasets.count-1 {
        mi, ma := bounds_y(datasets[i]);
        _min = min(_min, mi);
        _max = max(_max, ma);
    }
    return _min, _max;
}
bounds_extra :: (using ax: *Axis, index: int) -> float32, float32 {
    assert(datasets.count > 0);

    _min := Math.FLOAT32_MAX;
    _max := Math.FLOAT32_MIN;

    for datasets {
        if it.extra.count > index {
            mi,ma := bounds_extra(it, index);
            _min = min(_min, mi);
            _max = max(_max, ma);
        }
    }

    return _min, _max;
}






CartesianAxis2D :: struct {
    using axis: Axis;

    original_x_mapper: *Mapper;
    original_y_mapper: *Mapper;

    x_mapper: *Mapper;
    y_mapper: *Mapper;

    show_frame: bool = true;
    show_zero_lines: bool = true;
    show_grid: bool = true;
    show_subgrid: bool = true;
    hide_overflow: bool = true;
}
cartesian_axis_2d :: (x_mapper: *Mapper = null, y_mapper: *Mapper = null) -> *CartesianAxis2D {
    res := New(CartesianAxis2D);
    res.axis_type = .CARTESIAN_2D;
    res.rect      = window_rect;
    res.datasets  = NewResizableArray(0, Data2D);
    
    res.x_mapper = ifx x_mapper then x_mapper else mapper_linear();
    res.y_mapper = ifx y_mapper then y_mapper else mapper_linear();

    res.original_x_mapper = clone(res.x_mapper);
    res.original_y_mapper = clone(res.y_mapper);

    return res;
}
reset :: (axis: *CartesianAxis2D) {
    xm := axis.x_mapper;
    ym := axis.y_mapper;
    defer {
        free(xm);
        free(ym);
    }
    axis.x_mapper = clone(axis.original_x_mapper);
    axis.y_mapper = clone(axis.original_y_mapper);
}
zoom :: (axis: *CartesianAxis2D, wheel: float32) {
    xm := axis.x_mapper;
    ym := axis.y_mapper;
    defer {
        free(xm);
        free(ym);
    }

    delta := 0.02 * wheel;

    xmin := map_inv(axis.x_mapper, (_mouse.x - axis.x)               * delta + axis.x             );
    xmax := map_inv(axis.x_mapper, (_mouse.x - (axis.x+axis.width )) * delta + axis.x+axis.width  );
    ymin := map_inv(axis.y_mapper, (_mouse.y - axis.y)               * delta + axis.y             );
    ymax := map_inv(axis.y_mapper, (_mouse.y - (axis.y+axis.height)) * delta + axis.y+axis.height );

    new_inner_x_mapper: *Mapper;
    new_inner_y_mapper: *Mapper;

    // // ! This is really bad code......

    // print("x_mapper = %\n", <<axis.x_mapper);
    // print("y_mapper = %\n", <<axis.y_mapper);

    if axis.x_mapper.type == {
        case .LINEAR;
            new_inner_x_mapper = mapper_linear();
        case .LOGARITHMIC;
            logmapper := cast(*Mapper_Logarithmic)axis.x_mapper;
            new_inner_x_mapper = mapper_logarithmic(logmapper.base);
        case .CONSTRAINT;
            cm := cast(*Mapper_Constraint)axis.x_mapper;
            if cm.inner.type == {
                case .LINEAR;
                    new_inner_x_mapper = mapper_linear();
                case .LOGARITHMIC;
                    logmapper := cast(*Mapper_Logarithmic)cm.inner;
                    new_inner_x_mapper = mapper_logarithmic(logmapper.base);
            }
    }
    if axis.y_mapper.type == {
        case .LINEAR;
            new_inner_y_mapper = mapper_linear();
        case .LOGARITHMIC;
            logmapper := cast(*Mapper_Logarithmic)axis.y_mapper;
            new_inner_y_mapper = mapper_logarithmic(logmapper.base);
        case .CONSTRAINT;
            cm := cast(*Mapper_Constraint)axis.y_mapper;
            if cm.inner.type == {
                case .LINEAR;
                    new_inner_y_mapper = mapper_linear();
                case .LOGARITHMIC;
                    logmapper := cast(*Mapper_Logarithmic)cm.inner;
                    new_inner_y_mapper = mapper_logarithmic(logmapper.base);
            }
    }

    axis.x_mapper = mapper_constraint(
        new_inner_x_mapper, 
        // mapper_linear(), 
        xmin, 
        xmax, 
        axis.x, 
        axis.x + axis.width
    );
    axis.y_mapper = mapper_constraint(
        new_inner_y_mapper, 
        // mapper_linear(), 
        ymin, 
        ymax, 
        axis.y, 
        axis.y + axis.height
    );
}


equal_scaling :: (axis: *CartesianAxis2D) {
    xm := axis.x_mapper;
    ym := axis.y_mapper;
    defer {
        free(xm);
        free(ym);
    }

    dx := map_inv(axis.x_mapper, axis.x+axis.width ) - map_inv(axis.x_mapper, axis.x);
    dy := map_inv(axis.y_mapper, axis.y+axis.height) - map_inv(axis.y_mapper, axis.y);
    x0 := map_inv(axis.x_mapper, axis.x + 0.5*axis.width );
    y0 := map_inv(axis.y_mapper, axis.y + 0.5*axis.height);

    xmin, xmax, ymin, ymax : float32;
    if dx > dy {
        xmin = map_inv(axis.x_mapper, axis.x);
        xmax = map_inv(axis.x_mapper, axis.x + axis.width);
        dxdp := (xmax-xmin)/axis.width;
        ymin = -dxdp*axis.height*0.5 + y0;
        ymax =  dxdp*axis.height*0.5 + y0;
    } else {
        ymin = map_inv(axis.y_mapper, axis.y);
        ymax = map_inv(axis.y_mapper, axis.y + axis.height);
        dydp := (ymax-ymin)/axis.height;
        xmin = -dydp*axis.width*0.5 + x0;
        xmax =  dydp*axis.width*0.5 + x0;
    }

    axis.x_mapper = mapper_constraint(
        mapper_linear(), 
        xmin, 
        xmax, 
        axis.x, 
        axis.x + axis.width
    );
    axis.y_mapper = mapper_constraint(
        mapper_linear(), 
        ymin, 
        ymax, 
        axis.y, 
        axis.y + axis.height
    );
}

fit_data :: (using ax: *CartesianAxis2D, overwrite_constraints: bool = false) {
    if datasets.count == 0 then return;

    min_x := min(datasets[0].x);
    max_x := max(datasets[0].x);
    min_y := min(datasets[0].y);
    max_y := max(datasets[0].y);
    for i: 1..datasets.count-1 {
        min_x = min(min_x, min(datasets[i].x));
        max_x = max(max_x, max(datasets[i].x));
        min_y = min(min_y, min(datasets[i].y));
        max_y = max(max_y, max(datasets[i].y));
    }

    fit_bounds(x_mapper, min_x, max_x, x, x+width , overwrite_constraints);
    fit_bounds(y_mapper, min_y, max_y, y, y+height, overwrite_constraints);
}
map :: (using ax: *CartesianAxis2D) {
    for *datasets {
        it.zero = vec2(map(x_mapper, 0.0), map(y_mapper, 0.0));

        n := it.x.count;
        
        array_resize(*it.v, n, false);
        for e: it.v_extra {
            array_resize(*e, n, false);
        }
        
        for i: 0..n-1 {
            it.v[i] = vec2(
                map(x_mapper, it.x[i]),
                map(y_mapper, it.y[i])
            );
            // for e, ei: it.v_extra {
            //     e[i] = map(it.extra_mappers[ei], it.extra[ei][i]);
            // }
        }
    }
}
draw :: (using ax: *CartesianAxis2D) {

    grid_div := 10.0;
    min_grid_gap_px := 20.0;

    draw_gridlines :: ($x_axis: bool, exponent_shift: float32, color: Color, thickness: float = 1.0) #expand {
        #if x_axis {
            mi := map_inv(x_mapper, x      );
            ma := map_inv(x_mapper, x+width);
        } else {
            mi := map_inv(y_mapper, y       );
            ma := map_inv(y_mapper, y+height);
        }
        ticks := ticks_linear(mi, ma, 10.0, exponent_shift - log10_of_5 );
        defer array_free(ticks);

        for ticks {
            #if x_axis {
                tx := map(x_mapper, it);
                DrawLineEx(
                    vec2(tx, y), 
                    vec2(tx, y+height), 
                    thickness, 
                    color
                );
            } else {
                ty := map(y_mapper, it);
                DrawLineEx(
                    vec2(x      , ty), 
                    vec2(x+width, ty), 
                    thickness, 
                    color
                );
            }
        }
    }

    if show_subgrid {
        draw_gridlines(true , -1.0, LIGHTGREY, 1.0);
        draw_gridlines(false, -1.0, LIGHTGREY, 1.0);
    }

    for datasets {
        draw(it);
    }

    if hide_overflow {
        DrawRectangleV(vec2(0.0,0.0), vec2(rect.width, rect.y), RAYWHITE);
        DrawRectangleV(vec2(0.0, rect.y+rect.height), vec2(window_rect.width, window_rect.height), RAYWHITE);
        DrawRectangleV(vec2(0.0,0.0), vec2(rect.x, window_rect.height), RAYWHITE);
        DrawRectangleV(vec2(rect.x+rect.width,0.0), vec2(window_rect.width, window_rect.height), RAYWHITE);
    }

    if show_grid {
        draw_gridlines(true , 0.0, Color.{ 130, 130, 130, 125 }, 1.5);
        draw_gridlines(false, 0.0, Color.{ 130, 130, 130, 125 }, 1.5);
    }

    if show_zero_lines {
        x0 := map(x_mapper, 0.0);
        y0 := map(y_mapper, 0.0);

        if x < x0 && x0 < x+width {
            DrawLineEx(
                vec2(x0, y       ),
                vec2(x0, y+height),
                2.0,
                BLACK
            );
        }

        if y < y0 && y0 < y+height {
            DrawLineEx(
                vec2(x      , y0),
                vec2(x+width, y0),
                2.0,
                BLACK
            );
        }
    }

    if show_frame {
        DrawRectangleLinesEx(rect, 2.0, BLACK);
    }
}




// ##     ##  #######  ##     ##  ######  ########
// ###   ### ##     ## ##     ## ##    ## ##
// #### #### ##     ## ##     ## ##       ##
// ## ### ## ##     ## ##     ##  ######  ######
// ##     ## ##     ## ##     ##       ## ##
// ##     ## ##     ## ##     ## ##    ## ##
// ##     ##  #######   #######   ######  ########


_mouse : *Mouse_State;

Mouse_State_Types :: enum u8 {
    FREE;
    DRAGGING;
}
Mouse_State :: struct {
    type: Mouse_State_Types = .FREE;
    x: s32 = 0;
    y: s32 = 0;
}

update_mouse :: () {
    if IsMouseButtonDown(0) && _mouse.type == .FREE {
        print("dragging\n");
        // free(_mouse);
        x := cast(float32)GetMouseX();
        y := cast(float32)GetMouseY();

        for _plot.axes {
            if CheckCollisionPointRec(vec2(x, y), it) && it.axis_type == .CARTESIAN_2D {
                ca := cast(*CartesianAxis2D)it;
                _mouse = mouse_dragging(ca);
            }
        }
    }
    if !IsMouseButtonDown(0) && _mouse.type == .DRAGGING {
        print("free\n");
        md := cast(*Mouse_State_Dragging)_mouse;
        _mouse = cast(*Mouse_State)mouse_stop_dragging(md);
    }

    _mouse.x = GetMouseX();
    _mouse.y = GetMouseY();

    if _mouse.type == {
        case .FREE;
            mf := cast(*Mouse_State_Free)_mouse;
            update(mf);
        case .DRAGGING;
            md := cast(*Mouse_State_Dragging)_mouse;
            update(md);
    }
}

Mouse_State_Free :: struct {
    using mouse_state: Mouse_State;
}
mouse_free :: () -> *Mouse_State_Free {
    res := New(Mouse_State_Free);
    res.type = .FREE;
    res.x = GetMouseX();
    res.y = GetMouseY();
    return res;
}
update :: (using mouse: *Mouse_State_Free) {
    wheel := GetMouseWheelMove();
    mv := vec2(cast(float32)x, cast(float32)y);
    for _plot.axes {
        if CheckCollisionPointRec(mv, it) && wheel != 0.0 {
            // print("zoom %\n", wheel);
            zoom(it, wheel);
        }
    }
}

Mouse_State_Dragging :: struct {
    using mouse_state: Mouse_State;
    old_x: float32 = 0.0;
    old_y: float32 = 0.0;
    axis: *CartesianAxis2D;
}
mouse_dragging :: (axis: *CartesianAxis2D) -> *Mouse_State_Dragging {
    res := New(Mouse_State_Dragging);
    res.type = .DRAGGING;
    res.x = GetMouseX();
    res.y = GetMouseY();
    res.axis = axis;

    mx := ifx axis.x_mapper.type == .CONSTRAINT then (cast(*Mapper_Constraint)axis.x_mapper).inner else axis.x_mapper;
    my := ifx axis.y_mapper.type == .CONSTRAINT then (cast(*Mapper_Constraint)axis.y_mapper).inner else axis.y_mapper;
    res.old_x = map_inv(mx, cast(float32)res.x);
    res.old_y = map_inv(my, cast(float32)res.y);
    
    // replace the axis mappers with fully constraint ones for dragging
    axis.x_mapper = mapper_constraint(mx, map_inv(mx, axis.x), map_inv(mx, axis.x+axis.width ), axis.x, axis.x+axis.width );
    axis.y_mapper = mapper_constraint(my, map_inv(my, axis.y), map_inv(my, axis.y+axis.height), axis.y, axis.y+axis.height);
    
    return res;
}
update :: (using mouse: *Mouse_State_Dragging) {
    mx := cast(*Mapper_Constraint)axis.x_mapper;
    my := cast(*Mapper_Constraint)axis.y_mapper;

    fit(mx, old_x, cast(float32)x);
    fit(my, old_y, cast(float32)y);
}
mouse_stop_dragging :: (using mouse: *Mouse_State_Dragging) -> *Mouse_State_Free {
    m := mouse;
    defer free(m);
    return mouse_free();
}



// ########  ##        #######  ########
// ##     ## ##       ##     ##    ##
// ##     ## ##       ##     ##    ##
// ########  ##       ##     ##    ##
// ##        ##       ##     ##    ##
// ##        ##       ##     ##    ##
// ##        ########  #######     ##

Plot :: struct {
    thread: *Thread;
    axes: [..]*Axis;
    active_axis: *Axis;
    running: bool = false;
}

_plot : Plot;

plot :: (msaa : bool = true, highdpi: bool = false) {
    flags := ConfigFlags.WINDOW_RESIZABLE;
    if highdpi then flags |= ConfigFlags.WINDOW_HIGHDPI;
    if msaa    then flags |= ConfigFlags.MSAA_4X_HINT;
    SetConfigFlags(xx flags);

    _plot.axes = NewResizableArray(0, *Axis);
    _plot.thread = New(Thread);
    thread_init(_plot.thread, plot_render);
    thread_start(_plot.thread);

    while !_plot.running {
        sleep_milliseconds(10);
    }
}

plot_render :: (_thread: *Thread = null) -> s64 {
    Window(cast(s32)window_rect.width, cast(s32)window_rect.height, "Jai Plot");
    SetTargetFPS(60);

    init_symbol_texture();
    camera := camera2d();
    _mouse = cast(*Mouse_State)mouse_free();

    _plot.running = true;

    while !WindowShouldClose() {
        window_rect.width  = cast(float)GetScreenWidth();
        window_rect.height = cast(float)GetScreenHeight();

        update_mouse();

        Drawing();
        ClearBackground(RAYWHITE);
        Mode2D(camera);

        for _plot.axes {
            if it.axis_type == {
                case .CARTESIAN_2D;
                    ax := cast(*CartesianAxis2D)it;
                    fit_into_rectangle(ax, window_rect, vec4(50.0,50.0,50.0,50.0));
                    fit_data(ax);
                    map(ax);
                    draw(ax);
            }
        }

        rect := rectangle(50.0,15.0,50.0,20.0);
        if gui_button(rect, "reset") {
            print("reset\n");
            reset(_plot.axes[0]);
        }

        rect.x += 50.0 + 20.0;
        if gui_button(rect, "1:1") {
            print("1:1\n");
            if _plot.axes[0].axis_type == .CARTESIAN_2D {
                ax := cast(*CartesianAxis2D)_plot.axes[0];
                equal_scaling(ax);
            }
        }

        rect.x += 50.0 + 20.0;
        if gui_button(rect, "fit") {
            print("fit\n");
            fit_data(_plot.axes[0], true);
        }
    }

    return 0; // what is this for?
}


add_axis :: (ax: *Axis) -> int {
    array_add(*_plot.axes, ax);
    _plot.active_axis = ax;
    return _plot.axes.count-1;
}

axis :: (id: int) {
    _plot.active_axis = _plot.axes[id];
}
axis :: (ax: *Axis) {
    _plot.active_axis = ax;
}

plot2d :: (
    style: *Style2D,
    x: []float32, 
    y: []float32, 
    extra: [][]float32 = .[], 
    extra_mappers: []Mapper = .[]
) {
    dataset := data2d(x, y, extra, extra_mappers, style);
    array_add(*_plot.active_axis.datasets, dataset);
}

plot_wait_for_close :: () {
    while !thread_is_done(_plot.thread) {
        sleep_milliseconds(100);
    }
}

