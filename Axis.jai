


//    ###    ##     ## ####  ######
//   ## ##    ##   ##   ##  ##    ##
//  ##   ##    ## ##    ##  ##
// ##     ##    ###     ##   ######
// #########   ## ##    ##        ##
// ##     ##  ##   ##   ##  ##    ##
// ##     ## ##     ## ####  ######


Axis_Types :: Type.[
    Axis_2D_Cartesian
];

Axis :: struct {
    axis_rectangle: Rectangle;
    type: Type;
    graphs2d: [..]*Graph_2D;
    activated: bool;
}


#scope_export
plot2d :: (graph2d: *Graph_2D) {
    array_add(*_plot.active_axis.graphs2d, graph2d);
}
plot2d :: (ax: *Axis, graph2d: *Graph_2D) {
    array_add(*ax.graphs2d, graph2d);
}
#scope_module




intersection_axis :: (b: *Axis, pos: Vector2) -> bool {
    #insert #run specialize(Axis_Types, "intersection_axis", .["pos"], 1);
}
draw :: (b: *Axis) {
    #insert #run specialize(Axis_Types, "draw");
}
reset :: (b: *Axis) {
    #insert #run specialize(Axis_Types, "reset");
}
zoom :: (b: *Axis, position: Vector2, wheel: float32) {
    #insert #run specialize(Axis_Types, "zoom", .["position", "wheel"]);
}
fit_into_rectangle :: (b: *Axis, rectangle: Rectangle) {
    #insert #run specialize(Axis_Types, "fit_into_rectangle", .["rectangle"]);
}
fit_data :: (b: *Axis, overwrite_constraints: bool = false) {
    #insert #run specialize(Axis_Types, "fit_data", .["overwrite_constraints"]);
}
fit_bounds :: (b: *Axis, gui_rect: Rectangle, overwrite_constraints : bool = false) {
    #insert #run specialize(Axis_Types, "fit_bounds", .["gui_rect", "overwrite_constraints"]);
}
mouse_dragging :: (b: *Axis) -> *MouseState_Dragging {
    #insert #run specialize(Axis_Types, "mouse_dragging", .[], 1);
}
mouse_rmb_dragging :: (b: *Axis) -> *MouseState_RMB_Dragging {
    #insert #run specialize(Axis_Types, "mouse_rmb_dragging", .[], 1);
}
bounds_x :: (using ax: *Axis) -> float32, float32 {
    assert(graphs2d.count > 0);
    _min, _max := bounds_x(graphs2d[0]);
    for i:1..graphs2d.count-1 {
        mi, ma := bounds_x(graphs2d[i]);
        _min = min(_min, mi);
        _max = max(_max, ma);
    }
    return _min, _max;
}
bounds_y :: (using ax: *Axis) -> float32, float32 {
    assert(graphs2d.count > 0);
    _min, _max := bounds_y(graphs2d[0]);
    for i:1..graphs2d.count-1 {
        mi, ma := bounds_y(graphs2d[i]);
        _min = min(_min, mi);
        _max = max(_max, ma);
    }
    return _min, _max;
}
bounds_extra :: (using ax: *Axis, index: int) -> float32, float32 {
    assert(graphs2d.count > 0);

    _min := Math.FLOAT32_MAX;
    _max := Math.FLOAT32_MIN;

    for graphs2d {
        if it.extra.count > index {
            mi,ma := bounds_extra(it, index);
            _min = min(_min, mi);
            _max = max(_max, ma);
        }
    }

    return _min, _max;
}




//  ######     ###    ########  ######## ########  ######  ####    ###    ##    ##     #######  ########
// ##    ##   ## ##   ##     ##    ##    ##       ##    ##  ##    ## ##   ###   ##    ##     ## ##     ##
// ##        ##   ##  ##     ##    ##    ##       ##        ##   ##   ##  ####  ##           ## ##     ##
// ##       ##     ## ########     ##    ######    ######   ##  ##     ## ## ## ##     #######  ##     ##
// ##       ######### ##   ##      ##    ##             ##  ##  ######### ##  ####    ##        ##     ##
// ##    ## ##     ## ##    ##     ##    ##       ##    ##  ##  ##     ## ##   ###    ##        ##     ##
//  ######  ##     ## ##     ##    ##    ########  ######  #### ##     ## ##    ##    ######### ########

