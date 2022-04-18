

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
    Graph_2D_Multi,
    Graph_2D_Error,
    Graph_2D_HeatMap
];

Graph_2D :: struct {
    type: Type;
}

draw :: (b: *Graph_2D, mapper: *Mapper_2D) {
    #insert #run specialize(Graph_2D_Types, "draw", .["mapper"]);
}
update :: (b: *Graph_2D, mapper: *Mapper_2D) {
    #insert #run specialize(Graph_2D_Types, "update", .["mapper"]);
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
draw :: (using graph: *Graph_2D_Line, mapper: *Mapper_2D) {
    m := NewArray(x.count, Vector2, false);
    defer array_free(m);

    for i:0..x.count-1 {
        m[i] = map(mapper, vec2(x[i], y[i]));
    }

    DrawLines(m, color, thickness);
}
update :: inline (using graph: *Graph_2D_Line, mapper: *Mapper_2D) {}
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
}
#scope_export
fill :: (x: []float32, y1: []float32, y2: []float32 = .[], color: Color = RED) -> *Graph_2D_Fill {
    res := New(Graph_2D_Fill);
    res.type = Graph_2D_Fill;
    res.x = x;
    res.y1 = y1;
    if y2.count == 0 {
        res.y2 = NewArray(y1.count, float32);
    } else {
        res.y2 = y2;
    }
    res.color = color;
    return res;
}
#scope_module
draw :: (using graph: *Graph_2D_Fill, mapper: *Mapper_2D) {

    m1 := map(mapper, x, y1);
    m2 := map(mapper, x, y2);
    defer {
        array_free(m1);
        array_free(m2);
    }

    zero := map(mapper, vec2());

    // create 1.1 * necessary points to account for probable zero-crossings
    N := x.count;
    pts := NewResizableArray(cast(s32)(1.1*N*2), Vector2, false);
    defer array_free(pts);

    for i: 0..N-1 {

        if i != N-1 {
            if (y2[i+1]-y1[i+1])*(y2[i]-y1[i]) < 0.0 {

                // a1*x+b1 = a2*x+b2
                // => (a1-a2)*x = b2-b1
                // => x = (b2-b1)/(a1-a2)
                a1 := (y1[i+1]-y1[i])/(x[i+1]-x[i]);
                a2 := (y2[i+1]-y2[i])/(x[i+1]-x[i]);
                _x := (y2[i]-y1[i])/(a1-a2);
                _y := y1[i] + _x * a1;

                extra := map(mapper, vec2(_x+x[i], _y));

                array_add(*pts,
                    vec2(m1[i].x, min(m1[i].y, m2[i].y)),
                    vec2(m1[i].x, max(m1[i].y, m2[i].y)),
                    extra,
                    extra
                );

            } else {
                array_add(*pts,
                    vec2(m1[i].x, min(m1[i].y, m2[i].y)),
                    vec2(m1[i].x, max(m1[i].y, m2[i].y)) 
                );
            }
        } else {
            array_add(*pts,
                vec2(m1[i].x, min(m1[i].y, m2[i].y)),
                vec2(m1[i].x, max(m1[i].y, m2[i].y)) 
            );
        }
    }

    DrawTriangleStrip(pts, color);
}
update :: inline (using graph: *Graph_2D_Fill, mapper: *Mapper_2D) {}
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
symbols_initialized := false;

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
draw :: (using graph: *Graph_2D_Symbols, mapper: *Mapper_2D) {
    m := map(mapper, x, y);
    defer array_free(m);

    tex := symbol_render_textures[symbol].texture;
    s := vec2(size,size);
    for i: 0..x.count-1 {
        DrawTextureEx(tex, m[i] - s, 0.0, size/(0.5*SYMBOL_SIZE), color);
    }
}
update :: (using graph: *Graph_2D_Symbols, mapper: *Mapper_2D) {
    if symbols_initialized then return;

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
    symbols_initialized = true;
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
draw :: (using graph: *Graph_2D_Bars, mapper: *Mapper_2D) {
    m := map(mapper, x, y);
    defer array_free(m);
    zero := map(mapper, vec2());

    if bar_type == {
        case .SIMPLE;
            for i: 0..m.count-2 {
                DrawRectangleRec(
                    rectangle(
                        min(m[i].x, m[i+1].x),
                        min(m[i].y, zero.y),
                        Math.abs(m[i].x-m[i+1].x),
                        Math.abs(m[i].y-zero.y)
                    ), 
                    color
                );
            }
        case .CONNECTED;
            for i: 0..m.count-2 {
                DrawRectangleRec(
                    rectangle(
                        min(m[i].x, m[i+1].x),
                        min(m[i].y, m[i+1].y),
                        Math.abs(m[i].x-m[i+1].x),
                        Math.abs(m[i].y-m[i+1].y)
                    ), 
                    color
                );
            }
    }
}
update :: inline (using graph: *Graph_2D_Bars, mapper: *Mapper_2D) {}
bounds_x :: inline (using graph: *Graph_2D_Bars) -> float32, float32 {
    return min(x), max(x);
}
bounds_y :: inline (using graph: *Graph_2D_Bars) -> float32, float32 {
    return min(y), max(y);
}




// ######## ########  ########   #######  ########
// ##       ##     ## ##     ## ##     ## ##     ##
// ##       ##     ## ##     ## ##     ## ##     ##
// ######   ########  ########  ##     ## ########
// ##       ##   ##   ##   ##   ##     ## ##   ##
// ##       ##    ##  ##    ##  ##     ## ##    ##
// ######## ##     ## ##     ##  #######  ##     ##

Graph_2D_Error :: struct {
    using _g : Graph_2D;
    val: []float32;
    low: []float32;
    high: []float32;
    y_error : bool;
    color: Color;
    thickness: float32;
    size: float32;
}
#scope_export
error_bars :: (val: []float32, low: []float32, high: []float32, y_error := true, thickness: float32 = 1.0, size: float32 = 10.0, color := RED) -> *Graph_2D_Error {
    assert(val.count ==  low.count);
    assert(val.count == high.count);
    res := New(Graph_2D_Error);
    res.type = Graph_2D_Error;
    res.val = val;
    res.low = low;
    res.high = high;
    res.y_error = y_error;
    res.thickness = thickness;
    res.color = color;
    res.size = size;
    return res;
}
#scope_module
draw :: (using graph: *Graph_2D_Error, mapper: *Mapper_2D) {

    mlow  := map(mapper, val, low);
    mhigh := map(mapper, val, high);

    defer {
        array_free(mlow );
        array_free(mhigh);
    }

    if y_error {
        shift := vec2(0.5*size, 0.0);
        for i: 0..val.count-1 {
            DrawLineEx(mhigh[i], mlow[i], thickness, color);
            DrawLineEx(mhigh[i] - shift, mhigh[i] + shift, thickness, color);
            DrawLineEx(mlow[i]  - shift, mlow[i]  + shift, thickness, color);
        }
    } else {
        shift := vec2(0.5*size, 0.0);
        // shift := vec2(0.0, 0.5*size);
        for i: 0..val.count-1 {
            DrawLineEx(yx(mhigh[i]), yx(mlow[i]), thickness, color);
            DrawLineEx(yx(mhigh[i] - shift), yx(mhigh[i] + shift), thickness, color);
            DrawLineEx(yx(mlow[i]  - shift), yx(mlow[i]  + shift), thickness, color);
        }
    }
}
update :: inline (using graph: *Graph_2D_Error, mapper: *Mapper_2D) {}
bounds_x :: inline (using graph: *Graph_2D_Error) -> float32, float32 {
    if y_error {
        return min(val), max(val);
    } else {
        return min(low), max(high);
    }
}
bounds_y :: inline (using graph: *Graph_2D_Error) -> float32, float32 {
    if !y_error {
        return min(val), max(val);
    } else {
        return min(low), max(high);
    }
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
    
    assert(x1.count == y1.count);
    if x2.count != 0 then assert(x2.count == x1.count);
    if y2.count != 0 then assert(y2.count == y1.count);

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
draw :: (using graph: *Graph_2D_Boxes, mapper: *Mapper_2D) {
    assert(x1.count != 0);
    assert(y1.count != 0);
    assert(x1.count == y1.count);
    if x2.count != 0 then assert(x2.count == x1.count);
    if y2.count != 0 then assert(y2.count == y1.count);

    N := x1.count;
    tl := TempNewArray(N, Vector2, false);
    tr := TempNewArray(N, Vector2, false);
    bl := TempNewArray(N, Vector2, false);
    br := TempNewArray(N, Vector2, false);

    subone := 0;

    if x2.count == 0 {
        subone = 1;
        if y2.count == 0 {

        } else {

        }
    } else {
        if y2.count == 0 {

        } else {
            for i:0..N-1 {
                if x1[i] <= x2[i] {
                    tl[i].x = x1[i];
                    bl[i].x = x1[i];
                    tr[i].x = x2[i];
                    br[i].x = x2[i];
                }
                if y1[i] <= y2[i] {
                    tl[i].y = y1[i];
                    tr[i].y = y1[i];
                    bl[i].y = y2[i];
                    br[i].y = y2[i];
                }
            }
        }
    }

    
    map(mapper, *tl);
    map(mapper, *tr);
    map(mapper, *bl);
    map(mapper, *br);

    box := TempNewArray(4, Vector2, false);
    for i:0..N-1-subone {
        box[0] = tl[i];
        box[1] = bl[i];
        box[2] = tr[i];
        box[3] = br[i];
        DrawTriangleStrip(box, color);
    }

}
update :: inline (using graph: *Graph_2D_Boxes, mapper: *Mapper_2D) {}
bounds_x :: inline (using graph: *Graph_2D_Boxes) -> float32, float32 {
    if x2.count == 0 then return min(x1), max(x1);
    return min(min(x1),min(x2)), max(max(x1),max(x2));
}
bounds_y :: inline (using graph: *Graph_2D_Boxes) -> float32, float32 {
    if y2.count == 0 then return min(y1), max(y1);
    return min(min(y1),min(y2)), max(max(y1),max(y2));
}




// ##     ## ########    ###    ########
// ##     ## ##         ## ##      ##
// ##     ## ##        ##   ##     ##
// ######### ######   ##     ##    ##
// ##     ## ##       #########    ##
// ##     ## ##       ##     ##    ##
// ##     ## ######## ##     ##    ##

#scope_export
Gradient :: struct {
    values : []float32;
    colors : []Color;
    interp: GradientInterpolation;
}


GradientInterpolation :: enum u8 {
    LINEAR;
}

GRADIENT_GREYSCALE      :: Gradient.{float32.[0.0,1.0]    , Color.[BLACK, RAYWHITE]                         , .LINEAR};
GRADIENT_BLUE_GREYSCALE :: Gradient.{float32.[0.0,0.5,1.0], Color.[BLACK, Color.{110,125,140,255}, RAYWHITE], .LINEAR};
GRADIENT_BLUE_RED       :: Gradient.{float32.[0.0,0.5,1.0], Color.[BLUE, RAYWHITE, RED]                     , .LINEAR};


gradient_greyscale :: (min: float32, max: float32, interpolation := GradientInterpolation.LINEAR) -> Gradient {
    res := GRADIENT_GREYSCALE;
    res.values[0] = min;
    res.values[1] = 0.5*(min+max);
    res.values[2] = max;
    return res;
}
gradient_blue_greyscale :: (min: float32, max: float32, interpolation := GradientInterpolation.LINEAR) -> Gradient {
    res := GRADIENT_BLUE_GREYSCALE;
    res.values[0] = min;
    res.values[1] = 0.5*(min+max);
    res.values[2] = max;
    return res;
}
gradient_blue_red :: (min: float32, max: float32, interpolation := GradientInterpolation.LINEAR) -> Gradient {
    res := GRADIENT_BLUE_RED;
    res.values[0] = min;
    res.values[1] = 0.5*(min+max);
    res.values[2] = max;
    return res;
}


gradient :: (values: []float32, colors: []Color, interpolation := GradientInterpolation.LINEAR) -> Gradient {
    assert(values.count == colors.count);
    for i: 0..values.count-2 {
        assert(values[i] < values[i+1]);
    }

    res : Gradient = ---;
    res.values = values;
    res.colors = colors;
    res.interp = interpolation;
    return res;
}
#scope_module
value_to_color :: (using gradient: Gradient, value: float32) -> Color {
    N := values.count;
    if #complete interp == {
        case .LINEAR;
            if value <= values[0]   then return colors[0]  ;
            if value >= values[N-1] then return colors[N-1];
            for i: 1..N-1 {
                if value >= values[i] then continue;
                // here, values[i-1] < value < values[i]
                t := (value-values[i-1])/(values[i]-values[i-1]);
                return (1-t) * colors[i-1] + t * colors[i]; // linear rgb interpolation
            }
    }
}



Graph_2D_HeatMap :: struct {
    using _g: Graph_2D;
    rect: Rectangle;
    width: int;
    height: int;
    values: []float32;
    gradient: Gradient;
    texture: RenderTexture2D;
    texture_initialized := false;
}
#scope_export
heatmap :: (rect: Rectangle, width: int, height: int, values: []float32, gradient: Gradient) -> *Graph_2D_HeatMap {
    assert(values.count == width*height);
    res := New(Graph_2D_HeatMap);
    res.type = Graph_2D_HeatMap;
    res.rect = rect;
    res.width = width;
    res.height = height;
    res.values = values;
    res.gradient = gradient;
    return res;
}
#scope_module
draw :: (using graph: *Graph_2D_HeatMap, mapper: *Mapper_2D) {
    if values.count != width*height {
        DrawRectangleRec(rect, PURPLE);
    }

    tl := map(mapper, top_left(rect));
    size := map(mapper, bottom_right(rect)) - tl;

    DrawTexturePro(texture.texture, rectangle(0,0,width,height), rectangle(tl.x,tl.y,size.x,-size.y), vec2(), 0.0, WHITE);
}
update :: inline (using graph: *Graph_2D_HeatMap, mapper: *Mapper_2D) {
    if !texture_initialized {
        texture = LoadRenderTexture(cast(s32)width, cast(s32)height);
        texture_initialized = true;
    }

    TextureMode(texture, #code {
        if values.count != width*height {
            ClearBackground(PURPLE);
        } else {
            ClearBackground(RAYWHITE);
            for x: 0..width-1 {
                for y: 0..height-1 {
                    DrawPixel(cast(s32)x, cast(s32)y, value_to_color(gradient, values[x + width*y]));
                }
            }
        }
    });
}
bounds_x :: inline (using graph: *Graph_2D_HeatMap) -> float32, float32 {
    return rect.x, rect.x+rect.width;
}
bounds_y :: inline (using graph: *Graph_2D_HeatMap) -> float32, float32 {
    return rect.y, rect.y+rect.height;
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
draw :: (using graph: *Graph_2D_Multi, mapper: *Mapper_2D) {
    for graphs2d {
        draw(it, mapper);
    }
}
update :: inline (using graph: *Graph_2D_Multi, mapper: *Mapper_2D) {
    for graphs2d {
        update(it, mapper);
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

