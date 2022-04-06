

// ########  ########   #######     ###    ########   ######     ###     ######  ######## ######## ########
// ##     ## ##     ## ##     ##   ## ##   ##     ## ##    ##   ## ##   ##    ##    ##    ##       ##     ##
// ##     ## ##     ## ##     ##  ##   ##  ##     ## ##        ##   ##  ##          ##    ##       ##     ##
// ########  ########  ##     ## ##     ## ##     ## ##       ##     ##  ######     ##    ######   ########
// ##     ## ##   ##   ##     ## ######### ##     ## ##       #########       ##    ##    ##       ##   ##
// ##     ## ##    ##  ##     ## ##     ## ##     ## ##    ## ##     ## ##    ##    ##    ##       ##    ##
// ########  ##     ##  #######  ##     ## ########   ######  ##     ##  ######     ##    ######## ##     ##

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
    // s := str(event); defer free(s);
    // print("broadcasting to % subscribers: %\n", bus.subscriptions.count, s);
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
    MOUSE_WHEEL;
    AXIS;
    BUTTON;
    WINDOW;
    PLOT;
}

Event :: struct {
    event_type: EventType;
}
str :: (event: *Event) -> string {
    if event.event_type == {
        case .MOUSE_POSITION;
            e := cast(*EventMousePosition)event;
            return sprint("%", <<e);
        case .MOUSE_BUTTON;
            e := cast(*EventMouseButton)event;
            return sprint("%", <<e);
        case .MOUSE_WHEEL; 
            e := cast(*EventMouseWheel)event;
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




// ########  ##        #######  ########    ######## ##     ## ######## ##    ## ########  ######
// ##     ## ##       ##     ##    ##       ##       ##     ## ##       ###   ##    ##    ##    ##
// ##     ## ##       ##     ##    ##       ##       ##     ## ##       ####  ##    ##    ##
// ########  ##       ##     ##    ##       ######   ##     ## ######   ## ## ##    ##     ######
// ##        ##       ##     ##    ##       ##        ##   ##  ##       ##  ####    ##          ##
// ##        ##       ##     ##    ##       ##         ## ##   ##       ##   ###    ##    ##    ##
// ##        ########  #######     ##       ########    ###    ######## ##    ##    ##     ######


EventPlot :: struct {
    using event: Event;
    page: *Page;
}
event_plot :: (page: *Page) -> *EventPlot {
    res := New(EventPlot);
    res.event_type = .PLOT;
    res.page = page;
    return res;
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


// ##     ##  #######  ##     ##  ######  ########    ######## ##     ## ######## ##    ## ########  ######
// ###   ### ##     ## ##     ## ##    ## ##          ##       ##     ## ##       ###   ##    ##    ##    ##
// #### #### ##     ## ##     ## ##       ##          ##       ##     ## ##       ####  ##    ##    ##
// ## ### ## ##     ## ##     ##  ######  ######      ######   ##     ## ######   ## ## ##    ##     ######
// ##     ## ##     ## ##     ##       ## ##          ##        ##   ##  ##       ##  ####    ##          ##
// ##     ## ##     ## ##     ## ##    ## ##          ##         ## ##   ##       ##   ###    ##    ##    ##
// ##     ##  #######   #######   ######  ########    ########    ###    ######## ##    ##    ##     ######

EventMousePosition :: struct {
    using event: Event;
    position: Vector2;
}
event_mouse_position :: (position: Vector2) -> *EventMousePosition {
    res := New(EventMousePosition);
    res.event_type = .MOUSE_POSITION;
    res.position = position;
    return res;
}




EventMouseWheel :: struct {
    using event: Event;
    position: Vector2;
    wheel: float32;
}
event_mouse_wheel :: (position: Vector2, wheel: float32) -> *EventMouseWheel {
    res := New(EventMouseWheel);
    res.event_type = .MOUSE_WHEEL;
    res.position = position;
    res.wheel = wheel;
    return res;
}



ButtonEventType :: enum u8 {
    DOWN;
    UP;
    PRESSED;
    RELEASED;
}
EventMouseButton :: struct {
    using event: Event;
    position: Vector2;
    button: u8;
    button_event_type: ButtonEventType;
}
event_mouse_button :: (button: u8, position: Vector2, button_event_type: ButtonEventType) -> *EventMouseButton {
    res := New(EventMouseButton);

    res.event_type = .MOUSE_BUTTON;

    res.button_event_type = button_event_type;
    res.position = position;
    res.button = button;

    return res;
}


