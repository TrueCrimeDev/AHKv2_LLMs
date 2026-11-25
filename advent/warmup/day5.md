The last broken system is Tinsel's focus keeper, a macro that shuffles windows with Alt+Tab so the right dashboard sits in front at launch time. Somebody left it on a timer, and it has been running ever since.

Your input has two blocks separated by a blank line. The first block lists the open windows from front to back, each as a hexadecimal window handle followed by its title. The second block is the macro, which runs top to bottom.

In this puzzle, `Send "!{Tab N}"` brings the window N places behind the front window to the front. Every window that was ahead of it moves back by a single place. `!{Tab 1}` swaps the front two windows.

```text
0x1A04 Naughty List.xlsx
0x2B10 Sleigh Telemetry
0x0C7E Cocoa Timer
0x3D52 Reindeer Roster
0x4E09 Elf Chat

Send "!{Tab 2}"
Send "!{Tab 4}"
Send "!{Tab 1}"
```

The three lines bring Cocoa Timer, then Elf Chat, then Cocoa Timer again to the front. The order ends as Cocoa Timer, Elf Chat, Naughty List.xlsx, Sleigh Telemetry, Reindeer Roster.

The checksum of an order is the sum of each window's position multiplied by its handle, where the front window is position 1. Here that is 1 x 3198 + 2 x 19977 + 3 x 6660 + 4 x 11024 + 5 x 15698 = **185718**.

**Part 1.** Run the macro a single time. What is the checksum of the window order?

**Alpha challenge.** Import your Day 4 module, keep each window in a `struct` with a typed handle field, and use no global variables.

<!-- part2 -->

**Part 2.** The timer log shows that the macro has run 1,000,000,000,000 times. For the example, the checksum after a trillion runs is **178794**.

Starting from the original order, what is the checksum after the macro runs 1,000,000,000,000 times?
