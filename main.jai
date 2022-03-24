#import "Basic";
#load "Plot.jai";



simulation :: (_thread: *Thread = null) -> s64 {

    for *x {
        <<it = -10.0 + 20.0 * (cast(float32)it_index/cast(float32)(N-1));
    }

    t0 := GetTime();
    while !stop_simulation {
        t := GetTime() - t0;

        for i: 0..N-1 {
            y[i] =  Math.sin(cast(float32)(t/10.0 * PI) + x[i]/5.0 * cast(float32)PI);
            z[i] =  Math.cos(cast(float32)(t/10.0 * PI) + x[i]/5.0 * cast(float32)PI);
            w[i] = -Math.sin(cast(float32)(t/10.0 * PI) + x[i]/5.0 * cast(float32)PI);
        }


        for i: 0..36+1-1 {
            vx[i] = 1.5 * Math.sin(cast(float32)(t/20.0 * PI) + cast(float32)(i/36.0 * 2.0 * PI));
            vy[i] = 1.5 * Math.cos(cast(float32)(t/20.0 * PI) + cast(float32)(i/36.0 * 2.0 * PI));
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

vx : [36+1]float32;
vy : [36+1]float32;

main :: () {
    print("Hello World\n");




    plot();
    axis := cartesian_axis_2d();
    // set_min_max(*axis.x_mapper, -10.0, 10.0);
    // set_min_max(*axis.y_mapper, -2.0, 2.0);
    // set_scale(*axis.x_mapper, scale = 100.0);
    // set_scale(*axis.y_mapper, scale = 100.0);
    ax_id := add_axis(axis);
    plot2d(bars(Color.{ 211, 176, 131, 125 }), x, w);
    plot2d(line(BLUE), x, y);
    plot2d(multi(symbols(RAYWHITE, 6.0), symbols()), x, z);

    plot2d(multi(line(SKYBLUE, 4.0), symbols(SKYBLUE, 8.0), symbols(GOLD, 5.0)), vx, vy);
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