#scope_export
Axis_2D_Cartesian :: struct {
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
    title_padding: float32;
    x_label: string;
    y_label: string;
    x_label_texture: *RenderTexture2D = null; // lazy
    y_label_texture: *RenderTexture2D = null; // lazy
    x_label_padding: float32;
    y_label_padding: float32;

    show_frame: bool = true;
    show_zero_lines: bool = true;
    show_grid: bool = true;
    show_tick_labels_left  : bool = true;
    show_tick_labels_right : bool = true;
    show_tick_labels_top   : bool = true;
    show_tick_labels_bottom: bool = true;
    hide_overflow: bool = true;
    show_gui: bool = true;

    axis_padding := Vector4.{60.0, 30.0, 60.0, 30.0}; // left, top, right, bottom

    // ticks
    font_size : s32 = 10;
    tick_length := 5;
    tick_thickness := 2.0;
    y_padding := 8;
    x_padding := 8;
    tick_padding := 5;
}
axis_2d_cartesian :: (x_mapper: *Mapper = null, y_mapper: *Mapper = null, title:="", x_label:="", y_label:="") -> *Axis_2D_Cartesian {
    res := New(Axis_2D_Cartesian);
    res.type = Axis_2D_Cartesian;
    res.axis_rectangle = WINDOW_RECT;
    res.graphs2d  = NewResizableArray(0, *Graph_2D);
    res.activated = false;

    res.button_reset         = button_framed(Rectangle.{}, "reset", res.font_size);
    res.button_equal_scaling = button_framed(Rectangle.{}, "1:1"  , res.font_size);
    res.button_fit           = button_framed(Rectangle.{}, "fit"  , res.font_size);
    
    res.x_mapper = ifx x_mapper then x_mapper else mapper_linear();
    res.y_mapper = ifx y_mapper then y_mapper else mapper_linear();

    res.title   = title;
    res.title_padding = ifx title == "" then 0.0 else 3.0*res.font_size;
    res.x_label = x_label;
    res.y_label = y_label;
    res.x_label_padding = ifx x_label == "" then 0.0 else 3.0 * res.font_size;
    res.y_label_padding = ifx y_label == "" then 0.0 else 3.0 * res.font_size;

    res.original_x_mapper = clone(res.x_mapper);
    res.original_y_mapper = clone(res.y_mapper);

    subscribe(_broadcaster, res, on_event);

    return res;
}
#scope_module
reset :: (axis: *Axis_2D_Cartesian) {
    xm := axis.x_mapper;
    ym := axis.y_mapper;
    defer {
        free(xm);
        free(ym);
    }
    axis.x_mapper = clone(axis.original_x_mapper);
    axis.y_mapper = clone(axis.original_y_mapper);
}
intersection_axis :: inline (axis: *Axis_2D_Cartesian, pos: Vector2) -> bool {
    return CheckCollisionPointRec(pos, axis.inner_rect);
}
zoom :: (using axis: *Axis_2D_Cartesian, mouse: Vector2, wheel: float32) {
    using inner_rect;
    
    delta := 0.02 * wheel;

    xmin := map_inv(x_mapper, (mouse.x - x)          * delta + x        );
    xmax := map_inv(x_mapper, (mouse.x - (x+width )) * delta + x+width  );
    ymin := map_inv(y_mapper, (mouse.y - y)          * delta + y        );
    ymax := map_inv(y_mapper, (mouse.y - (y+height)) * delta + y+height );

    fit_bounds(x_mapper, xmin, xmax, x, x + width , true);
    fit_bounds(y_mapper, ymin, ymax, y, y + height, true);
}
equal_scaling :: (using axis: *Axis_2D_Cartesian) {
    using inner_rect;

    xm := x_mapper;
    ym := y_mapper;
    defer {
        free(xm);
        free(ym);
    }

    x0 := map_inv(x_mapper, x + 0.5*width );
    y0 := map_inv(y_mapper, y + 0.5*height);

    xmin, xmax, ymin, ymax : float32;
    if width < height {   // portrait
        xmin = map_inv(x_mapper, x);
        xmax = map_inv(x_mapper, x + width);
        dxdp := (xmax-xmin)/width;
        if flip_y then dxdp = -dxdp;
        ymin = -dxdp*height*0.5 + y0;
        ymax =  dxdp*height*0.5 + y0;
    } else {                           // landscape
        ymin = map_inv(y_mapper, y);
        ymax = map_inv(y_mapper, y + height);
        dydp := (ymax-ymin)/height;
        if flip_y then dydp *= -1.0;
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
fit_into_rectangle :: (using ax: *Axis_2D_Cartesian, r: Rectangle) {
    axis_rectangle = r;

    left_padding   := y_label_padding;
    bottom_padding := x_label_padding;

    inner_rect.x = r.x + axis_padding.x + left_padding;
    inner_rect.y = r.y + axis_padding.y + title_padding ;
    inner_rect.width  = r.width  - (axis_padding.x + axis_padding.z + left_padding);
    inner_rect.height = r.height - (axis_padding.y + axis_padding.w + title_padding + bottom_padding);
}
fit_bounds :: (using ax: *Axis_2D_Cartesian, gui_rect: Rectangle, overwrite_constraints : bool = false) {
    min_x := map_inv(x_mapper, gui_rect.x);
    max_x := map_inv(x_mapper, gui_rect.x+gui_rect.width);
    min_y := map_inv(y_mapper, gui_rect.y);
    max_y := map_inv(y_mapper, gui_rect.y+gui_rect.height);

    using inner_rect;
    fit_bounds(x_mapper, min_x, max_x, x, x+width , overwrite_constraints);
    fit_bounds(y_mapper, min_y, max_y, y, y+height, overwrite_constraints);
}
fit_data :: (using ax: *Axis_2D_Cartesian, overwrite_constraints: bool = false) {
    if graphs2d.count == 0 then return;

    min_x, max_x := bounds_x(ax);
    min_y, max_y := bounds_y(ax);

    using inner_rect;
    fit_bounds(x_mapper, min_x, max_x, x, x+width , overwrite_constraints);
    if !flip_y {
        fit_bounds(y_mapper, min_y, max_y, y, y+height, overwrite_constraints);
    } else {
        fit_bounds(y_mapper, min_y, max_y, y+height, y, overwrite_constraints);
    }
}
on_event :: (ax: *Axis_2D_Cartesian, event: *Event) {
    if !ax.activated then return;

    if event.type == {
        case Event_Button;
            e := cast(*Event_Button)event;
            if e.button_event_type != .PRESSED then return;

            if e.button == ax.button_reset {
                reset(ax);
            }
            if e.button == ax.button_equal_scaling {
                equal_scaling(ax);
            }
            if e.button == ax.button_fit {
                fit_data(ax, true);
            }
        case Event_Mouse_Button;
            e := cast(*Event_Mouse_Button)event;

            is_over_reset := is_over(ax.button_reset        , e.position);
            is_over_eq_sc := is_over(ax.button_equal_scaling, e.position);
            is_over_fit   := is_over(ax.button_fit          , e.position);
            if is_over_reset || is_over_eq_sc || is_over_fit then return;

            if e.button == 0 && e.button_event_type == .PRESSED && CheckCollisionPointRec(e.position, ax.inner_rect) {
                broadcast(_broadcaster, event_axis(cast(*Axis)ax, .MOVE));
            }
            if e.button == 1 && e.button_event_type == .PRESSED && CheckCollisionPointRec(e.position, ax.inner_rect) {
                broadcast(_broadcaster, event_axis(cast(*Axis)ax, .RECT_ZOOM));
            }
        case Event_Mouse_Wheel;
            e := cast(*Event_Mouse_Wheel)event;

            if e.wheel != 0.0 && CheckCollisionPointRec(e.position, ax.inner_rect) {
                zoom(ax, e.position, e.wheel);
            }
    }
}
draw :: (using ax: *Axis_2D_Cartesian) {
    fit_data(ax);
    // map(ax);

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
                case Mapper_Linear;
                    xticks = ticks_linear(mi, ma, 10.0, exponent_shift - log10_of_5 );
                case Mapper_Logarithmic;
                    xticks = ticks_logarithmic(mi, ma, 10.0);
            }
        } else {
            mi := map_inv(y_mapper, inner_rect.y                    );
            ma := map_inv(y_mapper, inner_rect.y + inner_rect.height);
            if mi == ma then return;
            if mi > ma { mi, ma = swap(mi, ma); }

            if get_inner_type(y_mapper) == {
                case Mapper_Linear;
                    yticks = ticks_linear(mi, ma, 10.0, exponent_shift - log10_of_5 );
                case Mapper_Logarithmic;
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
    for graphs2d {
        draw(it, x_mapper, y_mapper);
    }
    if hide_overflow then EndScissorMode();

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

                if !first_tick || Math.abs(tx-xend) > cast(float32)(tick_padding+text_width) {
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

                if !first_tick || Math.abs(ty-yend) > cast(float32)(tick_padding+font_size) {
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
        x := center_x(inner_rect) - 0.5*text_width;
        DrawText(title, cast(s32)x, cast(s32)(axis_rectangle.y + 0.5*title_padding - 0.5*fs), cast(s32)fs, BLACK);
    }

    if x_label != "" {
        if !x_label_texture {
            xw := 10 + MeasureText(x_label, font_size);
            x_label_texture = New(RenderTexture2D, false);
            <<x_label_texture = render_to_texture(xw, 2*font_size, #code {
                ClearBackground(TRANSPARENT);
                DrawText(x_label, 5, cast(s32)(0.5*font_size), font_size, BLACK);
            });
        }

        tw := x_label_texture.texture.width;
        th := x_label_texture.texture.height;
        tr := rectangle(0,0,tw, -th);
        label_pos := centrize(rectangle(
            center_x(inner_rect),
            bottom(axis_rectangle) - 0.5*y_label_padding,
            tw,
            th
        ));
        DrawTexturePro(x_label_texture.texture, tr, label_pos, vec2(), 0.0, WHITE);
    }

    if y_label != "" {
        if !y_label_texture {
            yw := 10 + MeasureText(y_label, font_size);
            y_label_texture = New(RenderTexture2D, false);
            <<y_label_texture = render_to_texture(yw, 2*font_size, #code {
                ClearBackground(TRANSPARENT);
                DrawText(y_label, 5, cast(s32)(0.5*font_size), font_size, BLACK);
            });
        }

        tw := y_label_texture.texture.width;
        th := y_label_texture.texture.height;
        tr := rectangle(0,0,tw, -th);
        label_pos := rectangle(
            axis_rectangle.x + 0.5*y_label_padding,
            center_y(inner_rect),
            tw,
            th
        );
        // print("y label_pos %\n", label_pos);
        // print("inner_rect % -> center_y = %\n", inner_rect, center_y(inner_rect));
        DrawTexturePro(y_label_texture.texture, tr, label_pos, 0.5*vec2(tw,th), -90.0, WHITE);
        // DrawTexturePro(y_label_texture.texture, tr, label_pos, 0.5*vec2(tw,th),   0.0, WHITE);
    }

    if show_gui {
        {
            button_height := 20.0;
            button_width  := 50.0;
            button_y := inner_rect.y + 0.5 * button_height;

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


