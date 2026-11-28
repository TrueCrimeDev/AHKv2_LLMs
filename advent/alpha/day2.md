The control room's window manager keeps a binary journal of everything that happened to every window. Replaying it should rebuild the screen. Nobody has replayed it correctly yet.

The journal is a `Header` followed by `count` events:

```ahk2
struct Box {
    x : Int16, y : Int16
    w : Int16, h : Int16
}
struct Point {
    x : Int16, y : Int16
}
struct Header {
    count   : UInt16, head    : UInt16
    screenW : UInt16, screenH : UInt16
}

struct Event {
    kind : UInt8
    win  : UInt8
    next : UInt16
    union {
        box   : Box
        pos   : Point
        delta : Int8[4]
        tint  : UInt32
    }
}
```

`kind` says which union member is live and what the event does to window `win`:

| kind | Name | Payload | Effect |
| --: | :-- | :-- | :-- |
| 1 | OPEN | `box` | Opens the window with that box and tint 16777215, on top of every other window. An already open window is replaced and moves to the top. |
| 2 | MOVE | `pos` | Moves the window's top-left corner to `pos`. |
| 3 | NUDGE | `delta` | Adds the four values to x, y, w and h, in that order. |
| 4 | TINT | `tint` | Sets the window's tint. |
| 5 | RAISE | none | Moves the window to the top. |
| 6 | CLOSE | none | Closes the window. |

Kinds 2 through 6 do nothing when the window is not open. A window covers the pixels from (x, y) to (x + w - 1, y + h - 1), clipped to the screen. A window whose w or h is below 1 stays open but covers nothing.

The score of a screen is the sum, over every pixel, of the tint of the topmost window covering it. Bare desktop adds 0.

```text
08000300100008000101040001000100060004000401050005000000DB888B59
010206000400020008000500010200000A00000009000300030101000201FF02
58F872CF0502FFFF1CAECAB01CAF45DD04020200005ED0B2068BE58E06010700
B9564CA9E1B9CD9F
```

This example has 8 events on a screen 16 wide and 8 tall, with `head` = 3:

| Index | Event | next |
| --: | :-- | --: |
| 0 | OPEN window 1, box (1, 1, 6, 4) | 4 |
| 1 | TINT window 1 to 5 | 5 |
| 2 | OPEN window 2, box (4, 2, 8, 5) | 6 |
| 3 | OPEN window 2, box (10, 0, 9, 3) | 0 |
| 4 | NUDGE window 1 by (2, 1, -1, 2) | 1 |
| 5 | RAISE window 2 | 65535 |
| 6 | TINT window 2 to 3000000000 | 2 |
| 7 | CLOSE window 1 | 7 |

**Part 1.** Run every event in file order and ignore `next`. In the example, window 1 ends up closed and window 2 sits at (10, 0) with 18 of its pixels on screen, so the score is 18 x 3000000000 = **54000000000**.

What is the score after running all events in file order?

**Alpha requirements.** Declare `Event` once, with a `union` block, the nested `Box` and `Point` structs and the `Int8[4]` array. Reach each event with `Event.At()`. Call no `NumGet`, and do no offset math beyond `base + index * size`, with the size read from the struct's `Size`.

**Left for you to discover.** How typed array elements are indexed, and what a nested struct property hands back when you read it.

<!-- part2 -->

**Part 2.** The journal is really a linked list. Start at the event whose index is `head`, counting from 0, and follow `next` until it reads 65535. Events off the chain are stale and never run.

The example chain is 3, 0, 4, 1, 5, and it leaves this screen:

```text
..........222222
..........222222
...11111..222222
...11111........
...11111........
...11111........
...11111........
...11111........
```

Window 1 shows 30 pixels of tint 5 and window 2 shows 18 pixels of tint 16777215, for a score of **301990020**.

What is the score after running only the chain?
