#import "Basic";
Math :: #import "Math";
#import "Jai-Plot";



simulation :: () {
    for *x {
        <<it = 100.0 * (cast(float32)it_index/cast(float32)(N-1));
    }
    x2[0] = x[0];
    for i: 1..N-1 {
        x2[i] = cast(float32)i/cast(float32)N * (x[i] - x[i-1]) + x[i-1];
    }
    for *u {
        // <<it = Math.sin(cast(float32)it_index/cast(float32)(N-1) * 4.0 * 2.0*cast(float32)PI);
        // <<it = 0.5;
        <<it = -1.0 + cast(float32)it_index/cast(float32)(N-1) * 2.0;
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

            y2[i] = y[i] + 0.6;
            y_shift[i] =  1.25 * Math.sin(cast(float32)(t/10.0 * PI) + (x[i] + 2.0)/5.0 * cast(float32)PI);
            y_err_pos[i] = y[i] + 0.2 * Math.abs(z[i]);
            y_err_neg[i] = y[i] - 0.2 * Math.abs(w[i]);
            x_err_pos[i] = x[i] + 0.2 * Math.abs(y[i]);
            x_err_neg[i] = x[i] - 0.2 * Math.abs(y_shift[i]);
        }


        for i: 0..K+1-1 {
            dt := cast(float32)(Math.sin(t/3.0 * PI + i/cast(float32)K * 6*PI) * (45.0/3.0)/180.0 * PI);
            vx[i] = 1.5 * Math.sin(cast(float32)(t/20.0 * PI) + dt + cast(float32)(i/cast(float32)K * 2.0 * PI));
            vy[i] = 1.5 * Math.cos(cast(float32)(t/20.0 * PI) + dt + cast(float32)(i/cast(float32)K * 2.0 * PI));
        }


        for i:0..17-1 {
            ccx[i] = 1.5 * Math.sin(cast(float32)i/16 * 2.0 * cast(float32)PI);
            ccy[i] = 1.5 * Math.cos(cast(float32)i/16 * 2.0 * cast(float32)PI);

            ccx[i] += cast(float32)( 4.0 * Math.sin(t/5.0 * PI) );
            ccy[i] += cast(float32)( 4.0 * Math.cos(t/5.0 * PI) );
        }

        for x:0..H-1 {
            for y:0..H-1 {
                vx := 1.0/H*x * 2.0 * PI + t/10.0 * 2.0 * PI;
                vy := 1.0/H*y * 2.0 * PI + t/7.0 * 2.0 * PI;
                heat[x + H*y] = cast(float32)Math.abs( Math.sin(vx) * Math.sin(vy) );
            }
        }

        sleep_milliseconds(10);
    }
}


stop_simulation : bool = false;

N :: 201;
NP :: 20;
x : [N]float32;
x2 : [N]float32;
y : [N]float32;
y2 : [N]float32;
y_shift : [N]float32;
y_err_pos : [N]float32;
y_err_neg : [N]float32;
x_err_pos : [N]float32;
x_err_neg : [N]float32;
z : [N]float32;
w : [N]float32;
u : [N]float32;

K :: 48;
vx : [K+1]float32;
vy : [K+1]float32;
cx : [361]float32;
cy : [361]float32;
ccx : [17]float32;
ccy : [17]float32;

H :: 64;
heat : [H*H]float32;

