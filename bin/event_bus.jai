#import "Basic";


Event :: struct {
    msg: string;
}
event :: (msg: string) -> *Event {
    res := New(Event);
    res.msg = msg;
    return res;
}


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
    for bus.subscriptions {
        it.callback(it.subscriber, event);
    }
    if consume_event then free(event);
}


Foo :: struct {}
foo :: () -> *Foo {
    res := New(Foo);
    return res;
}
foo_hello :: (f: *Foo, e: *Event) {
    print("Hello from a Foo: \"%\"\n", e.msg);
}


main :: () {
    bus : Broadcaster;

    f := foo();
    g := foo();
    subscribe(bus, f, foo_hello);
    subscribe(bus, g, foo_hello);

    broadcast(bus, event("what's up?"));

    unsubscribe(bus, f);

    broadcast(bus, event("nothing"));
}