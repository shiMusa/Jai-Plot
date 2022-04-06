

// ########     ###     ######   ########
// ##     ##   ## ##   ##    ##  ##
// ##     ##  ##   ##  ##        ##
// ########  ##     ## ##   #### ######
// ##        ######### ##    ##  ##
// ##        ##     ## ##    ##  ##
// ##        ##     ##  ######   ########

Page_Type :: enum u8 {
    SINGLE;
}
Page :: struct {
    page_rectangle: Rectangle;
    page_type: Page_Type;
    page_title: string;
    activated: bool;
}
activate :: (page: *Page) {
    page.activated = true;
    _plot.active_page = cast(*Page)page;

    if page.page_type == {
        case .SINGLE;
            p := cast(*Page_Single)page;
            activate(p.axis);
    }
}
draw :: (page: *Page) {
    if page.page_type == {
        case .SINGLE;
            p := cast(*Page_Single)page;
            draw(p);
    }
}
intersection_axis :: (page: *Page, pos: Vector2) -> *Axis {
    if page.page_type == {
        case .SINGLE;
            p := cast(*Page_Single)page;
            return cast(*Axis)intersection_axis(p, pos);
    }
}


//  ######  #### ##    ##  ######   ##       ########
// ##    ##  ##  ###   ## ##    ##  ##       ##
// ##        ##  ####  ## ##        ##       ##
//  ######   ##  ## ## ## ##   #### ##       ######
//       ##  ##  ##  #### ##    ##  ##       ##
// ##    ##  ##  ##   ### ##    ##  ##       ##
//  ######  #### ##    ##  ######   ######## ########

Page_Single :: struct {
    using _page: Page;
    axis: *Axis;
}
#scope_export
page_single :: (axis: *Axis, page_title: string = "", activate_axis: bool = true) -> *Page_Single {
    res := New(Page_Single);
    res.page_type = .SINGLE;
    res.page_title = page_title;
    res.activated = false;
    res.axis = axis;

    subscribe(_broadcaster, res, page_single_on_event);

    if activate_axis then activate(axis);

    return res;
}
#scope_module
page_single_on_event :: (page: *Page_Single, event: *Event) {
    if event.event_type == {
        case .PLOT;
            e := cast(*EventPlot)event;
            page.activated = cast(*Page)page == e.page;
            page.axis.activated = page.activated;
    }
}
draw :: (page: *Page_Single) {
    fit_into_rectangle(page.axis, page.page_rectangle);
    draw(page.axis);
}
intersection_axis :: inline (using page: *Page_Single, pos: Vector2) -> *Axis {
    return ifx intersection_axis(axis, pos) then axis else null;
}
