


//    ###    ##     ## ####  ######
//   ## ##    ##   ##   ##  ##    ##
//  ##   ##    ## ##    ##  ##
// ##     ##    ###     ##   ######
// #########   ## ##    ##        ##
// ##     ##  ##   ##   ##  ##    ##
// ##     ## ##     ## ####  ######


Axis_2D_Types :: Type.[
    Axis_2D_Cartesian,
    Axis_2D_Polar
];

Axis_2D :: struct {
    type: Type;
    axis_rectangle: Rectangle;
    graphs2d: [..]*Graph_2D;
    
    activated: bool;
}


#scope_export
plot2d :: (graph2d: *Graph_2D) {
    array_add(*_plot.active_axis.graphs2d, graph2d);
}
plot2d :: (ax: *Axis_2D, graph2d: *Graph_2D) {
    array_add(*ax.graphs2d, graph2d);
}
#scope_module




intersection_axis :: (b: *Axis_2D, pos: Vector2) -> bool {
    #insert #run specialize(Axis_2D_Types, "intersection_axis", .["pos"], 1);
}
draw :: (b: *Axis_2D) {
    #insert #run specialize(Axis_2D_Types, "draw");
}
update :: (b: *Axis_2D) {
    #insert #run specialize(Axis_2D_Types, "update");
}
reset :: (b: *Axis_2D) {
    #insert #run specialize(Axis_2D_Types, "reset");
}
zoom :: (b: *Axis_2D, position: Vector2, wheel: float32) {
    #insert #run specialize(Axis_2D_Types, "zoom", .["position", "wheel"]);
}
fit_into_rectangle :: (b: *Axis_2D, rectangle: Rectangle) {
    #insert #run specialize(Axis_2D_Types, "fit_into_rectangle", .["rectangle"]);
}
fit_data :: (b: *Axis_2D, overwrite_constraints: bool = false) {
    #insert #run specialize(Axis_2D_Types, "fit_data", .["overwrite_constraints"]);
}
fit_bounds :: (b: *Axis_2D, gui_rect: Rectangle, overwrite_constraints : bool = false) {
    #insert #run specialize(Axis_2D_Types, "fit_bounds", .["gui_rect", "overwrite_constraints"]);
}
mouse_dragging :: (b: *Axis_2D) -> *MouseState_Dragging {
    #insert #run specialize(Axis_2D_Types, "mouse_dragging", .[], 1);
}
mouse_rmb_dragging :: (b: *Axis_2D) -> *MouseState_RMB_Dragging {
    #insert #run specialize(Axis_2D_Types, "mouse_rmb_dragging", .[], 1);
}
bounds_x :: (using ax: *Axis_2D) -> float32, float32 {
    assert(graphs2d.count > 0);
    _min, _max := bounds_x(graphs2d[0]);
    for i:1..graphs2d.count-1 {
        mi, ma := bounds_x(graphs2d[i]);
        _min = min(_min, mi);
        _max = max(_max, ma);
    }
    return _min, _max;
}
bounds_y :: (using ax: *Axis_2D) -> float32, float32 {
    assert(graphs2d.count > 0);
    _min, _max := bounds_y(graphs2d[0]);
    for i:1..graphs2d.count-1 {
        mi, ma := bounds_y(graphs2d[i]);
        _min = min(_min, mi);
        _max = max(_max, ma);
    }
    return _min, _max;
}
bounds_extra :: (using ax: *Axis_2D, index: int) -> float32, float32 {
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
    using _axis: Axis_2D;

    inner_rect : Rectangle;

    original_x_mapper: *Mapper_1D;
    original_y_mapper: *Mapper_1D;

    x_mapper: *Mapper_1D;
    y_mapper: *Mapper_1D;
    flip_y: bool = true;

    button_reset        : *Button;
    button_equal_scaling: *Button;
    button_fit          : *Button;
    button_grid         : *Button;

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
axis_2d_cartesian :: (x_mapper: *Mapper_1D = null, y_mapper: *Mapper_1D = null, title:="", x_label:="", y_label:="") -> *Axis_2D_Cartesian {
    res := New(Axis_2D_Cartesian);
    res.type = Axis_2D_Cartesian;
    res.axis_rectangle = WINDOW_RECT;
    res.graphs2d  = NewResizableArray(0, *Graph_2D);
    res.activated = false;

    res.button_reset         = button_framed(Rectangle.{}, "reset", res.font_size);
    res.button_equal_scaling = button_framed(Rectangle.{}, "1:1"  , res.font_size);
    res.button_fit           = button_framed(Rectangle.{}, "fit"  , res.font_size);
    res.button_grid          = button_framed(Rectangle.{}, "#"    , res.font_size);

    
    res.x_mapper = ifx x_mapper then x_mapper else mapper_1d_linear();
    res.y_mapper = ifx y_mapper then y_mapper else mapper_1d_linear();

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

    x_mapper = mapper_1d_constraint(
        mapper_1d_linear(), 
        xmin, 
        xmax, 
        x, 
        x + width
    );
    y_mapper = mapper_1d_constraint(
        mapper_1d_linear(), 
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

            if e.button == ax.button_reset         then reset(ax);
            if e.button == ax.button_equal_scaling then equal_scaling(ax);
            if e.button == ax.button_fit           then fit_data(ax, true);
            if e.button == ax.button_grid          then ax.show_grid = !ax.show_grid;

        case Event_Mouse_Button;
            e := cast(*Event_Mouse_Button)event;

            is_over_reset := is_over(ax.button_reset        , e.position);
            is_over_eq_sc := is_over(ax.button_equal_scaling, e.position);
            is_over_fit   := is_over(ax.button_fit          , e.position);
            if is_over_reset || is_over_eq_sc || is_over_fit then return;

            if e.button == 0 && e.button_event_type == .PRESSED && CheckCollisionPointRec(e.position, ax.inner_rect) {
                broadcast(_broadcaster, event_axis(cast(*Axis_2D)ax, .MOVE));
            }
            if e.button == 1 && e.button_event_type == .PRESSED && CheckCollisionPointRec(e.position, ax.inner_rect) {
                broadcast(_broadcaster, event_axis(cast(*Axis_2D)ax, .RECT_ZOOM));
            }
        case Event_Mouse_Wheel;
            e := cast(*Event_Mouse_Wheel)event;

            if e.wheel != 0.0 && CheckCollisionPointRec(e.position, ax.inner_rect) {
                zoom(ax, e.position, e.wheel);
            }
    }
}
update :: (using ax: *Axis_2D_Cartesian) {
    for graphs2d {
        update(it, x_mapper, y_mapper);
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

    calculate_ticks :: (exponent_shift: float32) #expand {
        { // x
            mi := map_inv(x_mapper, inner_rect.x                   );
            ma := map_inv(x_mapper, inner_rect.x + inner_rect.width);
            if mi == ma then return;
            if mi > ma { mi, ma = swap(mi, ma); }

            if get_inner_type(x_mapper) == {
                case Mapper_1D_Linear;
                    xticks = ticks_linear(mi, ma, 10.0, exponent_shift - log10_of_5 );
                case Mapper_1D_Logarithmic;
                    xticks = ticks_logarithmic(mi, ma, 10.0);
            }
        }
        { // y
            mi := map_inv(y_mapper, inner_rect.y                    );
            ma := map_inv(y_mapper, inner_rect.y + inner_rect.height);
            if mi == ma then return;
            if mi > ma { mi, ma = swap(mi, ma); }

            if get_inner_type(y_mapper) == {
                case Mapper_1D_Linear;
                    yticks = ticks_linear(mi, ma, 10.0, exponent_shift - log10_of_5 );
                case Mapper_1D_Logarithmic;
                    yticks = ticks_logarithmic(mi, ma, 10.0);
            }
        }
    }

    draw_gridlines :: ($x_axis: bool, exponent_shift: float32, color: Color, thickness: float = 1.0) #expand {
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

    calculate_ticks(0.0);

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

            br := bottom_right(inner_rect);
            r = rectangle(br.x - 2*button_height, br.y - 2*button_height, button_height, button_height);
            button_grid.rect = r;
        }

        draw(button_reset);
        draw(button_equal_scaling);
        draw(button_fit);
        draw(button_grid);
    }
}


