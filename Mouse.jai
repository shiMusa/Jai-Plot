


// ##     ##  #######  ##     ##  ######  ########
// ###   ### ##     ## ##     ## ##    ## ##
// #### #### ##     ## ##     ## ##       ##
// ## ### ## ##     ## ##     ##  ######  ######
// ##     ## ##     ## ##     ##       ## ##
// ##     ## ##     ## ##     ## ##    ## ##
// ##     ##  #######   #######   ######  ########


Mouse_State_Types :: enum u8 {
    FREE;
    DRAGGING;
    RMB_DRAGGING;
}
Mouse_State :: struct {
    type: Mouse_State_Types = .FREE;
    x: float32 = 0.0;
    y: float32 = 0.0;
}

draw :: (mouse: *Mouse_State) {
    if mouse.type == {
        case .FREE;
            m := cast(*Mouse_State_Free)mouse;
            draw(m);
        case .DRAGGING;
            m := cast(*Mouse_State_Dragging)mouse;
            draw(m);
        case .RMB_DRAGGING;
            m := cast(*Mouse_State_RMB_Dragging)mouse;
            draw(m);
    }
}



mouse_on_event :: (mouse: *Mouse_State, event: *Event) {

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
    res.x = cast(float32)GetMouseX();
    res.y = cast(float32)GetMouseY();

    subscribe(_broadcaster, res, mouse_free_on_event);

    return res;
}
draw :: (mouse: *Mouse_State_Free) {}
mouse_stop_free :: (mouse: *Mouse_State_Free) {
    unsubscribe(_broadcaster, mouse);
}
mouse_free_on_event :: (using mouse: *Mouse_State_Free, event: *Event) {
    if event.event_type == {
        case .AXIS;
            e := cast(*EventAxis)event;
            if e.axis_event_type == {
                case .MOVE;
                    mouse_stop_free(mouse);
                    _mouse = cast(*Mouse_State)mouse_dragging(e.axis);
                    free(mouse);
                case .RECT_ZOOM;
                    mouse_stop_free(mouse);
                    _mouse = cast(*Mouse_State)mouse_rmb_dragging(e.axis);
                    free(mouse);
            }
    }
}

Mouse_State_Dragging :: struct {
    using mouse_state: Mouse_State;
    old_x: float32 = 0.0;
    old_y: float32 = 0.0;
    axis: *CartesianAxis2D;
}
mouse_dragging :: (using axis: *CartesianAxis2D) -> *Mouse_State_Dragging {
    using inner_rect;

    res := New(Mouse_State_Dragging);
    res.type = .DRAGGING;
    res.x = cast(float32)GetMouseX();
    res.y = cast(float32)GetMouseY();
    res.axis = axis;

    mx := ifx x_mapper.type == .CONSTRAINT then (cast(*Mapper_Constraint)x_mapper).inner else x_mapper;
    my := ifx y_mapper.type == .CONSTRAINT then (cast(*Mapper_Constraint)y_mapper).inner else y_mapper;
    res.old_x = map_inv(mx, cast(float32)res.x);
    res.old_y = map_inv(my, cast(float32)res.y);

    x_mapper = mapper_constraint(mx, map_inv(mx, x), map_inv(mx, x+width ), x, x+width );
    y_mapper = mapper_constraint(my, map_inv(my, y), map_inv(my, y+height), y, y+height);

    subscribe(_broadcaster, res, mouse_dragging_on_event);
    
    return res;
}
draw :: (mouse: *Mouse_State_Dragging) {}
mouse_dragging_on_event :: (using mouse: *Mouse_State_Dragging, event: *Event) {
    if event.event_type == {
        case. MOUSE_POSITION;
            e := cast(*EventMousePosition)event;
            x = e.position.x;
            y = e.position.y;
            mx := cast(*Mapper_Constraint)axis.x_mapper;
            my := cast(*Mapper_Constraint)axis.y_mapper;
            fit(mx, old_x, x);
            fit(my, old_y, y);
        case .MOUSE_BUTTON;
            e := cast(*EventMouseButton)event;
            if e.button == 0 && e.button_event_type == .RELEASED {
                mouse_stop_dragging(mouse);
                _mouse = cast(*Mouse_State)mouse_free();
                free(mouse);
            }
    }
}
mouse_stop_dragging :: (using mouse: *Mouse_State_Dragging) {
    unsubscribe(_broadcaster, mouse);
}




Mouse_State_RMB_Dragging :: struct {
    using mouse_state: Mouse_State;
    old_x, old_y: float32;
    axis: *CartesianAxis2D;
}
mouse_rmb_dragging :: (axis: *CartesianAxis2D) -> *Mouse_State_RMB_Dragging {
    res := New(Mouse_State_RMB_Dragging);
    res.type = .RMB_DRAGGING;
    res.x = cast(float32)GetMouseX();
    res.y = cast(float32)GetMouseY();
    res.axis = axis;
    res.old_x = res.x;
    res.old_y = res.y;

    subscribe(_broadcaster, res, mouse_rmb_dragging_on_event);

    return res;
}
mouse_rmb_dragging_on_event :: (using mouse: *Mouse_State_RMB_Dragging, event: *Event) {
    if event.event_type == {
        case. MOUSE_POSITION;
            e := cast(*EventMousePosition)event;
            x = e.position.x;
            y = e.position.y;
        case .MOUSE_BUTTON;
            e := cast(*EventMouseButton)event;
            if e.button == 1 && e.button_event_type == .RELEASED {
                mouse_stop_dragging(mouse);
                _mouse = cast(*Mouse_State)mouse_free();
                free(mouse);
            }
    }
}
draw :: (using mouse: *Mouse_State_RMB_Dragging) {
    rx, rwidth, ry, rheight: float32;
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
mouse_stop_dragging :: (using mouse: *Mouse_State_RMB_Dragging) {
    unsubscribe(_broadcaster, mouse);
    
    rx, rwidth, ry, rheight: float32;
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
}

