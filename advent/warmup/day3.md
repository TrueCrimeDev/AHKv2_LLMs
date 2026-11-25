A runaway startup script opened 150 windows on the control room monitor, which is still 800 pixels wide and 600 pixels tall. The elves can barely find the desktop.

Each line of your input is `WinMove X, Y, W, H`. It places a window whose top-left pixel is (X, Y) and which is W pixels wide and H pixels tall. The top-left pixel of the screen is (0, 0). Line N belongs to window ID N, counting from 1. The script ran top to bottom, so each window draws on top of every window listed before it. Every window fits fully on the screen.

This example uses a tiny screen, 12 wide and 8 tall:

```text
WinMove 1, 1, 5, 4
WinMove 4, 2, 6, 3
WinMove 0, 5, 3, 3
WinMove 2, 3, 4, 4
```

Drawn with each pixel showing the ID of its topmost window and `.` for bare desktop:

```text
............
.11111......
.111222222..
.144442222..
.144442222..
334444......
334444......
333.........
```

**Part 1.** How many pixels of desktop are still visible? In the example, **49** pixels show no window.

**Alpha challenge.** Model each window as a `struct` (alpha.22) and hold the screen in a typed array class such as `UInt8[N]` (alpha.23) in place of an Array of Arrays.

<!-- part2 -->

**Part 2.** A window's visible pixels are the pixels where it is the topmost window. In the example, windows 1 through 4 show 10, 14, 7 and 16 pixels. Window 4 shows the most, so the result is 4 x 16 = **64**.

Find the window with the most visible pixels. What is its ID multiplied by its visible pixel count?
