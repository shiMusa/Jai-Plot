

// ########  ##     ## ######## ########  #######  ##    ##
// ##     ## ##     ##    ##       ##    ##     ## ###   ##
// ##     ## ##     ##    ##       ##    ##     ## ####  ##
// ########  ##     ##    ##       ##    ##     ## ## ## ##
// ##     ## ##     ##    ##       ##    ##     ## ##  ####
// ##     ## ##     ##    ##       ##    ##     ## ##   ###
// ########   #######     ##       ##     #######  ##    ##


Button_Types :: Type.[
    Button_Framed,
    Button_Tab
];

Button :: struct {
    using rect: Rectangle;
    type: Type;
}
is_over :: inline (button: *Button, position: Vector2) -> bool {
    return CheckCollisionPointRec(position, button.rect);
}
draw :: (b: *Button) {
    #insert #run specialize(Button_Types, "draw");
}



// ########  ##     ## ######## ########  #######  ##    ## ######## ########     ###    ##     ## ######## ########
// ##     ## ##     ##    ##       ##    ##     ## ###   ## ##       ##     ##   ## ##   ###   ### ##       ##     ##
// ##     ## ##     ##    ##       ##    ##     ## ####  ## ##       ##     ##  ##   ##  #### #### ##       ##     ##
// ########  ##     ##    ##       ##    ##     ## ## ## ## ######   ########  ##     ## ## ### ## ######   ##     ##
// ##     ## ##     ##    ##       ##    ##     ## ##  #### ##       ##   ##   ######### ##     ## ##       ##     ##
// ##     ## ##     ##    ##       ##    ##     ## ##   ### ##       ##    ##  ##     ## ##     ## ##       ##     ##
// ########   #######     ##       ##     #######  ##    ## ##       ##     ## ##     ## ##     ## ######## ########


Button_Framed :: struct {
    using button: Button;
    text: string;
    font_size: s32;
    line_color: Color;
    fill_color: Color;

    is_over: bool = false;
    is_pressed: bool = false;
}
button_framed :: (rect: Rectangle, text := "", font_size : s32 = 12, line_color := GREY, fill_color := RAYWHITE) -> *Button_Framed {
    res := New(Button_Framed);
    res.type = Button_Framed;
    res.rect = rect;
    res.text = text;
    res.font_size = font_size;
    res.line_color = line_color;
    res.fill_color = fill_color;

    subscribe(_broadcaster, res, on_event);

    return res;
}
on_event :: (button: *Button_Framed, event: *Event) {
    if event.type == {
        case Event_Mouse_Position;
            e := cast(*Event_Mouse_Position)event;
            if is_over(button, e.position) {
                broadcast(_broadcaster, event_button(button, .HOVER));
                button.is_over = true;
            } else {
                button.is_over = false;
            }
        case Event_Mouse_Button;
            e := cast(*Event_Mouse_Button)event;
            if is_over(button, e.position) {
                if e.button_event_type == .PRESSED && e.button == 0 {
                    broadcast(_broadcaster, event_button(button, .PRESSED));
                    button.is_pressed = true;
                }
                if e.button_event_type == .RELEASED && e.button == 0 {
                    button.is_pressed = false;
                }
            }
    }
}
draw :: (using button_framed: *Button_Framed) {
    // text_width := MeasureText(text, font_size);
    text_width := measure_text_regular(text, font_size).x;

    tx := cast(s32)(rect.width  * 0.5 + rect.x - 0.5 * text_width);
    ty := cast(s32)(rect.height * 0.5 + rect.y - 0.5 * font_size );

    if is_over && is_pressed {
        bg := fill_color * 0.5;
        bg.a = 255;
        DrawRectangleRec(rect, bg);
        DrawRectangleLinesEx(rect, 2.0, line_color);
        draw_text_regular(text, vec2(tx,ty), font_size, BLACK);
        // DrawText(text, tx, ty, font_size, BLACK);
    } else if is_over {
        DrawRectangleRec(rect, fill_color);
        DrawRectangleLinesEx(rect, 2.0, RED);
        draw_text_regular(text, vec2(tx,ty), font_size, BLACK);
        // DrawText(text, tx, ty, font_size, BLACK);
    } else {
        DrawRectangleRec(rect, fill_color);
        DrawRectangleLinesEx(rect, 2.0, line_color);
        draw_text_regular(text, vec2(tx,ty), font_size, BLACK);
        // DrawText(text, tx, ty, font_size, BLACK);
    }
}





