


// ##     ##  #######  ##     ##  ######  ########
// ###   ### ##     ## ##     ## ##    ## ##
// #### #### ##     ## ##     ## ##       ##
// ## ### ## ##     ## ##     ##  ######  ######
// ##     ## ##     ## ##     ##       ## ##
// ##     ## ##     ## ##     ## ##    ## ##
// ##     ##  #######   #######   ######  ########


MouseState_Types :: Type.[
    MouseState_Free,
    MouseState_Dragging,
    MouseState_RMB_Dragging
];

MouseState :: struct {
    type: Type;
    using position: Vector2;
}

draw :: (b: *MouseState) {
    #insert #run specialize(MouseState_Types, "draw");
}





MouseState_Free :: struct {
    using mouse_state: MouseState;
}
mouse_free :: () -> *MouseState_Free {
    res := New(MouseState_Free);
    res.type = MouseState_Free;
    res.x = cast(float32)GetMouseX();
    res.y = cast(float32)GetMouseY();

    subscribe(_broadcaster, res, on_event);

    return res;
}
draw :: (mouse: *MouseState_Free) {}
mouse_stop_free :: (mouse: *MouseState_Free) {
    unsubscribe(_broadcaster, mouse);
}
on_event :: (using mouse: *MouseState_Free, event: *Event) {
    if event.type == {
        case Event_Axis;
            e := cast(*Event_Axis)event;
            if e.axis_event_type == {
                case .MOVE;
                    mouse_stop_free(mouse);
                    _mouse = cast(*MouseState)mouse_dragging(e.axis);
                    free(mouse);
                case .RECT_ZOOM;
                    mouse_stop_free(mouse);
                    _mouse = cast(*MouseState)mouse_rmb_dragging(e.axis);
                    free(mouse);
            }
    }
}



MouseState_Dragging :: struct {
    using mouse_state: MouseState;
}
mouse_dragging :: (using axis: *Axis_2D_Cartesian) -> *MouseState_Dragging {
    using inner_rect;

    res := New(MouseState_Dragging);
    res.type = MouseState_Dragging;
    res.x = cast(float32)GetMouseX();
    res.y = cast(float32)GetMouseY();

    subscribe(_broadcaster, res, on_event);
    
    return res;
}
draw :: (mouse: *MouseState_Dragging) {}
on_event :: (using mouse: *MouseState_Dragging, event: *Event) {
    if event.type == {
        case Event_Mouse_Position;
            e := cast(*Event_Mouse_Position)event;
            position = e.position;
            broadcast(_broadcaster, event_mouse_drag(e.position, button=0));
        case Event_Mouse_Button;
            e := cast(*Event_Mouse_Button)event;
            if e.button == 0 && e.button_event_type == .RELEASED {
                mouse_stop_dragging(mouse);
                _mouse = cast(*MouseState)mouse_free();
                free(mouse);
            }
    }
}
mouse_stop_dragging :: (using mouse: *MouseState_Dragging) {
    unsubscribe(_broadcaster, mouse);
}




MouseState_RMB_Dragging :: struct {
    using mouse_state: MouseState;
    old_x, old_y: float32;
    axis: *Axis_2D_Cartesian;
}
mouse_rmb_dragging :: (axis: *Axis_2D_Cartesian) -> *MouseState_RMB_Dragging {
    res := New(MouseState_RMB_Dragging);
    res.type = MouseState_RMB_Dragging;
    res.x = cast(float32)GetMouseX();
    res.y = cast(float32)GetMouseY();
    res.axis = axis;
    res.old_x = res.x;
    res.old_y = res.y;

    subscribe(_broadcaster, res, on_event);

    return res;
}
on_event :: (using mouse: *MouseState_RMB_Dragging, event: *Event) {
    if event.type == {
        case Event_Mouse_Position;
            e := cast(*Event_Mouse_Position)event;
            x = e.position.x;
            y = e.position.y;
        case Event_Mouse_Button;
            e := cast(*Event_Mouse_Button)event;
            if e.button == 1 && e.button_event_type == .RELEASED {
                mouse_stop_dragging(mouse);
                _mouse = cast(*MouseState)mouse_free();
                free(mouse);
            }
    }
}
draw :: (using mouse: *MouseState_RMB_Dragging) {
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
mouse_stop_dragging :: (using mouse: *MouseState_RMB_Dragging) {
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

