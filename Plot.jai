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
}
Style2D_Line :: struct {
    using _s: Style2D;
    color: Color;
}
line :: (color: Color = RED) -> *Style2D_Line {
    res := New(Style2D_Line);
    res.type = .LINE;
    res.color = color;
    return res;
}
Style2D_Symbols :: struct {
    using _s: Style2D;
    color: Color;
}
symbols :: (color: Color = RED) -> *Style2D_Symbols {
    res := New(Style2D_Symbols);
    res.type = .SYMBOLS;
    res.color = color;
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
draw :: (using data: Data2D) {
    if style.type == {
        case .LINE;
            linestyle := cast(*Style2D_Line)style;
            DrawLines(v, linestyle.color, 2.0);
        case .SYMBOLS;
            symbolstyle := cast(*Style2D_Symbols)style;
            for v {
                DrawCircleV(it, 4.0, symbolstyle.color);
            }
        case .BARS;
            barstyle := cast(*Style2D_Bars)style;
            for i: 0..v.count-2 {
                h := cast(s32)(v[i].y-zero.y);

                if h > 0 {
                    DrawRectangle(
                        cast(s32)(v[i].x), 
                        cast(s32)(zero.y),
                        cast(s32)(v[i+1].x-v[i].x) + 1, 
                        h,
                        barstyle.color
                    );
                } else {
                    DrawRectangle(
                        cast(s32)(v[i].x),
                        cast(s32)(zero.y + h), 
                        cast(s32)(v[i+1].x-v[i].x) + 1, 
                        -h,
                        barstyle.color
                    );
                }
            }
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
    from_min, from_max: float32;
    to_min, to_max: float32;
    fixed_min, fixed_max: bool;
}
mapper :: (from_min: float32, from_max: float32, to_min: float32, to_max: float32, type: Mapper_Type = .LINEAR) -> Mapper {
    res : Mapper = ---;
    res.type = type;
    res.from_min = from_min;
    res.from_max = from_max;
    res.to_min   = to_min;
    res.to_max   = to_max;
    res.fixed_max = false;
    res.fixed_min = false;
    return res;
}
set_min :: (m: *Mapper, min: float32) {
    m.from_min = min;
    m.fixed_min = true;
}
set_max :: (m: *Mapper, max: float32) {
    m.from_max = max;
    m.fixed_max = true;
}
set_min_max :: (m: *Mapper, min: float32, max: float32) {
    set_min(m, min);
    set_max(m, max);
}
map :: inline (using mapper: Mapper, x: float32) -> float32 {
    if type == {
        case .LINEAR;
            return (x-from_min)/(from_max-from_min)*(to_max-to_min) + to_min;
    }
}
map_delta :: inline (using mapper: Mapper, dx: float32) -> float32 {
    if type == {
        case .LINEAR;
            return dx/(from_max-from_min)*(to_max-to_min);
    }
}
fit_data :: (using mapper: *Mapper, vals: []float32, $reset: bool = true) {
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
}







CartesianAxis2D :: struct {
    using rect: Rectangle;
    using axis: Axis;

    x_mapper: Mapper;
    y_mapper: Mapper;

    show_frame: bool = true;
    show_zero_lines: bool = true;
    show_grid: bool = true;
    show_subgrid: bool = true;
}
cartesian_axis_2d :: () -> *CartesianAxis2D {
    res := New(CartesianAxis2D);
    res.axis_type = .CARTESIAN_2D;
    res.rect      = window_rect;
    res.datasets  = NewResizableArray(0, Data2D);
    
    res.x_mapper  = mapper(0.0, 1.0, window_rect.x, window_rect.x+window_rect.width);
    res.y_mapper  = mapper(0.0, 1.0, window_rect.y, window_rect.y+window_rect.height);
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
        print("fit_data [%/%]\n", it_index, datasets.count-1);
        print("it = %\n", it);
        if it_index == 0 {
            fit_data(*x_mapper, it.x, true);
            fit_data(*y_mapper, it.y, true);
        } else {
            fit_data(*x_mapper, it.x, false);
            fit_data(*y_mapper, it.y, false);
        }
    }
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
            for e, ei: it.v_extra {
                e[i] = map(it.extra_mappers[ei], it.extra[ei][i]);
            }
        }
    }
}
draw :: (using ax: CartesianAxis2D) {
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

    if show_grid {
        draw_gridlines(true , -1.0, GREY, 2.0, true);
        draw_gridlines(false, -1.0, GREY, 2.0, true);
    }

    for datasets {
        draw(it);
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


plot :: () {
    _plot.axes = NewResizableArray(0, *Axis);
    _plot.thread = New(Thread);
    thread_init(_plot.thread, plot_render);
    thread_start(_plot.thread);
}

plot_render :: (_thread: *Thread) -> s64 {
    // SetConfigFlags(xx (ConfigFlags.MSAA_4X_HINT | ConfigFlags.WINDOW_HIGHDPI | ConfigFlags.WINDOW_RESIZABLE));
    SetConfigFlags(xx (ConfigFlags.MSAA_4X_HINT | ConfigFlags.WINDOW_RESIZABLE));
    Window(cast(s32)window_rect.width, cast(s32)window_rect.height, "raylib [core] example - basic window [Jai]");
    SetTargetFPS(60);

    camera := camera2d();

    while !WindowShouldClose() {

        window_rect.width  = cast(float)GetScreenWidth();
        window_rect.height = cast(float)GetScreenHeight();

        Drawing();
        ClearBackground(RAYWHITE);
        Mode2D(camera);

        for _plot.axes {
            if it.axis_type == {
                case .CARTESIAN_2D;
                    ax := cast(*CartesianAxis2D)it;
                    fit_into_rectangle(ax, window_rect, vec4(100.0,50.0,50.0,60.0));
                    fit_data(ax);
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
    print("active_axis % <-> axes[0] %\n", _plot.active_axis, _plot.axes[0]);

    print("<<active_axis = %\n", <<_plot.active_axis);
    print("<<axes[0] = %\n"    , <<_plot.axes[0]);

    print("active_axis.datasets = %\n", (_plot.active_axis).datasets);
    print("axes[0].datasets = %\n"    , (_plot.axes[0]).datasets);
}

plot_wait_for_close :: () {
    while !thread_is_done(_plot.thread) {
        sleep_milliseconds(100);
        // print("waiting...\n");
    }

    print("plot successfully closed.\n");
}

