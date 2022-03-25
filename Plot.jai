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





Mouse_State :: enum u8 {
    FREE;
    DRAGGING;
}

Mouse :: struct {
    x, y, _x, _y: s32 = 0;
    state: Mouse_State = .FREE;
    active_axis: *Axis = null;
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
}
symbol_render_textures : [1]RenderTexture2D;
init_symbol_texture :: () {
    for *symbol_render_textures {
        tex := LoadRenderTexture(SYMBOL_SIZE,SYMBOL_SIZE);
        TextureMode(tex, #code {
            ClearBackground(Color.{255,255,255,0});
            if cast(Symbols)it_index == {
                case Symbols.CIRCLE;
                    DrawCircleV(0.5*vec2(SYMBOL_SIZE+0.5, SYMBOL_SIZE+0.5), SYMBOL_SIZE/2, WHITE);
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
    res.symbol = .CIRCLE;
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
}

Mapper :: struct {
    type: Mapper_Type = .LINEAR;
}

map :: (m: *Mapper, x: float32) -> float32 {
    if m.type == {
        case .LINEAR;
            lm := cast(*Mapper_Linear)m;
            return map(lm, x);
        case .CONSTRAINT;
            cm := cast(*Mapper_Constraint)m;
            return map(cm, x);
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
    }
}
map_dx :: (m: *Mapper, dx: float32) -> float32 {
    if m.type == {
        case .LINEAR;
            lm := cast(*Mapper_Linear)m;
            return map_dx(lm, dx);
        case .CONSTRAINT;
            cm := cast(*Mapper_Constraint)m;
            return map_dx(cm, dx);
    }
}
fit_bounds :: (m: *Mapper, min_x: float32, max_x: float32, min_y: float32, max_y: float32) {
    if m.type ==  {
        case .LINEAR;
            lm := cast(*Mapper_Linear)m;
            fit_bounds(lm, min_x, max_x, min_y, max_y);
        case .CONSTRAINT;
            cm := cast(*Mapper_Constraint)m;
            fit_bounds(cm, min_x, max_x, min_y, max_y);
    }
}



Mapper_Linear :: struct {
    using _m: Mapper;
    y0, dydx : float32;
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
map_dx :: inline (using lm: *Mapper_Linear, dx: float32) -> float32 {
    return dydx * dx;
}
fit_bounds :: (using lm: *Mapper_Linear, min_x: float32, max_x: float32, min_y: float32, max_y: float32) {
    dydx = (max_y-min_y)/(max_x-min_x);
    // dydx * max_x + y0 = max_y => y0 = max_y - dydx * max_x
    y0 = max_y - dydx * max_x;
}




Mapper_Constraint :: struct {
    using _m: Mapper;
    inner: *Mapper;

    fixed_min_x, fixed_max_x, fixed_min_y, fixed_max_y: bool = false;
    min_x, max_x, min_y, max_y : float32;

    // fixed_scale: bool = false;
    // scale, center: float32;
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
map_dx :: inline (using cm: *Mapper_Constraint, dx: float32) -> float32 {
    return map_dx(inner, dx);
}
fit_bounds :: (cm: *Mapper_Constraint, min_x: float32, max_x: float32, min_y: float32, max_y: float32) {
    mi_x := ifx cm.fixed_min_x then cm.min_x else min_x;
    ma_x := ifx cm.fixed_max_x then cm.max_x else max_x;
    mi_y := ifx cm.fixed_min_y then cm.min_y else min_y;
    ma_y := ifx cm.fixed_max_y then cm.max_y else max_y;

    fit_bounds(cm.inner, mi_x, ma_x, mi_y, ma_y);
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
    return res;
}


fit_data :: (using ax: CartesianAxis2D) {
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

    fit_bounds(x_mapper, min_x, max_x, x, x+width);
    fit_bounds(y_mapper, min_y, max_y, y, y+height);
}
map :: (using ax: CartesianAxis2D) {
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
draw :: (using ax: CartesianAxis2D) {

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

        if ticks.count >= 2 {
            #if x_axis {
                if map_dx(x_mapper, ticks[1] - ticks[0]) < min_grid_gap_px then return;
            } else {
                if map_dx(y_mapper, ticks[1] - ticks[0]) < min_grid_gap_px then return;
            }
        }

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
mouse: Mouse;

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
    Window(cast(s32)window_rect.width, cast(s32)window_rect.height, "raylib [core] example - basic window [Jai]");
    SetTargetFPS(60);

    camera := camera2d();

    init_symbol_texture();

    _plot.running = true;

    while !WindowShouldClose() {

        window_rect.width  = cast(float)GetScreenWidth();
        window_rect.height = cast(float)GetScreenHeight();

        // if IsMouseButtonDown(0) && mouse.state == .FREE {
        //     print("dragging\n");
        //     mouse.state = .DRAGGING;
        //     mouse._x = GetMouseX();
        //     mouse._y = GetMouseY();
        //     for _plot.axes {
        //         if CheckCollisionPointRec(vec2(cast(float32)mouse._x, cast(float32)mouse._y), it.rect) {
        //             mouse.active_axis = it;
        //         }
        //     }
        // }
        // if !IsMouseButtonDown(0) && mouse.state == .DRAGGING {
        //     print("free\n");
        //     mouse.state = .FREE;
        //     print("dx = %\n", mouse.x-mouse._x);
        //     print("dy = %\n", mouse.y-mouse._y);
        //     if mouse.active_axis.axis_type == {
        //         case .CARTESIAN_2D;
        //             ax := cast(*CartesianAxis2D)mouse.active_axis;
        //             ax.x_mapper.to_min += cast(float32)(mouse.x-mouse._x);
        //             ax.x_mapper.to_max += cast(float32)(mouse.x-mouse._x);
        //             ax.y_mapper.to_min += cast(float32)(mouse.y-mouse._y);
        //             ax.y_mapper.to_max += cast(float32)(mouse.y-mouse._y);
        //             print("mouse drag assigned\n");
        //     }
        // }
        // mouse.x = GetMouseX();
        // mouse.y = GetMouseY();


        Drawing();
        ClearBackground(RAYWHITE);
        Mode2D(camera);

        for _plot.axes {
            if it.axis_type == {
                case .CARTESIAN_2D;
                    ax := cast(*CartesianAxis2D)it;
                    fit_into_rectangle(ax, window_rect, vec4(50.0,50.0,50.0,50.0));
                    fit_data(ax);
                    // shift := ifx mouse.state == .DRAGGING && mouse.active_axis == ax then 
                    //     vec2(cast(float32)(mouse.x-mouse._x), cast(float32)(mouse.y-mouse._y)) 
                    // else vec2();
                    map(ax);
                    draw(ax);
            }
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

