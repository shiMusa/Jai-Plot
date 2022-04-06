

//  ######   ########     ###    ########  ##     ##     #######  ########
// ##    ##  ##     ##   ## ##   ##     ## ##     ##    ##     ## ##     ##
// ##        ##     ##  ##   ##  ##     ## ##     ##           ## ##     ##
// ##   #### ########  ##     ## ########  #########     #######  ##     ##
// ##    ##  ##   ##   ######### ##        ##     ##    ##        ##     ##
// ##    ##  ##    ##  ##     ## ##        ##     ##    ##        ##     ##
//  ######   ##     ## ##     ## ##        ##     ##    ######### ########

Graph2D :: struct {
    type: Graph2D_Type;
}
Graph2D_Type :: enum u8 {
    LINE;
    SYMBOLS;
    BARS;

    MULTI;
}

draw :: (graph2d: *Graph2D, x_mapper: *Mapper, y_mapper: *Mapper) {
    if #complete graph2d.type == {
        case .LINE;
            g := cast(*Graph2D_Line)graph2d;
            draw(g, x_mapper, y_mapper);
        case .SYMBOLS;
            g := cast(*Graph2D_Symbols)graph2d;
            draw(g, x_mapper, y_mapper);
        case .BARS;
            g := cast(*Graph2D_Bars)graph2d;
            draw(g, x_mapper, y_mapper);
        case .MULTI;
            g := cast(*Graph2D_Multi)graph2d;
            draw(g, x_mapper, y_mapper);
    }
}
bounds_x :: (graph2d: *Graph2D) -> float32, float32 {
    mi, ma : float32;
    if #complete graph2d.type == {
        case .LINE;
            g := cast(*Graph2D_Line)graph2d;
            mi, ma = bounds_x(g);
        case .SYMBOLS;
            g := cast(*Graph2D_Symbols)graph2d;
            mi, ma = bounds_x(g);
        case .BARS;
            g := cast(*Graph2D_Bars)graph2d;
            mi, ma = bounds_x(g);
        case .MULTI;
            g := cast(*Graph2D_Multi)graph2d;
            mi, ma = bounds_x(g);
    }
    return mi, ma;
}
bounds_y :: (graph2d: *Graph2D) -> float32, float32 {
    mi, ma : float32;
    if #complete graph2d.type == {
        case .LINE;
            g := cast(*Graph2D_Line)graph2d;
            mi, ma = bounds_y(g);
        case .SYMBOLS;
            g := cast(*Graph2D_Symbols)graph2d;
            mi, ma = bounds_y(g);
        case .BARS;
            g := cast(*Graph2D_Bars)graph2d;
            mi, ma = bounds_y(g);
        case .MULTI;
            g := cast(*Graph2D_Multi)graph2d;
            mi, ma = bounds_y(g);
    }
    return mi, ma;
}



// ##       #### ##    ## ########
// ##        ##  ###   ## ##
// ##        ##  ####  ## ##
// ##        ##  ## ## ## ######
// ##        ##  ##  #### ##
// ##        ##  ##   ### ##
// ######## #### ##    ## ########

Graph2D_Line :: struct {
    using _s: Graph2D;
    x: []float32;
    y: []float32;
    color: Color;
    thickness: float32;
}
#scope_export
line :: (x: []float32, y: []float32, color: Color = RED, thickness: float32 = 2.0) -> *Graph2D_Line {
    res := New(Graph2D_Line);
    res.type = .LINE;
    res.x = x;
    res.y = y;
    res.color = color;
    res.thickness = thickness;
    return res;
}
#scope_module
draw :: (using graph: *Graph2D_Line, x_mapper: *Mapper, y_mapper: *Mapper) {
    mx := map(x_mapper, x);
    my := map(y_mapper, y);
    defer {
        array_free(mx);
        array_free(my);
    }
    DrawLines(mx, my, color, thickness);
}
bounds_x :: inline (using graph: *Graph2D_Line) -> float32, float32 {
    return min(x), max(x);
}
bounds_y :: inline (using graph: *Graph2D_Line) -> float32, float32 {
    return min(y), max(y);
}




//  ######  ##    ## ##     ## ########   #######  ##
// ##    ##  ##  ##  ###   ### ##     ## ##     ## ##
// ##         ####   #### #### ##     ## ##     ## ##
//  ######     ##    ## ### ## ########  ##     ## ##
//       ##    ##    ##     ## ##     ## ##     ## ##
// ##    ##    ##    ##     ## ##     ## ##     ## ##
//  ######     ##    ##     ## ########   #######  ########

SYMBOL_SIZE :: 128;

