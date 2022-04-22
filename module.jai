
#scope_module

#import "Windows";
#import "Basic";
Math :: #import "Math";
#import "Thread";
#load "Utils.jai";
#load "jai-raylib.jai";
#load "Events.jai";
#load "Gui.jai";
#load "Mapper_1D.jai";
#load "Mapper_2D.jai";
#load "Graph_2D.jai";
#load "Axis_2D.jai";
#load "Mouse.jai";
#load "Page.jai";


WINDOW_RECT := Rectangle.{0,0,800,600};
_broadcaster : Broadcaster;
_mouse : *MouseState;
_plot : Plot;

_font_initialized : [100]bool;
_font_regular     : [8]Font = ---;


init_fonts :: () {
    if _plot.highdpi {
        _font_regular[0] = LoadFontEx("../fonts/lmroman5-regular.otf" ,  5*2*2, null, 0);
        _font_regular[1] = LoadFontEx("../fonts/lmroman6-regular.otf" ,  6*2*2, null, 0);
        _font_regular[2] = LoadFontEx("../fonts/lmroman7-regular.otf" ,  7*2*2, null, 0);
        _font_regular[3] = LoadFontEx("../fonts/lmroman8-regular.otf" ,  8*2*2, null, 0);
        _font_regular[4] = LoadFontEx("../fonts/lmroman9-regular.otf" ,  9*2*2, null, 0);
        _font_regular[5] = LoadFontEx("../fonts/lmroman10-regular.otf", 10*2*2, null, 0);
        _font_regular[6] = LoadFontEx("../fonts/lmroman12-regular.otf", 12*2*2, null, 0);
        _font_regular[7] = LoadFontEx("../fonts/lmroman17-regular.otf", 17*2*2, null, 0);
    } else {
        _font_regular[0] = LoadFontEx("../fonts/lmroman5-regular.otf" ,  5*2, null, 0);
        _font_regular[1] = LoadFontEx("../fonts/lmroman6-regular.otf" ,  6*2, null, 0);
        _font_regular[2] = LoadFontEx("../fonts/lmroman7-regular.otf" ,  7*2, null, 0);
        _font_regular[3] = LoadFontEx("../fonts/lmroman8-regular.otf" ,  8*2, null, 0);
        _font_regular[4] = LoadFontEx("../fonts/lmroman9-regular.otf" ,  9*2, null, 0);
        _font_regular[5] = LoadFontEx("../fonts/lmroman10-regular.otf", 10*2, null, 0);
        _font_regular[6] = LoadFontEx("../fonts/lmroman12-regular.otf", 12*2, null, 0);
        _font_regular[7] = LoadFontEx("../fonts/lmroman17-regular.otf", 17*2, null, 0);
    }

    for _font_regular {
        SetTextureFilter(it.texture, xx TextureFilter.BILINEAR);
    }
}