main :: () {

    plot(highdpi=true, callback= ()=>{ stop_simulation = true; } );

    {
        x_mapper := mapper_1d_constraint(mapper_1d_logarithmic(), min_x =  0.1, max_x = 100.0);
        y_mapper := mapper_1d_constraint(mapper_1d_linear()     , min_x = -2.0, max_x =   2.0);
        add_page(page_single(axis_2d_cartesian(x_mapper, y_mapper, "waves")));

        plot2d(bars(x,w,transparency(BEIGE, 0.5)));
        plot2d(multi(
            line(x,y,RAYWHITE, 6.0), 
            line(x,y,BLUE)
        ));
        plot2d(multi(
            symbols(x,z,color=RAYWHITE, size=6.0), 
            symbols(x,z,.X), 
            symbols(x,z,size=3.0)
        ));
    }

    {
        x_mapper := mapper_1d_constraint(mapper_1d_linear(), min_x =  0.0, max_x = 100.0);
        y_mapper := mapper_1d_constraint(mapper_1d_linear(), min_x = -2.0, max_x =   2.0);
        add_page(page_single(axis_2d_cartesian(x_mapper, y_mapper, "fills")));

        plot2d(multi(
            fill(x,y,y2,color=SKYBLUE), 
            symbols(x,y2,color=BLUE),
            symbols(x,y2,size=2.0,color=RAYWHITE)
        ));

        plot2d(multi(
            fill(x,y,y_shift,color=transparency(BEIGE, 0.5)), 
            symbols(x,y_shift,color=BROWN),
            symbols(x,y_shift,size=2.0,color=RAYWHITE)
        ));
    }

    {
        x_mapper := mapper_1d_constraint(mapper_1d_linear(), min_x = -2.0, max_x = 2.0);
        y_mapper := mapper_1d_constraint(mapper_1d_linear(), min_x = -2.0, max_x = 2.0);
        add_page(page_single(
            axis_2d_cartesian(x_mapper, y_mapper, x_label="x axis", y_label="y axis"), 
            "circle"
        ));

        plot2d(line(cx,cy, SKYBLUE, 4.0));
        plot2d(multi(
            symbols(vx,vy, .SQUARE, color=RAYWHITE, size=8.0), 
            symbols(vx,vy, .SQUARE, color=SKYBLUE, size=6.0), 
            symbols(vx,vy, .PLUS, color=GOLD, size=8.0)
        ));
    }


    {
        add_page(page_single(axis_2d_cartesian(title="bars and boxes"), "bars"));

        plot2d(multi(
            bars(ccx, ccy, ORANGE),
            symbols(ccx, ccy),
            symbols(ccx, ccy, size=2.0, color=RAYWHITE)
        ));
        plot2d(multi(
            bars(ccy, ccx, SKYBLUE, .CONNECTED),
            symbols(ccy, ccx, color=BLUE),
            symbols(ccy, ccx, size=2.0, color=RAYWHITE)
        ));
        plot2d(boxes(x, y, x2, y2, SKYBLUE));
    }

    {
        add_page(page_single(axis_2d_cartesian(
            mapper_1d_constraint(mapper_1d_linear(), min_x=-1.0, max_x=10.0),
            mapper_1d_constraint(mapper_1d_linear(), min_x=-3.0, max_x=3.0),
            title="error bars"
        ), "errors"));

        plot2d(multi(
            line(x, y, color=BLACK),
            error_bars(x, y_err_neg, y_err_pos, thickness=2.0),
            error_bars(y, x_err_neg, x_err_pos, y_error=false, thickness=2.0, color=BLUE),
            symbols(x, y),
            symbols(x, y, size=2.0, color=RAYWHITE)
        ));
    }

    {
        add_page(page_single(axis_2d_cartesian(
            mapper_1d_constraint(mapper_1d_linear(), min_x=0.0, max_x=1.0),
            mapper_1d_constraint(mapper_1d_linear(), min_x=0.0, max_x=1.0),
            title="heatmap"
        ), "heatmap"));

        plot2d(heatmap(rectangle(0,0,1,1), H, H, heat, GRADIENT_BLUE_RED));
    }


    {
        add_page(page_single(axis_2d_polar(), "polar map"));

        N := 360*2+1;
        angle  := NewArray(N, float32);
        radius := NewArray(N, float32);
        for i:0..N-1 {
            angle[i]  = cast(float32)i/(N-1) * 2.0 * PI32;
            tmp := Math.cos(angle[i]*7.0/2.0);
            radius[i] = tmp*tmp;
        }

        plot2d(line(angle, radius));
    }

    simulation();

    plot_wait_for_close();
}