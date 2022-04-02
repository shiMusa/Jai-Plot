#import "Basic";


Event :: struct {
    msg: string;
}
event :: (msg: string) -> *Event {
    res := New(Event);
    res.msg = msg;
    return res;
}

Subscription :: struct {
    subscriber: *void;
    callback: (*void, *Event) -> ();
}

EventBus :: struct {
    subscriptions: [..]Subscription;
}
event_bus :: () -> EventBus {
    res: EventBus;
    return res;
}
subscribe :: (bus: EventBus, type: *$T, callback: (*T, *Event)->()) {
    sub : Subscription;
    sub.subscriber = cast(*void)type;
    sub.callback   = cast((*void, *Event)->())callback;

    array_add(*bus.subscriptions, sub);
}
broadcast :: (bus: EventBus, event: *Event) {
    for bus.subscriptions {
        it.callback(it.subscriber, event);
    }
}


Foo :: struct {}

foo :: () -> *Foo {
    res := New(Foo);
    return res;
}
foo_hello :: (f: *Foo, e: *Event) {
    print("Hello from Foo! => \"%\"\n", e.msg);
}


_event_bus : EventBus;

main :: () {
    f := foo();
    g := foo();
    subscribe(_event_bus, f, foo_hello);
    subscribe(_event_bus, g, foo_hello);

    broadcast(_event_bus, event("what's up?"));
}