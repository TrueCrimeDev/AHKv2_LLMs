; Advent of Hotkeys - Day 4 input
; Every plugin module defines the same three names: Priority, Phase and Step.

#Module Sleigh
global Seed := 530215

#Module Holly
global Priority := 64
global Phase := 5

Step(x) {
    global Phase
    Phase := Mod(Phase + 1, 7)
    return (x & 1) ? Mod(x * 950098 + Phase, 1000003) : x // 2 + 322228
}

#Module Prancer
global Priority := 21
global Phase := 0

Step(x) {
    global Phase
    Phase := Mod(Phase + 1, 7)
    return Mod((x ^ 207773) + 488755 * Phase, 1000003)
}

#Module Tinsel
global Priority := 53
global Phase := 0

Step(x) {
    global Phase
    Phase := Mod(Phase + 1, 3)
    return Mod((x ^ 438971) + 65411 * Phase, 1000003)
}

#Module Cupid
global Priority := 66
global Phase := 2

Step(x) {
    global Phase
    Phase := Mod(Phase + 1, 3)
    return Mod((x ^ 182898) + 134758 * Phase, 1000003)
}

#Module Dancer
global Priority := 29
global Phase := 0

Step(x) {
    global Phase
    Phase := Mod(Phase + 1, 5)
    return Mod(x * x + 400262 + Phase, 1000003)
}

#Module Vixen
global Priority := 14
global Phase := 1

Step(x) {
    global Phase
    Phase := Mod(Phase + 1, 2)
    return (x & 1) ? Mod(x * 452890 + Phase, 1000003) : x // 2 + 472489
}

#Module Ember
global Priority := 81
global Phase := 2

Step(x) {
    global Phase
    Phase := Mod(Phase + 1, 3)
    return Mod(x * 198235 + 59253 + Phase, 1000003)
}

#Module Donner
global Priority := 86
global Phase := 0

Step(x) {
    global Phase
    Phase := Mod(Phase + 1, 3)
    return Mod(x * x + 447697 + Phase, 1000003)
}

#Module Blitzen
global Priority := 50
global Phase := 0

Step(x) {
    global Phase
    Phase := Mod(Phase + 1, 7)
    return (x & 1) ? Mod(x * 8462 + Phase, 1000003) : x // 2 + 419520
}

#Module Nutmeg
global Priority := 45
global Phase := 4

Step(x) {
    global Phase
    Phase := Mod(Phase + 1, 7)
    return Mod(x * 67701 + 298187 + Phase, 1000003)
}

#Module Dasher
global Priority := 6
global Phase := 0

Step(x) {
    global Phase
    Phase := Mod(Phase + 1, 7)
    return Mod(x * 995232 + 168089 + Phase, 1000003)
}

#Module Comet
global Priority := 85
global Phase := 2

Step(x) {
    global Phase
    Phase := Mod(Phase + 1, 3)
    return Mod(x + 137239 * (Phase + 1), 1000003)
}