measure_text_regular :: inline (msg: string, font_size: int = 12) -> Vector2 {
    assert(font_size >= 0 && font_size < 100);

    for _font_regular {
        if (it.baseSize > 2*font_size && _plot.highdpi) 
        || (it.baseSize > font_size && !_plot.highdpi) 
        || it_index == _font_regular.count-1 {
            return MeasureTextEx(it, msg, cast(float32)font_size, 0.0);
        }
    }
}
draw_text_regular :: inline (msg: string, position: Vector2, font_size: int = 12, color := BLACK) {
    assert(font_size >= 0 && font_size < 100);
    
    for _font_regular {
        if (it.baseSize > 2*font_size && _plot.highdpi) 
        || (it.baseSize > font_size && !_plot.highdpi) 
        || it_index == _font_regular.count-1 {
            DrawTextEx(it, msg, position, cast(float32)font_size, 0.0, color);
            return;
        }
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
    pages: [..]*Page;
    
    active_page: *Page;
    active_page_index: s32;

    active_axis: *Axis_2D;

    running: bool = false;
    callback: () -> ();

    buttons: [..]*Button_Tab;

    highdpi : bool;
}


_empty :: () {}
#scope_export
plot :: (msaa : bool = true, highdpi: bool = false, callback: ()->() = _empty) {
    flags := ConfigFlags.WINDOW_RESIZABLE;
    if highdpi then flags |= ConfigFlags.WINDOW_HIGHDPI;
    if msaa    then flags |= ConfigFlags.MSAA_4X_HINT;
    SetConfigFlags(xx flags);

    _plot.highdpi = highdpi;
    _plot.callback = callback;
    _plot.pages = NewResizableArray(0, *Page);
    _plot.buttons = NewResizableArray(0, *Button_Tab);
    _plot.thread = New(Thread);

    subscribe(_broadcaster, *_plot, on_event);

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

on_event :: (plot: *Plot, event: *Event) {
    if event.type == {
        case Event_Button;
            e := cast(*Event_Button)event;
            if e.button_event_type != .PRESSED then return;
            
            for b, i: _plot.buttons {
                if e.button == b {
                    activate(_plot.pages[i]);
                    broadcast(_broadcaster, event_plot(_plot.active_page));

                    b.active = true;
                    for c, ci: _plot.buttons {
                        if ci == i then continue;
                        c.active = false;
                    }
                }
            }
    }
}

draw_plot :: () {
    top_padding := 5;
    tabs_height := 25.0;
    page_button_pane := rectangle(0, 0, WINDOW_RECT.width, tabs_height+top_padding);
    page_pane := rectangle(0, tabs_height+top_padding, WINDOW_RECT.width, WINDOW_RECT.height-(tabs_height+top_padding));

    if !_plot.active_page then return; // no page to draw

    fit_into_rectangle(*_plot.active_page.page_rectangle, page_pane);
    draw(_plot.active_page);

    DrawLineEx(vec2(0, tabs_height+top_padding), vec2(WINDOW_RECT.width, tabs_height+top_padding), 2.0, GREY);
    for _plot.buttons {
        it.rect = rectangle(it_index * 120 + 10, top_padding, 100, tabs_height);
        draw(it);
    }
}

update_plot :: () {
    if !_plot.active_page then return;
    update(_plot.active_page);
}




read_frame_events :: () {
    // mouse events
    mv := vec2(GetMouseX(),GetMouseY());
    wheel := cast(float32)GetMouseWheelMove();

    broadcast(_broadcaster, event_mouse_position(mv));
    if wheel != 0.0             then broadcast(_broadcaster, event_mouse_wheel(mv, wheel));
    if IsMouseButtonReleased(0) then broadcast(_broadcaster, event_mouse_button(0, mv, .RELEASED));
    if IsMouseButtonPressed( 0) then broadcast(_broadcaster, event_mouse_button(0, mv, .PRESSED ));
    if IsMouseButtonDown(    0) then broadcast(_broadcaster, event_mouse_button(0, mv, .DOWN    ));
    if IsMouseButtonUp(      0) then broadcast(_broadcaster, event_mouse_button(0, mv, .UP      ));
    if IsMouseButtonReleased(1) then broadcast(_broadcaster, event_mouse_button(1, mv, .RELEASED));
    if IsMouseButtonPressed( 1) then broadcast(_broadcaster, event_mouse_button(1, mv, .PRESSED ));
    if IsMouseButtonDown(    1) then broadcast(_broadcaster, event_mouse_button(1, mv, .DOWN    ));
    if IsMouseButtonUp(      1) then broadcast(_broadcaster, event_mouse_button(1, mv, .UP      ));
}



DebugPrinter :: struct {}
_debug_printer : *DebugPrinter;
_debug_print_events :: ($DEBUG: bool = false) {
    _debug_printer := New(DebugPrinter);
    subscribe(_broadcaster, _debug_printer, dprint);

    dprint :: (p: *DebugPrinter, event: *Event) {
        #if DEBUG {
            str_event := str(event);
            defer free(str_event);
            print("event: %\n", str_event);
        }
    }
}




plot_render :: () {
    Window(cast(s32)WINDOW_RECT.width, cast(s32)WINDOW_RECT.height, "Jai Plot");
    SetTargetFPS(60);


    init_fonts();
    // for i:10..48-1 {
    //     // _font_regular = LoadFontEx("../fonts/lmroman12-regular.otf", 12*2*2*2, null, 0);
    //     print("creating font of size %\n", i);
    //     s := ifx _plot.highdpi then 2*i else i;
    //     _font_regular[i] = LoadFontEx("../fonts/lmroman12-regular.otf", cast(s32)s, null, 0);
    //     // _font_regular = LoadFont("../fonts/lmroman12-regular.otf");
    //     // SetTextureFilter(_font_regular[i].texture, xx TextureFilter.BILINEAR);
    // }

    camera := camera2d();
    _mouse = cast(*MouseState)mouse_free();

    _debug_print_events(false);

    _plot.running = true;
    while !WindowShouldClose() {
        WINDOW_RECT.width  = cast(float)GetScreenWidth();
        WINDOW_RECT.height = cast(float)GetScreenHeight();

        // print("---------------------------------------------------\n");
        update_plot();

        read_frame_events();

        Drawing();
        ClearBackground(RAYWHITE);
        Mode2D(camera);

        draw_plot();
        draw(_mouse);
    }

    _plot.callback(); 
}



#scope_export


add_page :: (p: *$P/Page, activate_page : bool = true) {
    array_add(*_plot.pages, cast(*Page)p);
    if activate_page {
        p.activated = true;
        _plot.active_page = cast(*Page)p;
    }

    button_label := ifx p.page_title == "" then sprint("page %", _plot.pages.count) else p.page_title;
    
    b := button_tab(rectangle(0,0,1,1), button_label);
    array_add(*_plot.buttons, b);
    broadcast(_broadcaster, event_button(b, .PRESSED));
}


activate :: (axis: *$A/Axis_2D) {
    _plot.active_axis = cast(*Axis_2D)axis;
}

plot_wait_for_close :: () {
    while !thread_is_done(_plot.thread) {
        sleep_milliseconds(100);
    }
}

