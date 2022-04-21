

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

Event_Types :: Type.[
    Event_Mouse_Position,
    Event_Mouse_Button,
    Event_Mouse_Wheel,
    Event_Mouse_Drag,
    Event_Axis,
    Event_Button,
    Event_Plot
];


Event :: struct {
    type: Type;
}
str :: (event: *Event) -> string {
    #insert #run specialize(Event_Types, "str");
}


// ########  ##     ## ######## ########  #######  ##    ##    ######## ##     ## ######## ##    ## ########  ######
// ##     ## ##     ##    ##       ##    ##     ## ###   ##    ##       ##     ## ##       ###   ##    ##    ##    ##
// ##     ## ##     ##    ##       ##    ##     ## ####  ##    ##       ##     ## ##       ####  ##    ##    ##
// ########  ##     ##    ##       ##    ##     ## ## ## ##    ######   ##     ## ######   ## ## ##    ##     ######
// ##     ## ##     ##    ##       ##    ##     ## ##  ####    ##        ##   ##  ##       ##  ####    ##          ##
// ##     ## ##     ##    ##       ##    ##     ## ##   ###    ##         ## ##   ##       ##   ###    ##    ##    ##
// ########   #######     ##       ##     #######  ##    ##    ########    ###    ######## ##    ##    ##     ######


Event_ButtonType :: enum u8 {
    PRESSED;
    HOVER;
}

Event_Button :: struct {
    using event: Event;
    button_event_type: Event_ButtonType;
    button: *Button;
}
event_button :: (button: *Button, type: Event_ButtonType) -> *Event_Button {
    res := New(Event_Button);
    res.type = Event_Button;
    res.button = button;
    res.button_event_type = type;
    return res;
}
str :: (event: *Event_Button) -> string {
    return sprint("%", <<event);
}




// ########  ##        #######  ########    ######## ##     ## ######## ##    ## ########  ######
// ##     ## ##       ##     ##    ##       ##       ##     ## ##       ###   ##    ##    ##    ##
// ##     ## ##       ##     ##    ##       ##       ##     ## ##       ####  ##    ##    ##
// ########  ##       ##     ##    ##       ######   ##     ## ######   ## ## ##    ##     ######
// ##        ##       ##     ##    ##       ##        ##   ##  ##       ##  ####    ##          ##
// ##        ##       ##     ##    ##       ##         ## ##   ##       ##   ###    ##    ##    ##
// ##        ########  #######     ##       ########    ###    ######## ##    ##    ##     ######


Event_Plot :: struct {
    using event: Event;
    page: *Page;
}
event_plot :: (page: *Page) -> *Event_Plot {
    res := New(Event_Plot);
    res.type = Event_Plot;
    res.page = page;
    return res;
}
str :: (event: *Event_Plot) -> string {
    return sprint("%", <<event);
}




//    ###    ##     ## ####  ######     ######## ##     ## ######## ##    ## ########  ######
//   ## ##    ##   ##   ##  ##    ##    ##       ##     ## ##       ###   ##    ##    ##    ##
//  ##   ##    ## ##    ##  ##          ##       ##     ## ##       ####  ##    ##    ##
// ##     ##    ###     ##   ######     ######   ##     ## ######   ## ## ##    ##     ######
// #########   ## ##    ##        ##    ##        ##   ##  ##       ##  ####    ##          ##
// ##     ##  ##   ##   ##  ##    ##    ##         ## ##   ##       ##   ###    ##    ##    ##
// ##     ## ##     ## ####  ######     ########    ###    ######## ##    ##    ##     ######

Event_AxisType :: enum u8 {
    MOVE;
    RECT_ZOOM;
}

Event_Axis :: struct {
    using event: Event;
    axis_event_type: Event_AxisType;
    axis: *Axis_2D;
}
event_axis :: (axis: *Axis_2D, type: Event_AxisType) -> *Event_Axis {
    res := New(Event_Axis);
    res.type = Event_Axis;
    res.axis_event_type = type;
    res.axis = axis;
    return res;
}
str :: (event: *Event_Axis) -> string {
    return sprint("%", <<event);
}


// ##     ##  #######  ##     ##  ######  ########    ######## ##     ## ######## ##    ## ########  ######
// ###   ### ##     ## ##     ## ##    ## ##          ##       ##     ## ##       ###   ##    ##    ##    ##
// #### #### ##     ## ##     ## ##       ##          ##       ##     ## ##       ####  ##    ##    ##
// ## ### ## ##     ## ##     ##  ######  ######      ######   ##     ## ######   ## ## ##    ##     ######
// ##     ## ##     ## ##     ##       ## ##          ##        ##   ##  ##       ##  ####    ##          ##
// ##     ## ##     ## ##     ## ##    ## ##          ##         ## ##   ##       ##   ###    ##    ##    ##
// ##     ##  #######   #######   ######  ########    ########    ###    ######## ##    ##    ##     ######

Event_Mouse_Position :: struct {
    using event: Event;
    using position: Vector2;
}
event_mouse_position :: (position: Vector2) -> *Event_Mouse_Position {
    res := New(Event_Mouse_Position);
    res.type = Event_Mouse_Position;
    res.position = position;
    return res;
}
str :: (event: *Event_Mouse_Position) -> string {
    return sprint("%", <<event);
}

Event_Mouse_Drag :: struct {
    using event: Event;
    using position: Vector2;
    button: u8;
    active: bool;
}
event_mouse_drag :: (position: Vector2, button: u8, active := true) -> *Event_Mouse_Drag {
    res := New(Event_Mouse_Drag);
    res.type = Event_Mouse_Drag;
    res.position = position;
    res.button = button;
    res.active = active;
    return res;
}
str :: (event: *Event_Mouse_Drag) -> string {
    return sprint("%", <<event);
}


Event_Mouse_Wheel :: struct {
    using event: Event;
    using position: Vector2;
    wheel: float32;
}
event_mouse_wheel :: (position: Vector2, wheel: float32) -> *Event_Mouse_Wheel {
    res := New(Event_Mouse_Wheel);
    res.type = Event_Mouse_Wheel;
    res.position = position;
    res.wheel = wheel;
    return res;
}
str :: (event: *Event_Mouse_Wheel) -> string {
    return sprint("%", <<event);
}



ButtonEventType :: enum u8 {
    DOWN;
    UP;
    PRESSED;
    RELEASED;
}
Event_Mouse_Button :: struct {
    using event: Event;
    using position: Vector2;
    button: u8;
    button_event_type: ButtonEventType;
}
event_mouse_button :: (button: u8, position: Vector2, button_event_type: ButtonEventType) -> *Event_Mouse_Button {
    res := New(Event_Mouse_Button);

    res.type = Event_Mouse_Button;

    res.button_event_type = button_event_type;
    res.position = position;
    res.button = button;

    return res;
}
str :: (event: *Event_Mouse_Button) -> string {
    return sprint("%", <<event);
}


