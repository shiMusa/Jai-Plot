

//  ######   ########     ###    ########  ##     ##     #######  ########
// ##    ##  ##     ##   ## ##   ##     ## ##     ##    ##     ## ##     ##
// ##        ##     ##  ##   ##  ##     ## ##     ##           ## ##     ##
// ##   #### ########  ##     ## ########  #########     #######  ##     ##
// ##    ##  ##   ##   ######### ##        ##     ##    ##        ##     ##
// ##    ##  ##    ##  ##     ## ##        ##     ##    ##        ##     ##
//  ######   ##     ## ##     ## ##        ##     ##    ######### ########


Graph_2D_Types :: Type.[
    Graph_2D_Line,
    Graph_2D_Bars,
    Graph_2D_Symbols,
    Graph_2D_Fill,
    Graph_2D_Boxes,
    Graph_2D_Multi
];

Graph_2D :: struct {
    type: Type;
}

draw :: (b: *Graph_2D, x_mapper: *Mapper, y_mapper: *Mapper) {
    #insert #run specialize(Graph_2D_Types, "draw", .["x_mapper", "y_mapper"]);
}
bounds_x :: (b: *Graph_2D) -> float32, float32 {
    #insert #run specialize(Graph_2D_Types, "bounds_x", num_return_vars=2);
}
bounds_y :: (b: *Graph_2D) -> float32, float32 {
    #insert #run specialize(Graph_2D_Types, "bounds_y", num_return_vars=2);
}



// ##       #### ##    ## ########
// ##        ##  ###   ## ##
// ##        ##  ####  ## ##
// ##        ##  ## ## ## ######
// ##        ##  ##  #### ##
// ##        ##  ##   ### ##
// ######## #### ##    ## ########

Graph_2D_Line :: struct {
    using _s : Graph_2D;
    x: []float32;
    y: []float32;
    color: Color;
    thickness: float32;
}
#scope_export
line :: (x: []float32, y: []float32, color: Color = RED, thickness: float32 = 2.0) -> *Graph_2D_Line {
    res := New(Graph_2D_Line);
    res.type = Graph_2D_Line;
    res.x = x;
    res.y = y;
    res.color = color;
    res.thickness = thickness;
    return res;
}
#scope_module
draw :: (using graph: *Graph_2D_Line, x_mapper: *Mapper, y_mapper: *Mapper) {
    mx := map(x_mapper, x);
    my := map(y_mapper, y);
    defer {
        array_free(mx);
        array_free(my);
    }
    DrawLines(mx, my, color, thickness);
}
bounds_x :: inline (using graph: *Graph_2D_Line) -> float32, float32 {
    return min(x), max(x);
}
bounds_y :: inline (using graph: *Graph_2D_Line) -> float32, float32 {
    return min(y), max(y);
}


// ######## #### ##       ##
// ##        ##  ##       ##
// ##        ##  ##       ##
// ######    ##  ##       ##
// ##        ##  ##       ##
// ##        ##  ##       ##
// ##       #### ######## ########

