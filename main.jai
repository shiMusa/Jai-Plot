#import "Basic";
#load "Plot.jai";



simulation :: (_thread: *Thread = null) -> s64 {

    for *x {
        <<it = -500.0 + 1000.0 * (cast(float32)it_index/cast(float32)(N-1));
    }

    t0 := GetTime();
    while !stop_simulation {
        t := GetTime() - t0;

        for i: 0..N-1 {
            y[i] = Math.sin(cast(float32)(t/10.0 * PI) + x[i]/200.0 * cast(float32)PI);
            z[i] = Math.cos(cast(float32)(t/10.0 * PI) + x[i]/200.0 * cast(float32)PI);
            w[i] = -Math.sin(cast(float32)(t/10.0 * PI) + x[i]/200.0 * cast(float32)PI);
        }
        // print("simulate\n");
        sleep_milliseconds(10);
    }
    return 0;
}


stop_simulation : bool = false;

N :: 201;
NP :: 20;
x : [N]float32;
y : [N]float32;
z : [N]float32;
w : [N]float32;

main :: () {
    print("Hello World\n");




    plot();
    axis := cartesian_axis_2d();
    set_min_max(*axis.x_mapper, -600.0, 600.0);
    set_min_max(*axis.y_mapper, -2.0, 2.0);
    ax_id := add_axis(axis);
    plot2d(bars(Color.{ 211, 176, 131, 125 }), x, w);
    plot2d(line(BLUE), x, y);
    plot2d(symbols(), x, z);
    // plot_render();



    sim := New(Thread);
    thread_init(sim, simulation);
    thread_start(sim);
    // simulation(null);

    // stop everything
    plot_wait_for_close();
    stop_simulation = true;
    while !thread_is_done(sim) {
        sleep_milliseconds(100);
    }
}