// ########   #######  ##          ###    ########      #######  ########
// ##     ## ##     ## ##         ## ##   ##     ##    ##     ## ##     ##
// ##     ## ##     ## ##        ##   ##  ##     ##           ## ##     ##
// ########  ##     ## ##       ##     ## ########      #######  ##     ##
// ##        ##     ## ##       ######### ##   ##      ##        ##     ##
// ##        ##     ## ##       ##     ## ##    ##     ##        ##     ##
// ##         #######  ######## ##     ## ##     ##    ######### ########

Axis_2D_Polar :: struct {
    using _axis: Axis_2D;

    mapper_angle : *Mapper_1D_Linear;

    original_mapper_radius  : *Mapper_1D;        // map datapoint radial component
    original_mapper_polar   : *Mapper_2D_Polar;  // map from polar coordinates to cartesian
    original_mapper_pixel_x : *Mapper_1D_Linear; // map to pixel position x 
    original_mapper_pixel_y : *Mapper_1D_Linear; // map to pixel position y
    
    mapper_radius  : *Mapper_1D;        // map datapoint radial component
    mapper_polar   : *Mapper_2D_Polar;  // map from polar coordinates to cartesian
    mapper_pixel_x : *Mapper_1D_Linear; // map to pixel position x 
    mapper_pixel_y : *Mapper_1D_Linear; // map to pixel position y

    show_frame : bool = true;
}
#scope_export
axis_2d_polar :: (mapper_radius: *Mapper_1D = null) -> *Axis_2D_Polar {
    res := New(Axis_2D_Polar);
    res.type = Axis_2D_Polar;
    res.mapper_radius = ifx mapper_radius then mapper_radius else mapper_1d_linear();
    res.mapper_polar = mapper_2d_polar();
    res.mapper_pixel_x = mapper_1d_linear();
    res.mapper_pixel_y = mapper_1d_linear();

    res.mapper_angle = mapper_1d_linear();

    res.original_mapper_radius  = clone(res.mapper_radius);
    res.original_mapper_polar   = clone(res.mapper_polar);
    res.original_mapper_pixel_x = clone(res.mapper_pixel_x);
    res.original_mapper_pixel_y = clone(res.mapper_pixel_y);

    return res;
}

