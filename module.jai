
#scope_module

#import "Windows";
#import "Basic";
Math :: #import "Math";
#import "Thread";
#load "Utils.jai";
#load "jai-raylib.jai";


WINDOW_RECT := Rectangle.{0,0,800,600};


fit_into_rectangle :: (r: *Rectangle, rectangle: Rectangle, padding := Vector4.{0.0,0.0,0.0,0.0}) {
    r.x = rectangle.x + padding.x;
    r.y = rectangle.y + padding.y;
    r.width  = rectangle.width  - (padding.x + padding.z);
    r.height = rectangle.height - (padding.y + padding.w);
}



// ########  ########   #######     ###    ########   ######     ###     ######  ######## ######## ########
// ##     ## ##     ## ##     ##   ## ##   ##     ## ##    ##   ## ##   ##    ##    ##    ##       ##     ##
// ##     ## ##     ## ##     ##  ##   ##  ##     ## ##        ##   ##  ##          ##    ##       ##     ##
// ########  ########  ##     ## ##     ## ##     ## ##       ##     ##  ######     ##    ######   ########
// ##     ## ##   ##   ##     ## ######### ##     ## ##       #########       ##    ##    ##       ##   ##
// ##     ## ##    ##  ##     ## ##     ## ##     ## ##    ## ##     ## ##    ##    ##    ##       ##    ##
// ########  ##     ##  #######  ##     ## ########   ######  ##     ##  ######     ##    ######## ##     ##

_broadcaster : Broadcaster;

Broadcaster :: struct {
    subscriptions: [..]Subscription;
    
    Subscription :: struct {
        subscriber: *void;
        callback: (*void, *Event) -> ();
    }
}
subscribe :: (bus: Broadcaster, sub: *$T, callback: (*T, *Event)) {
    subscription := array_add(*bus.subscriptions);
    subscription.subscriber = sub;
    subscription.callback   = cast((*void, *Event)->())callback;
}
unsubscribe :: (bus: Broadcaster, sub: *$T) {
    for bus.subscriptions {
        if it.subscriber == sub {
            remove it;
        }
    }
}
broadcast :: (bus: Broadcaster, event: *Event, consume_event: bool = true) {
    for bus.subscriptions {
        it.callback(it.subscriber, event);
    }
    if consume_event then free(event);
}



// ######## ##     ## ######## ##    ## ########  ######
// ##       ##     ## ##       ###   ##    ##    ##    ##
// ##       ##     ## ##       ####  ##    ##    ##
// ######   ##     ## ######   ## ## ##    ##     ######
// ##        ##   ##  ##       ##  ####    ##          ##
// ##         ## ##   ##       ##   ###    ##    ##    ##
// ########    ###    ######## ##    ##    ##     ######


EventType :: enum u8 {
    MOUSE_POSITION;
    MOUSE_BUTTON;
    AXIS;
    BUTTON;
}

Event :: struct {
    event_type: EventType;
}
is_same_type :: (a: *Event, b: *Event) -> bool {
    if a.event_type != b.event_type then return false;
    if #complete a.event_type == {
        case .MOUSE_POSITION;
            aa := cast(*EventMousePosition)a;
            bb := cast(*EventMousePosition)b;
            return is_same_type(aa,bb);
        case .MOUSE_BUTTON;
            aa := cast(*EventMouseButton)a;
            bb := cast(*EventMouseButton)b;
            return is_same_type(aa,bb);
        case .AXIS;
            aa := cast(*EventAxis)a;
            bb := cast(*EventAxis)b;
            return is_same_type(aa,bb);
        case .BUTTON;
            aa := cast(*EventButton)a;
            bb := cast(*EventButton)b;
            return is_same_type(aa,bb);
    }
}
str :: (event: *Event) -> string {
    if event.event_type == {
        case .MOUSE_POSITION;
            e := cast(*EventMousePosition)event;
            return sprint("%", <<e);
        case .MOUSE_BUTTON;
            e := cast(*EventMouseButton)event;
            return sprint("%", <<e);
        case .AXIS;
            e := cast(*EventAxis)event;
            return sprint("%", <<e);
        case .BUTTON;
            e := cast(*EventButton)event;
            return sprint("%", <<e);
    }
}


// ########  ##     ## ######## ########  #######  ##    ##    ######## ##     ## ######## ##    ## ########  ######
// ##     ## ##     ##    ##       ##    ##     ## ###   ##    ##       ##     ## ##       ###   ##    ##    ##    ##
// ##     ## ##     ##    ##       ##    ##     ## ####  ##    ##       ##     ## ##       ####  ##    ##    ##
// ########  ##     ##    ##       ##    ##     ## ## ## ##    ######   ##     ## ######   ## ## ##    ##     ######
// ##     ## ##     ##    ##       ##    ##     ## ##  ####    ##        ##   ##  ##       ##  ####    ##          ##
// ##     ## ##     ##    ##       ##    ##     ## ##   ###    ##         ## ##   ##       ##   ###    ##    ##    ##
// ########   #######     ##       ##     #######  ##    ##    ########    ###    ######## ##    ##    ##     ######


EventButtonType :: enum u8 {
    PRESSED;
    HOVER;
}

EventButton :: struct {
    using event: Event;
    button_event_type: EventButtonType;
    button: *Button;
}
event_button :: (button: *Button, type: EventButtonType) -> *EventButton {
    res := New(EventButton);
    res.event_type = .BUTTON;
    res.button = button;
    res.button_event_type = type;
    return res;
}
is_same_type :: (a: *EventButton, b: *EventButton) -> bool {
    // if a.button_event_type != b.button_event_type then return false;
    if a.button != b.button then return false;
    return true;
}