// ########  ##     ## ######## ########  #######  ##    ## ########    ###     ######
// ##     ## ##     ##    ##       ##    ##     ## ###   ##    ##      ## ##   ##    ##
// ##     ## ##     ##    ##       ##    ##     ## ####  ##    ##     ##   ##  ##
// ########  ##     ##    ##       ##    ##     ## ## ## ##    ##    ##     ## ##   ####
// ##     ## ##     ##    ##       ##    ##     ## ##  ####    ##    ######### ##    ##
// ##     ## ##     ##    ##       ##    ##     ## ##   ###    ##    ##     ## ##    ##
// ########   #######     ##       ##     #######  ##    ##    ##    ##     ##  ######

Button_Tab :: struct {
    using button: Button;
    text: string;
    font_size: s32;
    line_color: Color;
    fill_color: Color;

    active: bool;

    is_over: bool = false;
    is_pressed: bool = false;
}
button_tab :: (rect: Rectangle, text := "", font_size : s32 = 10, line_color := GREY, fill_color := RAYWHITE) -> *Button_Tab {
    res := New(Button_Tab);
    res.type = Button_Tab;
    res.rect = rect;
    res.text = text;
    res.font_size = font_size;
    res.line_color = line_color;
    res.fill_color = fill_color;
    res.active = false;

    subscribe(_broadcaster, res, on_event);    

    return res;
}
on_event :: (button: *Button_Tab, event: *Event) {
    if event.type == {
        case Event_Mouse_Position;
            e := cast(*Event_Mouse_Position)event;
            if is_over(button, e.position) {
                broadcast(_broadcaster, event_button(button, .HOVER));
                button.is_over = true;
            } else {
                button.is_over = false;
            }
        case Event_Mouse_Button;
            e := cast(*Event_Mouse_Button)event;
            if is_over(button, e.position) {
                if e.button_event_type == .PRESSED && e.button == 0 {
                    broadcast(_broadcaster, event_button(button, .PRESSED));
                    button.is_pressed = true;
                }
                if e.button_event_type == .RELEASED && e.button == 0 {
                    button.is_pressed = false;
                }
            }
    }
}
draw :: (using button_framed: *Button_Tab) {
    text_width := MeasureText(text, font_size);

    tx := cast(s32)(rect.width  * 0.5 + rect.x - 0.5 * text_width);
    ty := cast(s32)(rect.height * 0.5 + rect.y - 0.5 * font_size );

    fc := fill_color;
    if !active {
        fc *= 0.75;
        fc.a = 255;
    }
    lc := line_color;
    if is_over {
        lc = RED;
    }

    if !active {
        DrawRectangleRec(rect, fc);
    } else {
        r := rect;
        r.height += 2;
        DrawRectangleRec(r, fc);
    }
    
    if is_pressed {
        _fc := fill_color;
        _fc *= 0.5;
        _fc.a = 255;
        DrawRectangleRec(rect, _fc);
    }
    
    DrawText(text, tx, ty, font_size, BLACK);
    DrawLineEx(vec2(rect.x           ,rect.y), vec2(rect.x+rect.width, rect.y            ), 2.0, lc);
    DrawLineEx(vec2(rect.x           ,rect.y), vec2(rect.x           , rect.y+rect.height), 2.0, lc);
    DrawLineEx(vec2(rect.x+rect.width,rect.y), vec2(rect.x+rect.width, rect.y+rect.height), 2.0, lc);
    if !active {
        DrawLineEx(vec2(rect.x,rect.y+height), vec2(rect.x+rect.width, rect.y+rect.height), 2.0, line_color);
    }
}