#scope_module
intersection_axis :: (b: *Axis_2D_Polar, pos: Vector2) -> bool {
    return false;
}
draw :: (using b: *Axis_2D_Polar) {
    print("drawing %\n", axis_rectangle);
    if show_frame {
        r := min(axis_rectangle.width, axis_rectangle.height)*0.5;
        DrawCircleJai(center(axis_rectangle), r, BLACK, 2.0, 128);
    }
}
update :: (using b: *Axis_2D_Polar) {
    for graphs2d {
        update(it, mapper_angle, mapper_radius);
    }
}
reset :: (b: *Axis_2D_Polar) {
}
zoom :: (b: *Axis_2D_Polar, position: Vector2, wheel: float32) {
}
fit_into_rectangle :: (using b: *Axis_2D_Polar, rectangle: Rectangle) {
    axis_rectangle = rectangle;
}
fit_data :: (b: *Axis_2D_Polar, overwrite_constraints: bool = false) {
}
fit_bounds :: (b: *Axis_2D_Polar, gui_rect: Rectangle, overwrite_constraints : bool = false) {
}
mouse_dragging :: (b: *Axis_2D_Polar) -> *MouseState_Dragging {
    assert(false, "not yet implemented\n");
}
mouse_rmb_dragging :: (b: *Axis_2D_Polar) -> *MouseState_RMB_Dragging {
    assert(false, "not yet implemented\n");
}