//    ###    ##     ## ####  ######     ######## ##     ## ######## ##    ## ########  ######
//   ## ##    ##   ##   ##  ##    ##    ##       ##     ## ##       ###   ##    ##    ##    ##
//  ##   ##    ## ##    ##  ##          ##       ##     ## ##       ####  ##    ##    ##
// ##     ##    ###     ##   ######     ######   ##     ## ######   ## ## ##    ##     ######
// #########   ## ##    ##        ##    ##        ##   ##  ##       ##  ####    ##          ##
// ##     ##  ##   ##   ##  ##    ##    ##         ## ##   ##       ##   ###    ##    ##    ##
// ##     ## ##     ## ####  ######     ########    ###    ######## ##    ##    ##     ######

EventAxisType :: enum u8 {
    MOVE;
    RECT_ZOOM;
}

EventAxis :: struct {
    using event: Event;
    axis_event_type: EventAxisType;
    axis: *Axis;
}
event_axis :: (axis: *Axis, type: EventAxisType) -> *EventAxis {
    res := New(EventAxis);
    res.event_type = .AXIS;
    res.axis_event_type = type;
    res.axis = axis;
    return res;
}
is_same_type :: (a: *EventAxis, b: *EventAxis) -> bool {
    // if a.axis_event_type != b.axis_event_type then return false;
    if a.axis != b.axis then return false;
    return true;
}


// ##     ##  #######  ##     ##  ######  ########    ######## ##     ## ######## ##    ## ########  ######
// ###   ### ##     ## ##     ## ##    ## ##          ##       ##     ## ##       ###   ##    ##    ##    ##
// #### #### ##     ## ##     ## ##       ##          ##       ##     ## ##       ####  ##    ##    ##
// ## ### ## ##     ## ##     ##  ######  ######      ######   ##     ## ######   ## ## ##    ##     ######
// ##     ## ##     ## ##     ##       ## ##          ##        ##   ##  ##       ##  ####    ##          ##
// ##     ## ##     ## ##     ## ##    ## ##          ##         ## ##   ##       ##   ###    ##    ##    ##
// ##     ##  #######   #######   ######  ########    ########    ###    ######## ##    ##    ##     ######

EventMousePosition :: struct {
    using event: Event;
    pos: Vector2;
}
event_mouse_position :: (position: Vector2) -> *EventMousePosition {
    res := New(EventMousePosition);
    res.event_type = .MOUSE_POSITION;
    res.pos = position;
    return res;
}

is_same_type :: inline (a: *EventMousePosition, b: *EventMousePosition) -> bool {
    return true;
}


ButtonEventType :: enum u8 {
    DOWN;
    UP;
    PRESSED;
    RELEASED;
}
EventMouseButton :: struct {
    using event: Event;
    pos: Vector2;
    button: u8;
    button_event_type: ButtonEventType;
}
event_mouse_button :: (button: u8, position: Vector2, button_event_type: ButtonEventType) -> *EventMouseButton {
    res := New(EventMouseButton);

    res.event_type = .MOUSE_BUTTON;

    res.button_event_type = button_event_type;
    res.pos = position;
    res.button = button;

    return res;
}
is_same_type :: inline (a: *EventMouseButton, b: *EventMouseButton) -> bool {
    if a.button != b.button then return false;
    // if a.button_event_type != b.button_event_type then return false;
    return true;
}





//  ######   ##     ## ####
// ##    ##  ##     ##  ##
// ##        ##     ##  ##
// ##   #### ##     ##  ##
// ##    ##  ##     ##  ##
// ##    ##  ##     ##  ##
//  ######    #######  ####



