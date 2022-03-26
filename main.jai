#import "Basic";
#load "Plot.jai";



simulation :: (_thread: *Thread = null) -> s64 {

    for *x {
        <<it = -10.0 + 20.0 * (cast(float32)it_index/cast(float32)(N-1));
    }

    for i:0..361-1 {
        cx[i] = 1.5 * Math.sin(cast(float32)i/360 * 2.0 * cast(float32)PI);
        cy[i] = 1.5 * Math.cos(cast(float32)i/360 * 2.0 * cast(float32)PI);
    }

    t0 := GetTime();
    while !stop_simulation {
        t := GetTime() - t0;

        for i: 0..N-1 {
            y[i] =  1.25 * Math.sin(cast(float32)(t/10.0 * PI) + x[i]/5.0 * cast(float32)PI);
            z[i] =  0.8  *  Math.cos(cast(float32)(t/13.0 * PI) + x[i]/7.0 * cast(float32)PI);
            w[i] = -1.0  * Math.sin(cast(float32)(t/16.0 * PI) + x[i]/4.0 * cast(float32)PI);
        }


        for i: 0..K+1-1 {
            dt := cast(float32)(Math.sin(t/3.0 * PI + i/cast(float32)K * 6*PI) * (45.0/3.0)/180.0 * PI);
            vx[i] = 1.5 * Math.sin(cast(float32)(t/20.0 * PI) + dt + cast(float32)(i/cast(float32)K * 2.0 * PI));
            vy[i] = 1.5 * Math.cos(cast(float32)(t/20.0 * PI) + dt + cast(float32)(i/cast(float32)K * 2.0 * PI));
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

K :: 48;
vx : [K+1]float32;
vy : [K+1]float32;
cx : [361]float32;
cy : [361]float32;

main :: () {

    plot(highdpi=true);
    x_mapper := mapper_constraint(mapper_linear(), min_x = -10.0, max_x = 10.0);
    y_mapper := mapper_constraint(mapper_linear(), min_x = -2.0, max_x = 2.0);
    // x_mapper := mapper_constraint(mapper_linear(), min_x = -5.0, max_x = 5.0, min_y = 0.0, max_y = 1000.0);
    // y_mapper := mapper_constraint(mapper_linear(), min_x = -5.0, max_x = 5.0, min_y = 0.0, max_y = 1000.0);
    axis := cartesian_axis_2d(x_mapper, y_mapper);
    ax_id := add_axis(axis);
    plot2d(bars(Color.{ 211, 176, 131, 125 }), x, w);
    plot2d(multi(line(RAYWHITE, 6.0), line(BLUE)), x, y);
    plot2d(multi(symbols(color=RAYWHITE, size=6.0), symbols(.X), symbols(size=3.0)), x, z);

    plot2d(line(SKYBLUE, 4.0), cx, cy);
    plot2d(multi(
        symbols(.SQUARE, color=RAYWHITE, size=8.0), 
        symbols(.SQUARE, color=SKYBLUE, size=6.0), 
        symbols(.PLUS, color=GOLD, size=8.0)
    ), vx, vy);
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