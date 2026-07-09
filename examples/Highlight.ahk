#Requires AutoHotkey v2.1-alpha.24
#SingleInstance Force

Struct Vec3f {
    x: Float32
    y: Float32
    z: Float32
}

v := Vec3f()
v.x := 1.5, v.y := 2.7, v.z := -3.14

Struct SensorReading {
    timestamp: Int64       ; 8 bytes
    temperature: Float32   ; 4 bytes
    humidity: Float32      ; 4 bytes
    sensor_id: UInt16      ; 2 bytes
    flags: UInt8           ; 1 byte
}