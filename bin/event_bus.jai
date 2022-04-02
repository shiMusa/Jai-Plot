#import "Basic";


Event :: struct {
    msg: string;
}
event :: (msg: string) -> *Event {
    res := New(Event);
    res.msg = msg;
    return res;
}


EventBus :: struct {
    subscriptions: [..]Subscription;
    
    Subscription :: struct {
        subscriber: *void;
        callback: (*void, *Event) -> ();
    }
}
subscribe :: (bus: EventBus, type: *$T, callback: (*T, *Event)->()) {
    sub : EventBus.Subscription;
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



main :: () {
    bus : EventBus;

    f := foo();
    g := foo();
    subscribe(bus, f, foo_hello);
    subscribe(bus, g, foo_hello);

    broadcast(bus, event("what's up?"));
}