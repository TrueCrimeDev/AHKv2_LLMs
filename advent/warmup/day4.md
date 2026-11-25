The route planner keeps the sleigh route in a text file, and Tinsel's editor macro has to walk the caret from the start marker to the end marker. The mouse froze over years ago, so the keyboard is all you have.

Your input is a grid. `#` is a wall, `.` is open, `S` is where the caret starts and `E` is where it must end. Walls surround the whole grid.

```text
###########
#S..#.....#
#.#.#.###.#
#.#...#...#
#.#####.#.#
#.......#E#
###########
```

**Part 1.** Each arrow key moves the caret a single cell up, down, left or right. The caret cannot enter a wall. In the example, the shortest route takes **16** keystrokes.

What is the fewest keystrokes that move the caret from `S` to `E`?

**Alpha challenge.** Put your grid parsing and search code in a module and load it with `#Import`, so that Day 5 can reuse your helpers.

<!-- part2 -->

**Part 2.** You find four more working keys. In this editor, `Home`, `End`, `PgUp` and `PgDn` slide the caret left, right, up and down until the next cell is a wall. A slide costs a single keystroke no matter how far it travels, and it cannot stop early. Sliding across `E` does not count: the caret must come to rest on `E`.

In the example, `PgDn`, `End`, `PgUp`, `End`, `PgDn` lands on `E` in **5** keystrokes.

With all eight keys available, what is the fewest keystrokes that bring the caret to rest on `E`?