Graph_2D_Fill :: struct {
    using _s : Graph_2D;
    x: []float32;
    y1: []float32;
    y2: []float32;
    color: Color;
    direction: FillDirection;
}
#scope_export
FillDirection :: enum u8 {
    X;
    Y;
}
fill :: (direction: FillDirection, x: []float32, y1: []float32, y2: []float32 = .[], color: Color = RED) -> *Graph_2D_Fill {
    res := New(Graph_2D_Fill);
    res.type = Graph_2D_Fill;
    res.x = x;
    res.y1 = y1;
    res.y2 = y2;
    res.color = color;
    res.direction = direction;
    return res;
}
#scope_module
draw :: (using graph: *Graph_2D_Fill, x_mapper: *Mapper, y_mapper: *Mapper) {
    mx  := map(x_mapper, x);
    my1 := map(y_mapper, y1);
    my2 := map(y_mapper, y2);
    defer {
        array_free(mx);
        array_free(my1);
        array_free(my2);
    }
    zero := vec2(map(x_mapper, 0.0), map(y_mapper, 0.0));

    pts := NewArray(mx.count * 2, Vector2);
    defer array_free(pts);

    if #complete direction == {
        case .X;
            if my2.count == 0 {
                for i: 0..mx.count-1 {
                    pts[2*i  ] = vec2(mx[i], min(my1[i], zero.y));
                    pts[2*i+1] = vec2(mx[i], max(my1[i], zero.y));
                }
            } else {
                for i: 0..mx.count-1 {
                    pts[2*i  ] = vec2(mx[i], min(my1[i], my2[i]));
                    pts[2*i+1] = vec2(mx[i], max(my1[i], my2[i]));
                }
            }
        case .Y;
            if my2.count == 0 {
                for i: 0..mx.count-1 {
                    pts[2*i  ] = vec2(min(my1[i], zero.y), mx[i]);
                    pts[2*i+1] = vec2(max(my1[i], zero.y), mx[i]);
                }
            } else {
                for i: 0..mx.count-1 {
                    pts[2*i  ] = vec2(min(my1[i], my2[i]), mx[i]);
                    pts[2*i+1] = vec2(max(my1[i], my2[i]), mx[i]);
                }
            }
    }

    DrawTriangleStrip(pts, color);
}
bounds_x :: inline (using graph: *Graph_2D_Fill) -> float32, float32 {
    return min(x), max(x);
}
bounds_y :: inline (using graph: *Graph_2D_Fill) -> float32, float32 {
    if y2.count == 0 then return min(y1), max(y1);
    return min(min(y1), min(y2)), max(max(y1), max(y2));
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
Graph_2D_Symbols :: struct {
    using _s : Graph_2D;
    x: []float32;
    y: []float32;
    color: Color;
    size: float32;
    symbol: Symbols;
}
#scope_export
symbols :: (x: []float32, y: []float32, symbol := Symbols.CIRCLE, color := RED, size: float32 = 4.0, symbol_resolution: s32 = 32) -> *Graph_2D_Symbols {
    res := New(Graph_2D_Symbols);
    res.type = Graph_2D_Symbols;
    res.x = x;
    res.y = y;
    res.color = color;
    res.size = size;
    res.symbol = symbol;
    return res;
}
#scope_module
draw :: (using graph: *Graph_2D_Symbols, x_mapper: *Mapper, y_mapper: *Mapper) {
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
bounds_x :: inline (using graph: *Graph_2D_Symbols) -> float32, float32 {
    return min(x), max(x);
}
bounds_y :: inline (using graph: *Graph_2D_Symbols) -> float32, float32 {
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

Graph_2D_Bars :: struct {
    using _s : Graph_2D;
    x: []float32;
    y: []float32;
    color: Color;
    bar_type: BarType;
}
#scope_export
bars :: (x: []float32, y: []float32, color := SKYBLUE, bar_type: BarType = .SIMPLE) -> *Graph_2D_Bars {
    res := New(Graph_2D_Bars);
    res.type = Graph_2D_Bars;
    res.color = color;
    res.bar_type = bar_type;
    res.x = x;
    res.y = y;
    return res;
}
#scope_module
draw :: (using graph: *Graph_2D_Bars, x_mapper: *Mapper, y_mapper: *Mapper) {
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
                DrawRectangleRec(
                    rectangle(
                        min(mx[i], mx[i+1]),
                        min(my[i], zero.y),
                        Math.abs(mx[i]-mx[i+1]),
                        Math.abs(my[i]-zero.y)
                    ), 
                    color
                );
            }
        case .CONNECTED;
            for i: 0..mx.count-2 {
                DrawRectangleRec(
                    rectangle(
                        min(mx[i], mx[i+1]),
                        min(my[i], my[i+1]),
                        Math.abs(mx[i]-mx[i+1]),
                        Math.abs(my[i]-my[i+1])
                    ), 
                    color
                );
            }
    }
}
bounds_x :: inline (using graph: *Graph_2D_Bars) -> float32, float32 {
    return min(x), max(x);
}
bounds_y :: inline (using graph: *Graph_2D_Bars) -> float32, float32 {
    return min(y), max(y);
}







// ########   #######  ##     ##
// ##     ## ##     ##  ##   ##
// ##     ## ##     ##   ## ##
// ########  ##     ##    ###
// ##     ## ##     ##   ## ##
// ##     ## ##     ##  ##   ##
// ########   #######  ##     ##

Graph_2D_Boxes :: struct {
    using _g : Graph_2D;
    x1: []float32;
    x2: []float32;
    y1: []float32;
    y2: []float32;
    color: Color;
}
#scope_export
boxes :: (x1: []float32, y1: []float32, x2: []float32 = .[], y2: []float32 = .[], color := SKYBLUE) -> *Graph_2D_Boxes {
    res := New(Graph_2D_Boxes);
    res.type = Graph_2D_Boxes;
    res.color = color;
    res.x1 = x1;
    res.x2 = x2;
    res.y1 = y1;
    res.y2 = y2;
    return res;
}
#scope_module
draw :: (using graph: *Graph_2D_Boxes, x_mapper: *Mapper, y_mapper: *Mapper) {
    assert(x1.count != 0);
    assert(y1.count != 0);
    assert(x1.count == y1.count);
    if x2.count != 0 then assert(x2.count == x1.count);
    if y2.count != 0 then assert(y2.count == y1.count);

    mx1 := map(x_mapper, x1);
    mx2 := map(x_mapper, x2);
    my1 := map(y_mapper, y1);
    my2 := map(y_mapper, y2);
    defer {
        array_free(mx1);
        array_free(mx2);
        array_free(my1);
        array_free(my2);
    }
    // zero := vec2(map(x_mapper, 0.0), map(y_mapper, 0.0));


    if mx2.count == 0 {
        if my2.count == 0 {
            for i: 0..mx1.count-2 {
                DrawRectangleRec(
                    rectangle(
                        min(mx1[i], mx1[i+1]),
                        min(my1[i], my1[i+1]),
                        Math.abs(mx1[i+1]-mx1[i]),
                        Math.abs(my1[i+1]-my1[i])
                    ), 
                    color
                );
            }
        } else {
            for i: 0..mx1.count-2 {
                DrawRectangleRec(
                    rectangle(
                        min(mx1[i], mx1[i+1]),
                        min(my1[i], my2[i]),
                        Math.abs(mx1[i+1]-mx1[i]),
                        Math.abs(my2[i]-my1[i])
                    ), 
                    color
                );
            }
        }
    } else {
        if my2.count == 0 {
            for i: 0..mx1.count-2 {
                DrawRectangleRec(
                    rectangle(
                        min(mx1[i],mx2[i]),
                        min(my1[i], my1[i+1]),
                        Math.abs(mx2[i]-mx1[i]),
                        Math.abs(my1[i+1]-my1[i])
                    ), 
                    color
                );
            }
        } else {
            for i: 0..mx1.count-1 {
                DrawRectangleRec(
                    rectangle(
                        min(mx1[i],mx2[i]),
                        min(my1[i], my2[i]),
                        Math.abs(mx2[i]-mx1[i]),
                        Math.abs(my2[i]-my1[i])
                    ), 
                    color
                );
            }
        }
    }
}
bounds_x :: inline (using graph: *Graph_2D_Boxes) -> float32, float32 {
    if x2.count == 0 then return min(x1), max(x1);
    return min(min(x1),min(x2)), max(max(x1),max(x2));
}
bounds_y :: inline (using graph: *Graph_2D_Boxes) -> float32, float32 {
    if y2.count == 0 then return min(y1), max(y1);
    return min(min(y1),min(y2)), max(max(y1),max(y2));
}











// ##     ## ##     ## ##       ######## ####
// ###   ### ##     ## ##          ##     ##
// #### #### ##     ## ##          ##     ##
// ## ### ## ##     ## ##          ##     ##
// ##     ## ##     ## ##          ##     ##
// ##     ## ##     ## ##          ##     ##
// ##     ##  #######  ########    ##    ####

#scope_module
Graph_2D_Multi :: struct {
    using _s : Graph_2D;
    graphs2d: []*Graph_2D;
}
#scope_export
multi :: (graphs2d: ..*Graph_2D) -> *Graph_2D_Multi {
    res := New(Graph_2D_Multi);
    res.type = Graph_2D_Multi;
    res.graphs2d = graphs2d;
    return res;
}
#scope_module
draw :: (using graph: *Graph_2D_Multi, x_mapper: *Mapper, y_mapper: *Mapper) {
    for graphs2d {
        draw(it, x_mapper, y_mapper);
    }
}
bounds_x :: (using graph: *Graph_2D_Multi) -> float32, float32 {
    _min := Math.FLOAT32_MAX;
    _max := Math.FLOAT32_MIN;

    for graphs2d {
        mi, ma := bounds_x(it);
        _min = ifx mi < _min then mi else _min;
        _max = ifx ma > _max then ma else _max;
    }

    return _min, _max;
}
bounds_y :: (using graph: *Graph_2D_Multi) -> float32, float32 {
    _min := Math.FLOAT32_MAX;
    _max := Math.FLOAT32_MIN;

    for graphs2d {
        mi, ma := bounds_y(it);
        _min = ifx mi < _min then mi else _min;
        _max = ifx ma > _max then ma else _max;
    }

    return _min, _max;
}

