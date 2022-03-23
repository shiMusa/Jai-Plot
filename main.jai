#import "Basic";
#load "Plot.jai";



simulation :: (thread: *Thread) -> s64 {

    for *x {
        <<it = -500.0 + 1000.0 * (cast(float32)it_index/cast(float32)N);
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

N :: 200;
NP :: 20;
x : [N]float32;
y : [N]float32;
z : [N]float32;
w : [N]float32;

main :: () {
    print("Hello World\n");


    sim := New(Thread);
    thread_init(sim, simulation);
    thread_start(sim);


    plot();
    axis := cartesian_axis_2d();
    print("axis.datasets = %, count = %\n", axis.datasets, axis.datasets.count);
    ax_id := add_axis(axis);
    print("ax_id = %\n", ax_id);
    // plot2d(bars(Color.{ 211, 176, 131, 125 }), x, w);
    plot2d(line(BLUE), x, y);
    // plot2d(symbols(), x, z);


    // stop everything
    plot_wait_for_close();
    stop_simulation = true;
    while !thread_is_done(sim) {
        sleep_milliseconds(100);
    }
}