
TextFont_Types :: enum u8 {
    ROMAN;
    MONO;
    SANS;
}

TextFont_Info :: struct {
    type: TextFont_Types;
    font_size: int;
}
textfont_info :: (type: TextFont_Types, font_size: int) -> TextFont_Info {
    res : TextFont_Info = ---;
    res.type = type;
    res.font_size = font_size;
    return res;
}


TextFont :: struct {
    using _tfi: TextFont_Info;
    font: Font;
}
textfont :: (type: TextFont_Types, font_size: int, font: Font) -> TextFont {
    res: TextFont = ---;
    res._tfi = textfont_info(type, font_size);
    res.font = font;
    return res;
}



FONT_LARGE   :: 42;
FONT_DEFAULT :: 24;
FONT_SMALL   :: 18;
_fonts         : [..]TextFont;
_font_creation : [..]TextFont_Info;

init_fonts :: () {
    _fonts = NewResizableArray(20, TextFont, false);

    m := ifx _plot.highdpi then 2 else 1;
    font : Font = ---; 
    
    font = LoadFontExJai("../fonts/lmroman8-regular.otf", FONT_SMALL*m);
    SetTextureFilter(font.texture, xx TextureFilter.BILINEAR);
    array_add(*_fonts, textfont(.ROMAN, FONT_SMALL, font));
    font = LoadFontExJai("../fonts/lmmono8-regular.otf", FONT_SMALL*m);
    SetTextureFilter(font.texture, xx TextureFilter.BILINEAR);
    array_add(*_fonts , textfont(.MONO, FONT_SMALL, font));
    font = LoadFontExJai("../fonts/lmsans8-regular.otf", FONT_SMALL*m);
    SetTextureFilter(font.texture, xx TextureFilter.BILINEAR);
    array_add(*_fonts , textfont(.SANS, FONT_SMALL, font));
    print("small fonts generated\n");

    font = LoadFontExJai("../fonts/lmroman12-regular.otf", FONT_DEFAULT*m);
    SetTextureFilter(font.texture, xx TextureFilter.BILINEAR);
    array_add(*_fonts, textfont(.ROMAN, FONT_DEFAULT, font));
    font = LoadFontExJai("../fonts/lmmono12-regular.otf", FONT_DEFAULT*m);
    SetTextureFilter(font.texture, xx TextureFilter.BILINEAR);
    array_add(*_fonts , textfont(.MONO, FONT_DEFAULT, font));
    font = LoadFontExJai("../fonts/lmsans10-regular.otf", FONT_DEFAULT*m);
    SetTextureFilter(font.texture, xx TextureFilter.BILINEAR);
    array_add(*_fonts , textfont(.SANS, FONT_DEFAULT, font));
    print("default fonts generated\n");

    font = LoadFontExJai("../fonts/lmroman17-regular.otf", FONT_LARGE*m);
    SetTextureFilter(font.texture, xx TextureFilter.BILINEAR);
    array_add(*_fonts, textfont(.ROMAN, FONT_LARGE, font));
    font = LoadFontExJai("../fonts/lmmono12-regular.otf", FONT_LARGE*m);
    SetTextureFilter(font.texture, xx TextureFilter.BILINEAR);
    array_add(*_fonts , textfont(.MONO, FONT_LARGE, font));
    font = LoadFontExJai("../fonts/lmsans10-regular.otf", FONT_LARGE*m);
    SetTextureFilter(font.texture, xx TextureFilter.BILINEAR);
    array_add(*_fonts , textfont(.SANS, FONT_LARGE, font));
    print("large fonts generated\n");
}

update_fonts :: () {
    // print("there are % fonts scheduled for creation\n", _font_creation.count);
    m := ifx _plot.highdpi then 2 else 1;

    for _font_creation {
        font : Font;

        if it.type == {
            case .ROMAN;
                font = LoadFontExJai("../fonts/lmroman17-regular.otf", it.font_size*m);
            case .MONO;
                font = LoadFontExJai("../fonts/lmmono12-regular.otf", it.font_size*m);
            case .SANS;
                font = LoadFontExJai("../fonts/lmsans10-regular.otf", it.font_size*m);
        }
        
        SetTextureFilter(font.texture, xx TextureFilter.BILINEAR);
        res := textfont(it.type, it.font_size, font);


        inserted := false;
        for f, fi: _fonts {
            if f.font_size > it.font_size {
                array_insert_at(*_fonts, res, fi);
                inserted = true;
                break;
            }
        }
        if !inserted then
            array_add(*_fonts, res);
    }
    array_reset(*_font_creation);
}

get_font :: (font_type: TextFont_Types, font_size: int) -> bool, Font {
    schedule :: () #expand {
        found := false;
        for _font_creation {
            if it.type == font_type && it.font_size == font_size {
                found = true;
                break;
            }
        }
        if found then {
            print("textfont %, % already scheduled.\n", font_type, font_size);
            `return false, Font.{};
        }

        array_add(*_font_creation, textfont_info(font_type, font_size));
    }

    if _fonts.count == 0 {
        print("first font in array\n");
        schedule();
    }

    for _fonts {
        if it.font_size == font_size && it.type == font_type then
            return true, it.font;

        if it.font_size > font_size && it.type == font_type {
            print("loading new font, since it.font_size = % > font_size = % || it_index = % == _fonts.count-1 = %\n", it.font_size, font_size, it_index, _fonts.count-1);
            schedule();
        }
    }

    print("no font of size % or larger found, so schedule\n", font_size);
    schedule();
}


measure_text_regular :: inline (msg: string, font_size: int = 12) -> Vector2 {
    return measure_text(.ROMAN, msg, font_size);
}
draw_text_regular :: inline (msg: string, position: Vector2, font_size: int = 12, color := BLACK) -> Vector2 {
    draw_text(.ROMAN, msg, position, font_size, color);
}
measure_text_mono :: inline (msg: string, font_size: int = 12) -> Vector2 {
    return measure_text(.MONO, msg, font_size);
}
draw_text_mono :: inline (msg: string, position: Vector2, font_size: int = 12, color := BLACK) -> Vector2 {
    draw_text(.MONO, msg, position, font_size, color);
}
measure_text_sans :: inline (msg: string, font_size: int = 12) -> Vector2 {
    return measure_text(.SANS, msg, font_size);
}
draw_text_sans :: inline (msg: string, position: Vector2, font_size: int = 12, color := BLACK) -> Vector2 {
    draw_text(.SANS, msg, position, font_size, color);
}

measure_text :: (font_type: TextFont_Types, msg: string, font_size: int = 12) -> Vector2 {
    assert(font_size > 0);

    ok, font := get_font(font_type, font_size);
    if ok then 
        return MeasureTextExJai(font, msg, cast(float32)font_size, 0.0);
    else
        return vec2();
}
draw_text :: (font_type: TextFont_Types, msg: string, position: Vector2, font_size: int = 12, color := BLACK) {
    assert(font_size > 0);

    ok, font := get_font(font_type, font_size);
    if ok then 
        DrawTextExJai(font, msg, position, font_size, 0.0, color);
}