Button :: struct {
    using rect: Rectangle;
    text: string;
    font_size: s32;
    line_color: Color;
    fill_color: Color;

    is_over: bool = false;
    is_pressed: bool = false;
}
button :: (rect: Rectangle, text := "", font_size : s32 = 10, line_color := GREY, fill_color := RAYWHITE) -> *Button {
    res := New(Button);
    res.rect = rect;
    res.text = text;
    res.font_size = font_size;
    res.line_color = line_color;
    res.fill_color = fill_color;
    return res;
}
update :: (using button: *Button, consume_events: bool = true) {
    is_over = false;
    is_pressed = false;

    // print("button: _frame_event_bus: %\n", _frame_event_bus);

    for *_frame_event_bus {
        ev := <<it;
        used := false;
        defer if used && consume_events then remove_event(*_frame_event_bus, ev);

        if ev.event_type == {
            case .MOUSE_POSITION;
                e := cast(*EventMousePosition)ev;
                if CheckCollisionPointRec(e.pos, rect) {
                    // add_event(*_frame_event_bus, event_button(button, .HOVER));
                    is_over = true;
                    used = true;
                }
            case .MOUSE_BUTTON;
                e := cast(*EventMouseButton)ev;
                if CheckCollisionPointRec(e.pos, rect) && e.button_event_type == .PRESSED && e.button == 0 {
                    add_event(*_event_bus, event_button(button, .PRESSED));
                    is_over = true;
                    is_pressed = true;
                    used = true;
                }
        }
    }
    
    // print("button: after _frame_event_bus: %\n", _frame_event_bus);
}
draw :: (using button: *Button) {
    text_width := MeasureText(text, font_size);

    tx := cast(s32)(rect.width  * 0.5 + rect.x - 0.5 * text_width);
    ty := cast(s32)(rect.height * 0.5 + rect.y - 0.5 * font_size );

    if is_over && is_pressed {
        bg := fill_color * 0.5;
        bg.a = 255;
        DrawRectangleRec(rect, bg);
        DrawRectangleLinesEx(rect, 2.0, line_color);
        DrawText(text, tx, ty, font_size, BLACK);
    } else if is_over {
        DrawRectangleRec(rect, fill_color);
        DrawRectangleLinesEx(rect, 2.0, RED);
        DrawText(text, tx, ty, font_size, BLACK);
    } else {
        DrawRectangleRec(rect, fill_color);
        DrawRectangleLinesEx(rect, 2.0, line_color);
        DrawText(text, tx, ty, font_size, BLACK);
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
#scope_export
line :: (color: Color = RED, thickness: float32 = 2.0) -> *Style2D_Line {
    res := New(Style2D_Line);
    res.type = .LINE;
    res.color = color;
    res.thickness = thickness;
    return res;
}
#scope_module






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
#scope_export
symbols :: (symbol := Symbols.CIRCLE, color := RED, size: float32 = 4.0, symbol_resolution: s32 = 32) -> *Style2D_Symbols {
    res := New(Style2D_Symbols);
    res.type = .SYMBOLS;
    res.color = color;
    res.size = size;
    res.symbol = symbol;
    return res;
}
#scope_module








Style2D_Bars :: struct {
    using _s: Style2D;
    color: Color;
}
#scope_export
bars :: (color: Color) -> *Style2D_Bars {
    res := New(Style2D_Bars);
    res.type = .BARS;
    res.color = color;
    return res;
}







#scope_module
Style2D_Multi :: struct {
    using _s: Style2D;
    styles: []*Style2D;
}
#scope_export
multi :: (styles: ..*Style2D) -> *Style2D_Multi {
    res := New(Style2D_Multi);
    res.type = .MULTI;
    res.styles = styles;
    return res;
}
#scope_module





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


// specialize :: (proc_name: string, general: Type, arguments: string, return_type: Type, enum_var_name: string,  specials: ..Type) -> string {
//     builder : String_Builder;

//     print_to_builder(*builder, "% :: (g: *%", proc_name, general);
//     if arguments == "" then append(*builder, ") ") else
//         print_to_builder(*builder, ", %) ", arguments);
//     if return_type != void {
//         print_to_builder(*builder, "-> % ", return_type);
//     }
//     append(*builder, "{\n");

//     print_to_builder(*builder, "    if g.% == {\n");

//     for specials {
//         print_to_builder(*builder, "        case %.%;\n", it, enum_var_name);
//         print_to_builder(*builder, "            s := cast(*%)g;\n", it);

//         ret := ifx return_type == void then "" else " return";

//         print_to_builder(*builder, "           % %(s, %);\n", ret, it, arguments);
//     }

//     append(*builder, "    }\n");
//     append(*builder, "}\n");

//     return builder_to_string(*builder);
// }

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








ticks_linear :: (min_x: float32, max_x: float32, base: float32 = 10.0, exponent_shift: float32 = -log10_of_5) -> [..]float32 {
    range := max_x - min_x;
    dx, exp := round_to_base(range, 10.0, exponent_shift);

    if dx > 0.5 * range then dx /= base;

    res := NewResizableArray(cast(s32)(range/dx), float32);
    x := cast(float32)Math.ceil(min_x/dx) * dx;
    while x < max_x {
        array_add(*res, x);
        x += dx;
    }
    return res;
}

ticks_logarithmic :: (min_x: float32, max_x: float32, $$base: float32=10.0) -> [..]float32 {
    // print("ticks_logarithmic: %, %, %\n", min_x, max_x, base);
    #if is_constant(base) {
        invlogbase :: #run 1.0/Math.log(base);
    } else {
        invlogbase := 1.0/Math.log(base);
    }

    log_min_x := Math.log(min_x)*invlogbase;
    log_max_x := Math.log(max_x)*invlogbase;

    ticks := ticks_linear(log_min_x, log_max_x, base);
    for *ticks {
        <<it = Math.pow(base, <<it);
    }
    return ticks;
}



// ########     ###     ######   ########
// ##     ##   ## ##   ##    ##  ##
// ##     ##  ##   ##  ##        ##
// ########  ##     ## ##   #### ######
// ##        ######### ##    ##  ##
// ##        ##     ## ##    ##  ##
// ##        ##     ##  ######   ########

Page_Type :: enum u8 {
    SINGLE;
}
Page :: struct {
    page_rectangle: Rectangle;
    page_type: Page_Type;
}
update :: (page: *Page, consume_events: bool = true) {
    if page.page_type == {
        case .SINGLE;
            p := cast(*Page_Single)page;
            update(p, consume_events);
    }
}
draw :: (page: *Page) {
    if page.page_type == {
        case .SINGLE;
            p := cast(*Page_Single)page;
            draw(p);
    }
}
intersection_axis :: (page: *Page, pos: Vector2) -> *Axis {
    if page.page_type == {
        case .SINGLE;
            p := cast(*Page_Single)page;
            return cast(*Axis)intersection_axis(p, pos);
    }
}

Page_Single :: struct {
    using _page: Page;
    axis: *Axis;
}
#scope_export
page_single :: (axis: *Axis) -> *Page_Single {
    res := New(Page_Single);
    res.page_type = .SINGLE;
    res.axis = axis;
    return res;
}
#scope_module
update :: (page: *Page_Single, consume_events: bool = true) {
    fit_into_rectangle(page.axis, page.page_rectangle);
    update(page.axis, consume_events=consume_events);
}
draw :: (page: *Page_Single) {
    draw(page.axis);
}
intersection_axis :: inline (using page: *Page_Single, pos: Vector2) -> *Axis {
    return ifx intersection_axis(axis, pos) then axis else null;
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
    axis_rectangle: Rectangle;
    axis_type: Axis_Type;
    datasets: [..]Data2D;
}
intersection_axis :: (ax: *Axis, pos: Vector2) -> bool {
    if ax.axis_type == {
        case .CARTESIAN_2D;
            ca := cast(*CartesianAxis2D)ax;
            return intersection_axis(ca, pos);
    }
}
update :: (ax: *Axis, consume_events: bool = true) {
    if ax.axis_type == {
        case .CARTESIAN_2D;
            ca := cast(*CartesianAxis2D)ax;
            update(ca, consume_events=consume_events);
    }
}
draw :: (ax: *Axis) {
    if ax.axis_type == {
        case .CARTESIAN_2D;
            ca := cast(*CartesianAxis2D)ax;
            draw(ca);
    }
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
fit_into_rectangle :: (ax: *Axis, rectangle: Rectangle) {
    if ax.axis_type == {
        case .CARTESIAN_2D;
            ca := cast(*CartesianAxis2D)ax;
            fit_into_rectangle(ca, rectangle);
    }
}
fit_data :: (ax: *Axis, overwrite_constraints: bool = false) {
    if ax.axis_type == {
        case .CARTESIAN_2D;
            ca := cast(*CartesianAxis2D)ax;
            fit_data(ca, overwrite_constraints);
    }
}
fit_bounds :: (ax: *Axis, gui_rect: Rectangle, overwrite_constraints : bool = false) {
    if ax.axis_type == {
        case .CARTESIAN_2D;
            ca := cast(*CartesianAxis2D)ax;
            fit_bounds(ca, gui_rect, overwrite_constraints);
    }
}
mouse_dragging :: (ax: *Axis) -> *Mouse_State_Dragging {
    if ax.axis_type == {
        case .CARTESIAN_2D;
            ca := cast(*CartesianAxis2D)ax;
            return mouse_dragging(ca);
    }
}
mouse_rmb_dragging :: (ax: *Axis) -> *Mouse_State_RMB_Dragging {
    if ax.axis_type == {
        case .CARTESIAN_2D;
            ca := cast(*CartesianAxis2D)ax;
            return mouse_rmb_dragging(ca);
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





#scope_export
CartesianAxis2D :: struct {
    using _axis: Axis;

    inner_rect : Rectangle;

    original_x_mapper: *Mapper;
    original_y_mapper: *Mapper;

    x_mapper: *Mapper;
    y_mapper: *Mapper;
    flip_y: bool = true;

    button_reset        : *Button;
    button_equal_scaling: *Button;
    button_fit          : *Button;

    title  : string;
    x_label: string;
    y_label: string;

    show_frame: bool = true;
    show_zero_lines: bool = true;
    show_grid: bool = true;
    show_tick_labels_left  : bool = true;
    show_tick_labels_right : bool = true;
    show_tick_labels_top   : bool = true;
    show_tick_labels_bottom: bool = true;
    hide_overflow: bool = true;
    show_gui: bool = true;
    gui_padding: float32 = 50.0;

    axis_padding := Vector4.{70.0, 30.0, 70.0, 50.0}; // left, top, right, bottom

    font_size : s32 = 10;
    tick_length := 5;
    tick_thickness := 2.0;
    y_padding := 8;
    x_padding := 8;
    tick_padding := 5;
}
cartesian_axis_2d :: (x_mapper: *Mapper = null, y_mapper: *Mapper = null, title:="", x_label:="", y_label:="") -> *CartesianAxis2D {
    res := New(CartesianAxis2D);
    res.axis_type = .CARTESIAN_2D;
    res.axis_rectangle = WINDOW_RECT;
    res.datasets  = NewResizableArray(0, Data2D);

    res.button_reset         = button(Rectangle.{}, "reset", res.font_size);
    res.button_equal_scaling = button(Rectangle.{}, "1:1"  , res.font_size);
    res.button_fit           = button(Rectangle.{}, "fit"  , res.font_size);
    
    res.x_mapper = ifx x_mapper then x_mapper else mapper_linear();
    res.y_mapper = ifx y_mapper then y_mapper else mapper_linear();

    res.title   = title;
    res.x_label = x_label;
    res.y_label = y_label;

    res.original_x_mapper = clone(res.x_mapper);
    res.original_y_mapper = clone(res.y_mapper);

    return res;
}
#scope_module
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
intersection_axis :: inline (axis: *CartesianAxis2D, pos: Vector2) -> bool {
    return CheckCollisionPointRec(pos, axis.inner_rect);
}
zoom :: (using axis: *CartesianAxis2D, wheel: float32) {
    using inner_rect;
    
    delta := 0.02 * wheel;

    xmin := map_inv(x_mapper, (_mouse.x - x)          * delta + x        );
    xmax := map_inv(x_mapper, (_mouse.x - (x+width )) * delta + x+width  );
    ymin := map_inv(y_mapper, (_mouse.y - y)          * delta + y        );
    ymax := map_inv(y_mapper, (_mouse.y - (y+height)) * delta + y+height );

    fit_bounds(x_mapper, xmin, xmax, x, x + width , true);
    fit_bounds(y_mapper, ymin, ymax, y, y + height, true);
}
equal_scaling :: (using axis: *CartesianAxis2D) {
    using inner_rect;

    xm := x_mapper;
    ym := y_mapper;
    defer {
        free(xm);
        free(ym);
    }

    dx := map_inv(x_mapper, x +     width ) - map_inv(x_mapper, x);
    dy := map_inv(y_mapper, y +     height) - map_inv(y_mapper, y);
    x0 := map_inv(x_mapper, x + 0.5*width );
    y0 := map_inv(y_mapper, y + 0.5*height);

    xmin, xmax, ymin, ymax : float32;
    if Math.abs(dx) > Math.abs(dy) { // landscape
        xmin = map_inv(x_mapper, x);
        xmax = map_inv(x_mapper, x + width);
        dxdp := (xmax-xmin)/width;
        if flip_y then dxdp = -dxdp;
        ymin = -dxdp*height*0.5 + y0;
        ymax =  dxdp*height*0.5 + y0;
    } else { // portrait
        ymin = map_inv(y_mapper, y);
        ymax = map_inv(y_mapper, y + height);
        dydp := (ymax-ymin)/height;
        xmin = -dydp*width*0.5 + x0;
        xmax =  dydp*width*0.5 + x0;
    }

    x_mapper = mapper_constraint(
        mapper_linear(), 
        xmin, 
        xmax, 
        x, 
        x + width
    );
    y_mapper = mapper_constraint(
        mapper_linear(), 
        ymin, 
        ymax, 
        y         , //ifx flip_y then y          else y + height, 
        y + height  //ifx flip_y then y + height else y
    );
}
fit_into_rectangle :: (using ax: *CartesianAxis2D, r: Rectangle) {
    axis_rectangle = r;

    top_padding := ifx title == "" then 0.0 else 2.0*2.0*font_size;

    inner_rect.x = r.x + axis_padding.x;
    inner_rect.y = r.y + axis_padding.y + top_padding;
    inner_rect.width  = r.width  - (axis_padding.x + axis_padding.z);
    inner_rect.height = r.height - (axis_padding.y + axis_padding.w + top_padding);
}
fit_bounds :: (using ax: *CartesianAxis2D, gui_rect: Rectangle, overwrite_constraints : bool = false) {
    min_x := map_inv(x_mapper, gui_rect.x);
    max_x := map_inv(x_mapper, gui_rect.x+gui_rect.width);
    min_y := map_inv(y_mapper, gui_rect.y);
    max_y := map_inv(y_mapper, gui_rect.y+gui_rect.height);

    using inner_rect;
    fit_bounds(x_mapper, min_x, max_x, x, x+width , overwrite_constraints);
    fit_bounds(y_mapper, min_y, max_y, y, y+height, overwrite_constraints);
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

    using inner_rect;
    fit_bounds(x_mapper, min_x, max_x, x, x+width , overwrite_constraints);
    if !flip_y {
        fit_bounds(y_mapper, min_y, max_y, y, y+height, overwrite_constraints);
    } else {
        fit_bounds(y_mapper, min_y, max_y, y+height, y, overwrite_constraints);
    }
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
mouse_dragging :: (using axis: *CartesianAxis2D) -> *Mouse_State_Dragging {
    using inner_rect;

    res := New(Mouse_State_Dragging);
    res.type = .DRAGGING;
    res.x = GetMouseX();
    res.y = GetMouseY();
    res.axis = axis;

    mx := ifx x_mapper.type == .CONSTRAINT then (cast(*Mapper_Constraint)x_mapper).inner else x_mapper;
    my := ifx y_mapper.type == .CONSTRAINT then (cast(*Mapper_Constraint)y_mapper).inner else y_mapper;
    res.old_x = map_inv(mx, cast(float32)res.x);
    res.old_y = map_inv(my, cast(float32)res.y);

    x_mapper = mapper_constraint(mx, map_inv(mx, x), map_inv(mx, x+width ), x, x+width );
    y_mapper = mapper_constraint(my, map_inv(my, y), map_inv(my, y+height), y, y+height);
    
    return res;
}
mouse_rmb_dragging :: (axis: *CartesianAxis2D) -> *Mouse_State_RMB_Dragging {
    res := New(Mouse_State_RMB_Dragging);
    res.type = .RMB_DRAGGING;
    res.x = GetMouseX();
    res.y = GetMouseY();
    res.axis = axis;
    res.old_x = res.x;
    res.old_y = res.y;
    return res;
}
update :: (ax: *CartesianAxis2D, consume_events: bool = true) {
    fit_data(ax);
    map(ax);

    update(ax.button_reset        );
    update(ax.button_equal_scaling);
    update(ax.button_fit          );

    for *_event_bus {
        ev := <<it;
        used := false;
        defer if used && consume_events then remove_event(*_event_bus, ev);

        if ev.event_type == {
            case .BUTTON;
                e := cast(*EventButton)ev;
                if e.button_event_type != .PRESSED then continue;

                if e.button == ax.button_reset {
                    reset(ax);
                    used = true;
                }
                if e.button == ax.button_equal_scaling {
                    equal_scaling(ax);
                    used = true;
                }
                if e.button == ax.button_fit {
                    fit_data(ax, true);
                    used = true;
                }
        }
    }


    for *_frame_event_bus {
        ev := <<it;
        used := false;
        defer if used && consume_events then remove_event(*_frame_event_bus, ev);

        if ev.event_type == {
            case .MOUSE_BUTTON;
                e := cast(*EventMouseButton)ev;
                if e.button == 0 && e.button_event_type == .PRESSED && CheckCollisionPointRec(e.pos, ax.inner_rect) {
                    add_event(*_event_bus, event_axis(cast(*Axis)ax, .MOVE));
                    used = true;
                }
                if e.button == 1 && e.button_event_type == .PRESSED && CheckCollisionPointRec(e.pos, ax.inner_rect) {
                    add_event(*_event_bus, event_axis(cast(*Axis)ax, .RECT_ZOOM));
                    used = true;
                }
        }
    }
}
draw :: (using ax: *CartesianAxis2D) {
    grid_div := 10.0;
    min_grid_gap_px := 20.0;

    xticks : []float;
    yticks : []float;
    defer array_free(xticks);
    defer array_free(yticks);

    draw_gridlines :: ($x_axis: bool, exponent_shift: float32, color: Color, thickness: float = 1.0) #expand {
        #if x_axis {
            mi := map_inv(x_mapper, inner_rect.x                   );
            ma := map_inv(x_mapper, inner_rect.x + inner_rect.width);
            if mi == ma then return;
            if mi > ma { mi, ma = swap(mi, ma); }

            if get_inner_type(x_mapper) == {
                case .LINEAR;
                    xticks = ticks_linear(mi, ma, 10.0, exponent_shift - log10_of_5 );
                case .LOGARITHMIC;
                    xticks = ticks_logarithmic(mi, ma, 10.0);
            }
        } else {
            mi := map_inv(y_mapper, inner_rect.y                    );
            ma := map_inv(y_mapper, inner_rect.y + inner_rect.height);
            if mi == ma then return;
            if mi > ma { mi, ma = swap(mi, ma); }

            if get_inner_type(y_mapper) == {
                case .LINEAR;
                    yticks = ticks_linear(mi, ma, 10.0, exponent_shift - log10_of_5 );
                case .LOGARITHMIC;
                    yticks = ticks_logarithmic(mi, ma, 10.0);
            }
        }

        #if x_axis {
            ticks := xticks;
        } else {
            ticks := yticks;
        }

        for ticks {
            #if x_axis {
                tx := map(x_mapper, it);
                DrawLineEx(
                    vec2(tx, inner_rect.y                    ), 
                    vec2(tx, inner_rect.y + inner_rect.height), 
                    thickness, 
                    color
                );
            } else {
                ty := map(y_mapper, it);
                DrawLineEx(
                    vec2(inner_rect.x                   , ty), 
                    vec2(inner_rect.x + inner_rect.width, ty), 
                    thickness, 
                    color
                );
            }
        }
    }

    if hide_overflow then BeginScissorMode(cast(s32)inner_rect.x, cast(s32)inner_rect.y, cast(s32)inner_rect.width, cast(s32)inner_rect.height);
    for datasets {
        draw(it);
    }
    if hide_overflow then EndScissorMode();

    // if hide_overflow {
    //     DrawRectangleV(vec2(0.0,0.0), vec2(inner_rect.width, inner_rect.y), RAYWHITE);
    //     DrawRectangleV(vec2(0.0, inner_rect.y+inner_rect.height), vec2(WINDOW_RECT.width, WINDOW_RECT.height), RAYWHITE);
    //     DrawRectangleV(vec2(0.0,0.0), vec2(inner_rect.x, WINDOW_RECT.height), RAYWHITE);
    //     DrawRectangleV(vec2(inner_rect.x+inner_rect.width,0.0), vec2(WINDOW_RECT.width, WINDOW_RECT.height), RAYWHITE);
    // }

    if show_grid {
        draw_gridlines(true , 0.0, Color.{ 130, 130, 130, 125 }, 1.5);
        draw_gridlines(false, 0.0, Color.{ 130, 130, 130, 125 }, 1.5);
    }


    { // tick labels
        using inner_rect;

        if show_tick_labels_top || show_tick_labels_bottom {
            xend : float32 = 0.0;
            first_tick : bool = false;
            for xticks {
                tx := map(x_mapper, it);
                label := sprint("%", formatFloat(it, trailing_width=4, mode=.SHORTEST));
                defer free(label);
                
                text_width := MeasureText(label,font_size);

                if tx + text_width > x+width then break;

                if !first_tick || Math.abs(tx-xend) > cast(float32)tick_padding {
                    if show_tick_labels_bottom {
                        DrawLineEx(vec2(tx, y+height), vec2(tx, y+height+tick_length), tick_thickness, BLACK);
                        DrawText(label,cast(s32)tx,cast(s32)(y+height+y_padding),font_size,BLACK);
                    }
                    if show_tick_labels_top {
                        DrawLineEx(vec2(tx, y-tick_length), vec2(tx, y), tick_thickness, BLACK);
                        DrawText(label,cast(s32)tx,cast(s32)(y-y_padding-font_size),font_size,BLACK);
                    }
                    first_tick = true;
                    xend = tx+text_width;
                }
            }
        }

        if show_tick_labels_left || show_tick_labels_right {
            yend : float32 = 0.0;
            first_tick : bool = false;
            for yticks {
                ty := map(y_mapper, it);
                if ty + font_size > y+height || ty < y then continue;

                label := sprint("%", formatFloat(it, trailing_width=4, mode=.SHORTEST));
                defer free(label);
                
                text_width := MeasureText(label,font_size);

                if !first_tick || Math.abs(ty-yend) > cast(float32)tick_padding {
                    if show_tick_labels_left {
                        DrawLineEx(vec2(x-tick_length, ty), vec2(x, ty), tick_thickness, BLACK);
                        DrawText(label,cast(s32)(x-text_width-x_padding),cast(s32)ty,font_size,BLACK);
                    }
                    if show_tick_labels_right {
                        DrawLineEx(vec2(x+width, ty), vec2(x+width+tick_length, ty), tick_thickness, BLACK);
                        DrawText(label,cast(s32)(x+width+x_padding),cast(s32)ty,font_size,BLACK);
                    }
                    first_tick = true;
                    yend = ty;
                }
            }
        }
    }

    if show_zero_lines {
        using inner_rect;

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
        DrawRectangleLinesEx(inner_rect, 2.0, BLACK);
    }

    if title != "" {
        fs := 2*font_size;
        text_width := MeasureText(title, fs);
        x := inner_rect.x + 0.5*inner_rect.width - text_width*0.5;
        DrawText(title, cast(s32)x, cast(s32)axis_rectangle.y + cast(s32)(0.5*fs), fs, BLACK);
    }

    if show_gui {
        {
            button_height := 20.0;
            button_width  := 50.0;
            button_y := axis_rectangle.y + button_height;

            r := rectangle(inner_rect.x + button_height,button_y,button_width,button_height);
            button_reset.rect = r;
            r.x += button_height + button_width;
            button_equal_scaling.rect = r;
            r.x += button_height + button_width;
            button_fit.rect = r;
        }

        draw(button_reset);
        draw(button_equal_scaling);
        draw(button_fit);
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
    RMB_DRAGGING;
}
Mouse_State :: struct {
    type: Mouse_State_Types = .FREE;
    x: s32 = 0;
    y: s32 = 0;
}

update_mouse :: (consume_events: bool = true) {

    // if IsMouseButtonDown(0) && _mouse.type == .FREE {
    //     print("dragging\n");
    //     // free(_mouse);
    //     v := vec2(cast(float32)GetMouseX(), cast(float32)GetMouseY());
    //     ax := intersection_axis(_plot.active_page, v);
    //     if ax then _mouse = mouse_dragging(ax);
    // } else if !IsMouseButtonDown(0) && _mouse.type == .DRAGGING {
    //     print("stop dragging\n");
    //     md := cast(*Mouse_State_Dragging)_mouse;
    //     _mouse = cast(*Mouse_State)mouse_stop_dragging(md);
    // } else if IsMouseButtonDown(1) && _mouse.type == .FREE {
    //     print("rmb dragging\n");
    //     v := vec2(cast(float32)GetMouseX(), cast(float32)GetMouseY());
    //     ax := intersection_axis(_plot.active_page, v);
    //     if ax then _mouse = mouse_rmb_dragging(ax);
    // } else if !IsMouseButtonDown(1) && _mouse.type == .RMB_DRAGGING {
    //     print("stop rmb dragging\n");
    //     md := cast(*Mouse_State_RMB_Dragging)_mouse;
    //     _mouse = cast(*Mouse_State)mouse_stop_dragging(md);
    // }


    for *_event_bus {
        ev := <<it;
        used := false;
        defer if used && consume_events then remove_event(*_event_bus, ev);

        if ev.event_type == {
            case .AXIS;
                e := cast(*EventAxis)ev;
                if _mouse.type != .FREE then continue;

                if e.axis_event_type == {
                    case .MOVE;
                        tmp := _mouse;
                        _mouse = mouse_dragging(e.axis);
                        free(tmp);
                        used = true;
                    case .RECT_ZOOM;
                        tmp := _mouse;
                        _mouse = mouse_rmb_dragging(e.axis);
                        free(tmp);
                        used = true;
                }
        }
    }


    for *_frame_event_bus {
        ev := <<it;
        used := false;
        defer if used && consume_events then remove_event(*_frame_event_bus, ev);

        if ev.event_type == {
            case .MOUSE_BUTTON;
                e := cast(*EventMouseButton)ev;
                if _mouse.type == .DRAGGING && e.button == 0 && e.button_event_type == .RELEASED {
                    md := cast(*Mouse_State_Dragging)_mouse;
                    _mouse = cast(*Mouse_State)mouse_stop_dragging(md);
                    used = true;
                }
                if _mouse.type == .RMB_DRAGGING && e.button == 1 && e.button_event_type == .RELEASED {
                    md := cast(*Mouse_State_RMB_Dragging)_mouse;
                    _mouse = cast(*Mouse_State)mouse_stop_dragging(md);
                    used = true;
                }
        }
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
        case .RMB_DRAGGING;
            md := cast(*Mouse_State_RMB_Dragging)_mouse;
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
    if wheel == 0.0 then return;

    mv := vec2(cast(float32)x, cast(float32)y);
    ax := intersection_axis(_plot.active_page, mv);
    if ax then zoom(ax, wheel);
}

Mouse_State_Dragging :: struct {
    using mouse_state: Mouse_State;
    old_x: float32 = 0.0;
    old_y: float32 = 0.0;
    axis: *CartesianAxis2D;
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



Mouse_State_RMB_Dragging :: struct {
    using mouse_state: Mouse_State;
    old_x, old_y: s32;
    axis: *CartesianAxis2D;
}
update :: (using mouse: *Mouse_State_RMB_Dragging) {
    x = GetMouseX();
    y = GetMouseY();

    rx, rwidth, ry, rheight: s32;
    if old_x < x {
        rx = old_x;
        rwidth = x-old_x;
    } else {
        rx = x;
        rwidth = old_x-x;
    }
    if old_y < y {
        ry = old_y;
        rheight = y-old_y;
    } else {
        ry = y;
        rheight = old_y-y;
    }

    DrawRectangleLinesEx(rectangle(rx,ry,rwidth,rheight), 2.0, RED);
}
mouse_stop_dragging :: (using mouse: *Mouse_State_RMB_Dragging) -> *Mouse_State_Free {
    m := mouse;
    defer free(m);

    rx, rwidth, ry, rheight: s32;
    if old_x < x {
        rx = old_x;
        rwidth = x-old_x;
    } else {
        rx = x;
        rwidth = old_x-x;
    }
    if old_y < y {
        ry = old_y;
        rheight = y-old_y;
    } else {
        ry = y;
        rheight = old_y-y;
    }

    fit_bounds(axis, rectangle(rx,ry,rwidth,rheight), true);

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
    pages: [..]*Page;
    
    active_page: *Page;
    active_page_index: s32;

    active_axis: *Axis;

    running: bool = false;
    callback: () -> ();

    buttons: [..]*Button;
}

_plot : Plot;

_empty :: () {}
#scope_export
plot :: (msaa : bool = true, highdpi: bool = false, callback: ()->() = _empty) {
    flags := ConfigFlags.WINDOW_RESIZABLE;
    if highdpi then flags |= ConfigFlags.WINDOW_HIGHDPI;
    if msaa    then flags |= ConfigFlags.MSAA_4X_HINT;
    SetConfigFlags(xx flags);

    _plot.callback = callback;
    _plot.pages = NewResizableArray(0, *Page);
    _plot.buttons = NewResizableArray(0, *Button);
    _plot.thread = New(Thread);

    render_thread :: (_thread: *Thread = null) -> s64 {
        plot_render();
        return 0;
    }

    thread_init(_plot.thread, render_thread);
    thread_start(_plot.thread);

    while !_plot.running {
        sleep_milliseconds(10);
    }
}
#scope_module





update_plot :: () {
    for _plot.buttons {
        update(it);
    }

    if _plot.active_page {
        update(_plot.active_page);
    }

    for *_event_bus {
        ev := <<it;
        used := false;
        defer if used then remove_event(*_event_bus, ev);

        if ev.event_type == {
            case .BUTTON;
                e := cast(*EventButton)ev;
                for b, i: _plot.buttons {
                    if e.button == b {
                        _plot.active_page = _plot.pages[i];
                        used = true;
                    }
                }
        }
    }
}

draw_plot :: () {
    button_pane_width := 50.0;
    page_button_pane := rectangle(0,0,button_pane_width,WINDOW_RECT.height);
    page_pane := rectangle(button_pane_width,0,WINDOW_RECT.width-button_pane_width,WINDOW_RECT.height);

    if !_plot.active_page then return; // no page to draw

    // button_rect := rectangle(10.0,15.0,30.0,20.0);

    fit_into_rectangle(*_plot.active_page.page_rectangle, page_pane);
    draw(_plot.active_page);

    for _plot.buttons {
        if it_index == _plot.active_page_index {
            it.line_color = RED;
        } else {
            it.line_color = GREY;
        }
        draw(it);
    }

    // for _plot.pages {
    //     text := sprint("%", it_index);
    //     defer free(text);

    //     color := ifx _plot.active_page == it then RED else GREY;


    //     // if gui_button(button_rect, text, 10, line_color=color, consume_events=true) {
    //     //     _plot.active_page = it;
    //     // }
    //     // button_rect.y += 20.0 + 20.0;
    // }
}




read_events :: (bus: *EventBus) {
    // mouse events
    mv := vec2(GetMouseX(),GetMouseY());
    add_event(bus, event_mouse_position(mv));
    if IsMouseButtonPressed( 0) then add_event(bus, event_mouse_button(0, mv, .PRESSED ), false);
    if IsMouseButtonDown(    0) then add_event(bus, event_mouse_button(0, mv, .DOWN    ), false);
    if IsMouseButtonUp(      0) then add_event(bus, event_mouse_button(0, mv, .UP      ), false);
    if IsMouseButtonReleased(0) then add_event(bus, event_mouse_button(0, mv, .RELEASED), false);
    if IsMouseButtonPressed( 1) then add_event(bus, event_mouse_button(1, mv, .PRESSED ), false);
    if IsMouseButtonDown(    1) then add_event(bus, event_mouse_button(1, mv, .DOWN    ), false);
    if IsMouseButtonUp(      1) then add_event(bus, event_mouse_button(1, mv, .UP      ), false);
    if IsMouseButtonReleased(1) then add_event(bus, event_mouse_button(1, mv, .RELEASED), false);
}


_debug_print_events :: ($DEBUG: bool = false) {
    #if DEBUG {
        print("_event_bus       ////////////////////////////////\n");
        for _event_bus {
            if it.event_type == {
                case .MOUSE_BUTTON;
                    e := cast(*EventMouseButton)it;
                    print("event % : %\n", it_index, <<e);
                case .MOUSE_POSITION;
                    e := cast(*EventMousePosition)it;
                    print("event % : %\n", it_index, <<e);
                case .AXIS;
                    e := cast(*EventAxis)it;
                    print("event % : %\n", it_index, <<e);
            }
        }
        print("_frame_event_bus ////////////////////////////////\n");
        for _frame_event_bus {
            if it.event_type == {
                case .MOUSE_BUTTON;
                    e := cast(*EventMouseButton)it;
                    print("event % : %\n", it_index, <<e);
                case .MOUSE_POSITION;
                    e := cast(*EventMousePosition)it;
                    print("event % : %\n", it_index, <<e);
                case .AXIS;
                    e := cast(*EventAxis)it;
                    print("event % : %\n", it_index, <<e);
            }
        }
    }
}




plot_render :: () {
    Window(cast(s32)WINDOW_RECT.width, cast(s32)WINDOW_RECT.height, "Jai Plot");
    SetTargetFPS(60);

    init_symbol_texture();
    camera := camera2d();
    _mouse = cast(*Mouse_State)mouse_free();
    _event_bus = event_bus();
    _frame_event_bus = event_bus();

    _plot.running = true;

    while !WindowShouldClose() {
        WINDOW_RECT.width  = cast(float)GetScreenWidth();
        WINDOW_RECT.height = cast(float)GetScreenHeight();

        // reset_event_bus(_event_bus);
        reset_event_bus(*_frame_event_bus);
        print("---------------------------------------------------\n");
        read_events(*_frame_event_bus);
        // _debug_print_events(true);

        update_mouse();
        update_plot();

        Drawing();
        ClearBackground(RAYWHITE);
        Mode2D(camera);

        draw_plot();

    }

    _plot.callback(); 
}
#scope_export
add_page :: (p: *$P/Page) {
    array_add(*_plot.pages, cast(*Page)p);
    _plot.active_page = cast(*Page)p;
}

activate :: (axis: *$A/Axis) {
    _plot.active_axis = cast(*Axis)axis;
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

