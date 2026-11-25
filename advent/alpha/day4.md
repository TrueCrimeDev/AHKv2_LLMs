The sleigh's guidance computer runs on plugins. Twelve elves and reindeer each wrote a plugin, and every one of them picked the same three names for what it exports.

Your input is not data. It is an `.ahk` file of `#Module` sections. Module `Sleigh` holds a variable named `Seed`. Each of the other twelve modules defines `Priority`, `Phase` and `Step(x)`.

The guidance value starts at `Sleigh.Seed`. A round calls `Step` in every plugin exactly once, in ascending `Priority`, and feeds each result into the next call. `Step` also advances its own module's `Phase`, so every plugin carries state from round to round.

```ahk2
#Module Sleigh
global Seed := 100

#Module Dasher
global Priority := 20
global Phase := 0

Step(x) {
    global Phase
    Phase := Mod(Phase + 1, 2)
    return Mod(x * 7 + 3 + Phase, 1009)
}

#Module Vixen
global Priority := 5
global Phase := 1

Step(x) {
    global Phase
    Phase := Mod(Phase + 1, 3)
    return (x & 1) ? Mod(x * 5 + Phase, 1009) : x // 2 + 11
}

#Module Comet
global Priority := 12
global Phase := 0

Step(x) {
    global Phase
    Phase := Mod(Phase + 1, 2)
    return Mod((x ^ 90) + 4 * Phase, 1009)
}
```

In this example the order is Vixen, Comet, Dasher. Round 1 turns 100 into 61, then 107, then 753. Round 2 ends at 839 and round 3 ends at **773**.

**Part 1.** What is the guidance value after 1,000 rounds? (The example's value after 3 rounds is 773.)

**Alpha requirements.** Do not edit, copy, parse or transcribe the input file. Load it with `#Import`, call each `Step` through its module, and read each `Priority` and `Phase` through the module object.

**Left for you to discover.** How to import several modules out of a single file, when each module's body runs and sets its `Phase`, and what a repeated state looks like when part of the state lives inside twelve modules.

<!-- part2 -->

**Part 2.** The sleigh needs the value after 1,000,000,000,000 rounds. For the example, that value is **982**.

What is the guidance value after 1,000,000,000,000 rounds?
