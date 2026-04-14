/*
Alpha23_Example.ahk -- AutoHotkey v2.1-alpha.23 feature showcase

Features demonstrated:
  1. Numeric type classes (Int32, Float32, UInt8, etc.)
  2. Structured array classes via StructClass[N]
  3. Negative indexing on struct arrays
  4. Struct.Prototype.Size fix

Run: bin\AutoHotkey64.exe Alpha23_Example.ahk
*/
#Requires AutoHotkey v2.1-alpha.23

; NUMERIC TYPE CLASSES -- Float32, Int64, UInt16, etc.

; 3D vector with single-precision floats
Struct Vec3f {
    x: Float32
    y: Float32
    z: Float32
}

v := Vec3f()
v.x := 1.5, v.y := 2.7, v.z := -3.14

; Mixed numeric types -- alignment handled automatically
Struct SensorReading {
    timestamp: Int64
    temperature: Float32
    humidity: Float32
    sensor_id: UInt16
    flags: UInt8
}

reading := SensorReading()
reading.timestamp := 1711234567890
reading.temperature := 22.5
reading.humidity := 45.2
reading.sensor_id := 1042
reading.flags := 0x03

; STRUCT ARRAYS -- StructClass[N] syntax

; Primitive typed arrays -- contiguous memory
intArr := Int32[4]()
intArr[1] := 10, intArr[2] := 20, intArr[3] := 30, intArr[4] := 40

; Negative indexing: intArr[-1] is last element
lastVal := intArr[-1]  ; 40

; Float arrays for numerical work
floatArr := Float64[3]()
floatArr[1] := 3.14159
floatArr[2] := 2.71828
floatArr[3] := 1.41421

; Struct arrays -- arrays of user-defined structs
Struct POINT {
    x: i32
    y: i32
}

points := POINT[3]()
points[1].x := 10,  points[1].y := 20
points[2].x := 100, points[2].y := 200
points[3].x := 50,  points[3].y := 150

; Byte buffer for raw data
hashBuf := UInt8[32]()
loop 32
    hashBuf[A_Index] := Mod(A_Index * 17, 256)

; PRACTICAL: GDI color palette

; 256-entry grayscale palette, passable to SetDIBColorTable
Struct RGBQUAD {
    blue: u8
    green: u8
    red: u8
    reserved: u8
}

palette := RGBQUAD[256]()
loop 256
    palette[A_Index].red := palette[A_Index].green := palette[A_Index].blue := A_Index - 1

; SIZE FIX -- returns layout size, not allocation size

Struct SmallPair {
    a: u8
    b: u8
}

pair := SmallPair()
pair.a := 0xFF, pair.b := 0x42

; OUTPUT SUMMARY

stdout := FileOpen("*", "w", "UTF-8")
P(text := "") => stdout.Write(text "`n")

P "=== Alpha.23 Results ==="
P ""
P Format("Vec3f({:.2f}, {:.2f}, {:.2f})  {} bytes", v.x, v.y, v.z, v.Size)
P Format("SensorReading: temp={}, id={}, flags=0x{:02X}  {} bytes",
    reading.temperature, reading.sensor_id, reading.flags, reading.Size)
P ""
P Format("Int32[4]: [{}, {}, {}, {}]  {} bytes, Length={}",
    intArr[1], intArr[2], intArr[3], intArr[4], intArr.Size, intArr.Length)
P Format("  intArr[-1] = {}", lastVal)
P Format("Float64[3]: [{}, {}, {}]  {} bytes",
    floatArr[1], floatArr[2], floatArr[3], floatArr.Size)
P ""
P Format("POINT[3]: {} bytes", points.Size)
loop points.Length
    P Format("  [{}] = ({}, {})", A_Index, points[A_Index].x, points[A_Index].y)
P ""
hexStr := ""
loop 8
    hexStr .= Format("{:02X} ", hashBuf[A_Index])
P Format("UInt8[32]: {}...  ({} bytes)", hexStr, hashBuf.Size)
P ""
P Format("RGBQUAD[256]: {} bytes", palette.Size)
P Format("  [1]=RGB({1},{1},{1})  [128]=RGB({2},{2},{2})  [256]=RGB({3},{3},{3})",
    palette[1].red, palette[128].red, palette[256].red)
P Format("SmallPair: Size={} (layout size, not allocation)", pair.Size)