#scope_export
Symbols :: enum u8 {
    CIRCLE :: 0;
    SQUARE :: 1;
    PLUS   :: 2;
    X      :: 3;
}
#scope_module
symbol_render_textures : [4]RenderTexture2D;
init_symbol_texture :: () {
    for *symbol_render_textures {
        <<it = render_to_texture(SYMBOL_SIZE, SYMBOL_SIZE, #code {
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
    }
}
Graph2D_Symbols :: struct {
    using _s: Graph2D;
    x: []float32;
    y: []float32;
    color: Color;
    size: float32;
    symbol: Symbols;
}
#scope_export
symbols :: (x: []float32, y: []float32, symbol := Symbols.CIRCLE, color := RED, size: float32 = 4.0, symbol_resolution: s32 = 32) -> *Graph2D_Symbols {
    res := New(Graph2D_Symbols);
    res.type = .SYMBOLS;
    res.x = x;
    res.y = y;
    res.color = color;
    res.size = size;
    res.symbol = symbol;
    return res;
}
#scope_module
draw :: (using graph: *Graph2D_Symbols, x_mapper: *Mapper, y_mapper: *Mapper) {
    mx := map(x_mapper, x);
    my := map(y_mapper, y);
    defer {
        array_free(mx);
        array_free(my);
    }

    tex := symbol_render_textures[symbol].texture;
    for i: 0..x.count-1 {
        DrawTextureEx(tex, vec2(mx[i],my[i]) - vec2(size,size), 0.0, size/(0.5*SYMBOL_SIZE), color);
    }
}
bounds_x :: inline (using graph: *Graph2D_Symbols) -> float32, float32 {
    return min(x), max(x);
}
bounds_y :: inline (using graph: *Graph2D_Symbols) -> float32, float32 {
    return min(y), max(y);
}





// ########     ###    ########
// ##     ##   ## ##   ##     ##
// ##     ##  ##   ##  ##     ##
// ########  ##     ## ########
// ##     ## ######### ##   ##
// ##     ## ##     ## ##    ##
// ########  ##     ## ##     ##

BarType :: enum u8 {
    SIMPLE;
    CONNECTED;
}

Graph2D_Bars :: struct {
    using _s: Graph2D;
    x: []float32;
    y: []float32;
    color: Color;
    bar_type: BarType;
}
#scope_export
bars :: (x: []float32, y: []float32, color: Color, bar_type: BarType = .SIMPLE) -> *Graph2D_Bars {
    res := New(Graph2D_Bars);
    res.type = .BARS;
    res.color = color;
    res.bar_type = bar_type;
    res.x = x;
    res.y = y;
    return res;
}
#scope_module
draw :: (using graph: *Graph2D_Bars, x_mapper: *Mapper, y_mapper: *Mapper) {
    mx := map(x_mapper, x);
    my := map(y_mapper, y);
    defer {
        array_free(mx);
        array_free(my);
    }
    zero := vec2(map(x_mapper, 0.0), map(y_mapper, 0.0));

    if bar_type == {
        case .SIMPLE;
            for i: 0..mx.count-2 {
                h := my[i]-zero.y;

                if h > 0 {
                    DrawRectangleV(
                        vec2(mx[i]          , zero.y), 
                        vec2(mx[i+1] - mx[i], h     ), 
                        color
                    );
                } else {
                    DrawRectangleV(
                        vec2(mx[i]          , zero.y + h), 
                        vec2(mx[i+1] - mx[i], -h        ), 
                        color
                    );
                }
            }
        case .CONNECTED;
            for i: 0..mx.count-2 {
                h := my[i+1]-my[i];

                if h > 0 {
                    DrawRectangleV(
                        vec2(mx[i]          , my[i]), 
                        vec2(mx[i+1] - mx[i], h    ), 
                        color
                    );
                } else {
                    DrawRectangleV(
                        vec2(mx[i]          , my[i+1]), 
                        vec2(mx[i+1] - mx[i], -h     ), 
                        color
                    );
                }
            }
    }
}
bounds_x :: inline (using graph: *Graph2D_Bars) -> float32, float32 {
    return min(x), max(x);
}
bounds_y :: inline (using graph: *Graph2D_Bars) -> float32, float32 {
    return min(y), max(y);
}





// ##     ## ##     ## ##       ######## ####
// ###   ### ##     ## ##          ##     ##
// #### #### ##     ## ##          ##     ##
// ## ### ## ##     ## ##          ##     ##
// ##     ## ##     ## ##          ##     ##
// ##     ## ##     ## ##          ##     ##
// ##     ##  #######  ########    ##    ####

#scope_module
Graph2D_Multi :: struct {
    using _s: Graph2D;
    graphs2d: []*Graph2D;
}
#scope_export
multi :: (graphs2d: ..*Graph2D) -> *Graph2D_Multi {
    res := New(Graph2D_Multi);
    res.type = .MULTI;
    res.graphs2d = graphs2d;
    return res;
}
#scope_module
draw :: (using graph: *Graph2D_Multi, x_mapper: *Mapper, y_mapper: *Mapper) {
    for graphs2d {
        draw(it, x_mapper, y_mapper);
    }
}
bounds_x :: (using graph: *Graph2D_Multi) -> float32, float32 {
    _min := Math.FLOAT32_MAX;
    _max := Math.FLOAT32_MIN;

    for graphs2d {
        mi, ma := bounds_x(it);
        _min = ifx mi < _min then mi else _min;
        _max = ifx ma > _max then ma else _max;
    }

    return _min, _max;
}
bounds_y :: (using graph: *Graph2D_Multi) -> float32, float32 {
    _min := Math.FLOAT32_MAX;
    _max := Math.FLOAT32_MIN;

    for graphs2d {
        mi, ma := bounds_y(it);
        _min = ifx mi < _min then mi else _min;
        _max = ifx ma > _max then ma else _max;
    }

    return _min, _max;
}

