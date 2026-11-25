The label printer runs on a file of `Send` strings that Tinsel recorded years ago. Before the elves replay them through the keyboard robot, they want to know how much typing the robot is in for.

Each line of your input is a Send string, read left to right:

- A letter, digit or space sends that key once.
- `{Name}` sends the named key once, such as `{Enter}` or `{F4}`.
- `{Name N}` sends the named key N times.
- `^`, `!`, `+` and `#` are the modifiers Ctrl, Alt, Shift and Win. A modifier applies only to the next key or brace group and is not a key itself.

```text
hello world{Enter}
^s
+{Tab 3}Ho ho ho
^+{Left 2}{Del}
!{F4}
```

These lines send 12, 1, 11, 3 and 1 keys, for a total of **28**.

**Part 1.** How many keys do all the Send strings send in total?

**Alpha challenge.** Tokenize each line with `RegExReplace` and a callback function (callback support arrived in alpha.1) and write no character-by-character loop.

<!-- part2 -->

**Part 2.** The robot's keycaps are wearing out, so the elves need presses per physical key:

- Letters ignore case: `h` and `H` press the same key. An uppercase letter also presses Shift once.
- Space, each digit and each named key are separate physical keys.
- Each modifier symbol presses its modifier key once, even when the key it modifies repeats. `+{Tab 3}` presses Shift once and Tab three times.
- Your input never puts `+` in front of an uppercase letter.

In the example, `o` takes 5 presses and `h` takes 4. Four keys tie for third with 3 presses each (`l`, Space, Tab and Shift), so the result is 5 x 4 x 3 = **60**.

Multiply together the press counts of the three most-pressed physical keys. What do you get?
