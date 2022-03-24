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
Style2D_Symbols :: struct {
    using _s: Style2D;
    color: Color;
    size: float32;
}
symbols :: (color: Color = RED, size: float32 = 4.0) -> *Style2D_Symbols {
    res := New(Style2D_Symbols);
    res.type = .SYMBOLS;
    res.color = color;
    res.size = size;
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
draw :: (data: Data2D) {

    draw_style :: (s: *Style2D) #expand {
        if s.type == {
            case .LINE;
                linestyle := cast(*Style2D_Line)s;
                DrawLines(data.v, linestyle.color, linestyle.thickness);
            case .SYMBOLS;
                symbolstyle := cast(*Style2D_Symbols)s;
                for data.v {
                    DrawCircleV(it, symbolstyle.size, symbolstyle.color);
                }
            case .BARS;
                barstyle := cast(*Style2D_Bars)s;
                for i: 0..data.v.count-2 {
                    h := cast(s32)(data.v[i].y-data.zero.y);

                    if h > 0 {
                        DrawRectangle(
                            cast(s32)(data.v[i].x), 
                            cast(s32)(data.zero.y),
                            cast(s32)(data.v[i+1].x-data.v[i].x) + 1, 
                            h,
                            barstyle.color
                        );
                    } else {
                        DrawRectangle(
                            cast(s32)(data.v[i].x),
                            cast(s32)(data.zero.y + h), 
                            cast(s32)(data.v[i+1].x-data.v[i].x) + 1, 
                            -h,
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
}

Mapper :: struct {
    type: Mapper_Type = .LINEAR;
}

Mapper_Linear :: struct {
    using _m: Mapper = Mapper.{.LINEAR};

    from_min, from_max: float32;
    to_min, to_max: float32;
    fixed_min, fixed_max: bool;
    
    fixed_scale: bool;
    scale: float32;
    center: float32;
}

mapper_linear :: (from_min: float32, from_max: float32, to_min: float32, to_max: float32) -> Mapper_Linear {
    res : Mapper_Linear;
    res.from_min = from_min;
    res.from_max = from_max;
    res.to_min   = to_min;
    res.to_max   = to_max;
    res.fixed_max = false;
    res.fixed_min = false;
    res.fixed_scale = false;
    res.scale = 1.0;
    res.center = 0.0;
    return res;
}
set_min :: (m: *Mapper_Linear, min: float32) {
    m.from_min = min;
    m.fixed_min = true;
    m.fixed_scale = false;
}
set_max :: (m: *Mapper_Linear, max: float32) {
    m.from_max = max;
    m.fixed_max = true;
    m.fixed_scale = false;
}
set_min_max :: (m: *Mapper_Linear, min: float32, max: float32) {
    set_min(m, min);
    set_max(m, max);
}
set_scale :: (m: *Mapper_Linear, scale: float32, center: float32 = 0.0) {
    m.fixed_scale = true;
    m.scale = scale;
    m.center = center;
    m.fixed_max = false;
    m.fixed_min = false;
}
map :: inline (using mapper: Mapper_Linear, x: float32) -> float32 {
    s := ifx fixed_scale then scale else (to_max-to_min)/(from_max-from_min);

    if type == {
        case .LINEAR;
            if fixed_scale {
                return (x-center) * s + (to_max + to_min)*0.5;
            } else {
                return (x-from_min) * s + to_min;
            }
    }
}
map_delta :: inline (using mapper: Mapper_Linear, dx: float32) -> float32 {
    s := ifx fixed_scale then scale else (to_max-to_min)/(from_max-from_min);

    if type == {
        case .LINEAR;
            return dx * s;
    }
}
fit_data :: (using mapper: *Mapper_Linear, vals: []float32, $reset: bool = true) {
    #if reset {
        if !fixed_min then from_min = Math.FLOAT32_MAX;
        if !fixed_max then from_max = Math.FLOAT32_MIN;
    }
    for vals {
        if !fixed_min && it < from_min then from_min = it;
        if !fixed_max && it > from_max then from_max = it;
    }
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
    datasets: [..]Data2D;
    axis_type: Axis_Type;
    rect: Rectangle;
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
    
    res.x_mapper = ifx x_mapper then x_mapper else mapper_linear(0.0, 1.0, window_rect.x, window_rect.x+window_rect.width);
    res.y_mapper = ifx y_mapper then y_mapper else mapper_linear(0.0, 1.0, window_rect.y, window_rect.y+window_rect.height);
    return res;
}

fit_into_rectangle :: (ax: *CartesianAxis2D, rectangle: Rectangle, padding: Vector4) {
    fit_into_rectangle(*ax.rect, rectangle, padding);

    ax.x_mapper.to_min = rectangle.x + padding.x;
    ax.x_mapper.to_max = rectangle.x + rectangle.width - padding.y;

    ax.y_mapper.to_min = rectangle.y + padding.z;
    ax.y_mapper.to_max = rectangle.y + rectangle.height - padding.w;
}

fit_data :: (using ax: CartesianAxis2D) {
    for datasets {
        if it_index == 0 {
            fit_data(*x_mapper, it.x, true);
            fit_data(*y_mapper, it.y, true);
        } else {
            fit_data(*x_mapper, it.x, false);
            fit_data(*y_mapper, it.y, false);
        }
    }
}
map :: (using ax: CartesianAxis2D, shift:= Vector2.{0.0, 0.0}) {
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
            ) + shift;
            for e, ei: it.v_extra {
                e[i] = map(it.extra_mappers[ei], it.extra[ei][i]);
            }
        }
    }
}
draw :: (using ax: CartesianAxis2D, shift := Vector2.{0.0, 0.0}) {

    _x_to_min := x_mapper.to_min;
    _x_to_max := x_mapper.to_max;
    _y_to_min := y_mapper.to_min;
    _y_to_max := y_mapper.to_max;
    x_mapper.to_min += shift.x;
    x_mapper.to_max += shift.x;
    y_mapper.to_min += shift.y;
    y_mapper.to_max += shift.y;
    defer {
        x_mapper.to_min = _x_to_min;
        x_mapper.to_max = _x_to_max;
        y_mapper.to_min = _y_to_min;
        y_mapper.to_max = _y_to_max;
    }


    grid_div := 10.0;
    min_grid_gap_px := 20.0;

    draw_gridlines :: (x_axis: bool, exponent_shift: float32, color: Color, thickness: float = 1.0, $show_ticks: bool = false) #expand {
        dx := ifx x_axis then x_mapper.from_max - x_mapper.from_min else y_mapper.from_max - y_mapper.from_min;
        exponent := Math.log(dx)/Math.log(grid_div);
        division := Math.pow(grid_div, Math.ceil(exponent + exponent_shift));
        pixel_separation := ifx x_axis then map_delta(x_mapper, division) else map_delta(y_mapper, division);
        if pixel_separation > min_grid_gap_px {
            if x_axis {
                px := (cast(s32)Math.ceil(x_mapper.from_min/division))*division;
                tick_line := vec2(0.0, 10.0);
                while px <= x_mapper.from_max {
                    x_pix := map(x_mapper, px);
                    DrawLineEx(
                        vec2(x_pix, y_mapper.to_min),
                        vec2(x_pix, y_mapper.to_max) + tick_line, 
                        thickness,
                        color
                    );
                    #if show_ticks {
                        tick := sprint("%", formatFloat(px, trailing_width = 1, mode = .SCIENTIFIC));
                        defer free(tick);
                        DrawText(tick, cast(s32)x_pix, cast(s32)(rect.y+rect.height)+15, 12, BLACK);
                    }
                    px += division;
                }
            } else {
                px := (cast(s32)Math.ceil(y_mapper.from_min/division))*division;
                tick_line := vec2(-10.0, 0.0);
                while px <= y_mapper.from_max {
                    y_pix := map(y_mapper, px);
                    DrawLineEx(
                        vec2(x_mapper.to_min, map(y_mapper, px)) + tick_line,
                        vec2(x_mapper.to_max, map(y_mapper, px)), 
                        thickness,
                        color
                    );
                    #if show_ticks {
                        tick := sprint("%", formatFloat(px, trailing_width = 1, mode = .SCIENTIFIC));
                        defer free(tick);
                        DrawText(tick, cast(s32)rect.x - 75, cast(s32)y_pix, 12, BLACK);
                    }
                    px += division;
                }
            }
        }
    }
    
    if show_subgrid {
        draw_gridlines(true , -2.0, LIGHTGREY);
        draw_gridlines(false, -2.0, LIGHTGREY);
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
        draw_gridlines(true , -1.5, Color.{ 130, 130, 130, 125 }, 1.5, true);
        draw_gridlines(false, -1.5, Color.{ 130, 130, 130, 125 }, 1.5, true);
    }

    if show_zero_lines {
        if x_mapper.from_min < 0 && x_mapper.from_max > 0 {
            DrawLineEx(
                vec2(map(x_mapper, 0.0), y_mapper.to_min),
                vec2(map(x_mapper, 0.0), y_mapper.to_max),
                2.0,
                BLACK
            );
        }
        if y_mapper.from_min < 0 && y_mapper.from_max > 0 {
            DrawLineEx(
                vec2(x_mapper.to_min, map(y_mapper, 0.0)),
                vec2(x_mapper.to_max, map(y_mapper, 0.0)),
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
}

_plot : Plot;
mouse: Mouse;

plot :: () {
    _plot.axes = NewResizableArray(0, *Axis);
    _plot.thread = New(Thread);
    thread_init(_plot.thread, plot_render);
    thread_start(_plot.thread);
}

plot_render :: (_thread: *Thread = null) -> s64 {
    // SetConfigFlags(xx (ConfigFlags.MSAA_4X_HINT | ConfigFlags.WINDOW_HIGHDPI | ConfigFlags.WINDOW_RESIZABLE));
    SetConfigFlags(xx (ConfigFlags.MSAA_4X_HINT | ConfigFlags.WINDOW_RESIZABLE));
    Window(cast(s32)window_rect.width, cast(s32)window_rect.height, "raylib [core] example - basic window [Jai]");
    SetTargetFPS(60);

    camera := camera2d();

    while !WindowShouldClose() {

        window_rect.width  = cast(float)GetScreenWidth();
        window_rect.height = cast(float)GetScreenHeight();

        if IsMouseButtonDown(0) && mouse.state == .FREE {
            print("dragging\n");
            mouse.state = .DRAGGING;
            mouse._x = GetMouseX();
            mouse._y = GetMouseY();
            for _plot.axes {
                if CheckCollisionPointRec(vec2(cast(float32)mouse._x, cast(float32)mouse._y), it.rect) {
                    mouse.active_axis = it;
                }
            }
        }
        if !IsMouseButtonDown(0) && mouse.state == .DRAGGING {
            print("free\n");
            mouse.state = .FREE;
            print("dx = %\n", mouse.x-mouse._x);
            print("dy = %\n", mouse.y-mouse._y);
            if mouse.active_axis.axis_type == {
                case .CARTESIAN_2D;
                    ax := cast(*CartesianAxis2D)mouse.active_axis;
                    ax.x_mapper.to_min += cast(float32)(mouse.x-mouse._x);
                    ax.x_mapper.to_max += cast(float32)(mouse.x-mouse._x);
                    ax.y_mapper.to_min += cast(float32)(mouse.y-mouse._y);
                    ax.y_mapper.to_max += cast(float32)(mouse.y-mouse._y);
                    print("mouse drag assigned\n");
            }
        }
        mouse.x = GetMouseX();
        mouse.y = GetMouseY();


        Drawing();
        ClearBackground(RAYWHITE);
        Mode2D(camera);

        for _plot.axes {
            if it.axis_type == {
                case .CARTESIAN_2D;
                    ax := cast(*CartesianAxis2D)it;
                    fit_into_rectangle(ax, window_rect, vec4(100.0,50.0,50.0,60.0));
                    fit_data(ax);
                    shift := ifx mouse.state == .DRAGGING && mouse.active_axis == ax then 
                        vec2(cast(float32)(mouse.x-mouse._x), cast(float32)(mouse.y-mouse._y)) 
                    else vec2();
                    map(ax, shift);
                    draw(ax, shift);
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

