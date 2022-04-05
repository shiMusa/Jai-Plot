#load "raylib.jai";

LIGHTGREY  :: LIGHTGRAY;
GREY       :: GRAY;
DARKGREY   :: DARKGRAY;
TRANSPARENT :: Color.{255,255,255,0};



render_to_texture :: (width: s32, height: s32, $render_code: Code) -> RenderTexture2D #expand {
    tex := LoadRenderTexture(width, height);
    TextureMode(tex, render_code);
    return tex;
}





Window :: (width: s32, height: s32, title: string) #expand {
    cstr := to_c_string(title);
    `defer free(cstr);
    InitWindow(width, height, cstr);
    `defer CloseWindow();
}

TextureMode :: (target: RenderTexture2D) #expand {
    BeginTextureMode(target);
    `defer EndTextureMode();
}
TextureMode :: (target: RenderTexture2D, code: Code) #expand {
    BeginTextureMode(target);
    #insert code;
    EndTextureMode();
}

Drawing :: () #expand {
    BeginDrawing();
    `defer EndDrawing();
}

Mode2D :: (camera: Camera2D) #expand {
    BeginMode2D(camera);
    `defer EndMode2D();
}

Mode2D :: (camera: Camera2D, code: Code) #expand {
    BeginMode2D(camera);
    #insert code;
    EndMode2D();
}

DrawText :: (text: string, posx: s32, posy: s32, fontSize: s32, color: Color) {
    cstr := to_c_string(text);
    defer free(cstr);

    DrawText(cstr, posx, posy, fontSize, color);
}

MeasureText :: (text: string, font_size: s32) -> s32 {
    cstr := to_c_string(text);
    defer free(cstr);

    return MeasureText(cstr, font_size);
}

DrawLineStrip :: inline (points: []Vector2, color: Color) {
    DrawLineStrip(points.data, cast(s32)points.count, color);
}

DrawLines :: (points: []Vector2, color: Color, thickness: float = 1.0) {
    for i: 0..points.count-2 {
        DrawLineEx(points[i], points[i+1], thickness, color);
    }
}

camera2d :: (offset:=Vector2.{0.0,0.0}, target:=Vector2.{0.0,0.0}, rotation:=0.0, zoom:=1.0) -> Camera2D {
    res: Camera2D = ---;
    res.offset = offset;
    res.target = target;
    res.rotation = rotation;
    res.zoom = zoom;
    return res;
}


rectangle :: (x: $X, y: $Y, width: $W, height: $H) -> Rectangle {
// rectangle :: inline (x: float32, y: float32, width: float32, height: float32) -> Rectangle {
    res : Rectangle = ---;
    res.x      = cast(float32)x;
    res.y      = cast(float32)y;
    res.width  = cast(float32)width ;
    res.height = cast(float32)height;
    return res;
}


vec2 :: inline (x: $T, y: $U) -> Vector2 {
    return vec2(cast(float32)x, cast(float32)y);
}
vec2 :: (x:float=0.0, y:float=0.0) -> Vector2 {
    res : Vector2 = ---;
    res.x = x;
    res.y = y;
    return res;
}
vec3 :: (x:float=0.0, y:float=0.0, z:float=0.0) -> Vector3 {
    res : Vector3 = ---;
    res.x = x;
    res.y = y;
    res.z = z;
    return res;
}
vec4 :: (x:float=0.0, y:float=0.0, z:float=0.0, w:float=0.0) -> Vector4 {
    res : Vector4 = ---;
    res.x = x;
    res.y = y;
    res.z = z;
    res.w = w;
    return res;
}
color :: (r:u8=0, g:u8=0, b:u8=0, a:u8=255) -> Color {
    res : Color = ---;
    res.r = r;
    res.g = g;
    res.b = b;
    res.a = a;
    return res;
}
operator + :: (a: Vector2, b: Vector2) -> Vector2 {
    res : Vector2 = ---;
    res.x = a.x + b.x;
    res.y = a.y + b.y;
    return res;
}
operator - :: (a: Vector2, b: Vector2) -> Vector2 {
    res : Vector2 = ---;
    res.x = a.x - b.x;
    res.y = a.y - b.y;
    return res;
}
operator + :: (a: Vector3, b: Vector3) -> Vector3 {
    res : Vector3 = ---;
    res.x = a.x + b.x;
    res.y = a.y + b.y;
    res.z = a.z + b.z;
    return res;
}
operator - :: (a: Vector3, b: Vector3) -> Vector3 {
    res : Vector3 = ---;
    res.x = a.x - b.x;
    res.y = a.y - b.y;
    res.z = a.z - b.z;
    return res;
}
operator + :: (a: Vector4, b: Vector4) -> Vector4 {
    res : Vector4 = ---;
    res.x = a.x + b.x;
    res.y = a.y + b.y;
    res.z = a.z + b.z;
    res.w = a.w + b.w;
    return res;
}
operator - :: (a: Vector4, b: Vector4) -> Vector4 {
    res : Vector4 = ---;
    res.x = a.x - b.x;
    res.y = a.y - b.y;
    res.z = a.z - b.z;
    res.w = a.w - b.w;
    return res;
}

operator + :: (a: Color, b: Color) -> Color {
    res : Color = ---;
    res.r = a.r + b.r;
    res.g = a.g + b.g;
    res.b = a.b + b.b;
    res.a = a.a + b.a;
    return res;
}
operator - :: (a: Color, b: Color) -> Color {
    res : Color = ---;
    res.r = a.r - b.r;
    res.g = a.g - b.g;
    res.b = a.b - b.b;
    res.a = a.a - b.a;
    return res;
}
operator * :: (a: Color, b: float) -> Color #symmetric {
    res : Color = ---;
    res.r = cast(u8)(a.r * b);
    res.g = cast(u8)(a.g * b);
    res.b = cast(u8)(a.b * b);
    res.a = cast(u8)(a.a * b);
    return res;
}
operator / :: (a: Color, b: float) -> Color {
    res : Color = ---;
    res.r = cast(u8)(a.r / b);
    res.g = cast(u8)(a.g / b);
    res.b = cast(u8)(a.b / b);
    res.a = cast(u8)(a.a / b);
    return res;
}

operator * :: (a: Vector2, b: float) -> Vector2 #symmetric {
    res : Vector2 = ---;
    res.x = a.x * b;
    res.y = a.y * b;
    return res;
}
operator / :: (a: Vector2, b: float) -> Vector2 {
    res : Vector2 = ---;
    res.x = a.x / b;
    res.y = a.y / b;
    return res;
}
operator * :: (a: Vector3, b: float) -> Vector3 #symmetric {
    res : Vector3 = ---;
    res.x = a.x * b;
    res.y = a.y * b;
    res.z = a.z * b;
    return res;
}
operator / :: (a: Vector3, b: float) -> Vector3 {
    res : Vector3 = ---;
    res.x = a.x / b;
    res.y = a.y / b;
    res.z = a.z / b;
    return res;
}
operator * :: (a: Vector4, b: float) -> Vector4 #symmetric {
    res : Vector4 = ---;
    res.x = a.x * b;
    res.y = a.y * b;
    res.z = a.z * b;
    res.w = a.w * b;
    return res;
}
operator / :: (a: Vector4, b: float) -> Vector4 {
    res : Vector4 = ---;
    res.x = a.x / b;
    res.y = a.y / b;
    res.z = a.z / b;
    res.w = a.w / b;
    return res;
}