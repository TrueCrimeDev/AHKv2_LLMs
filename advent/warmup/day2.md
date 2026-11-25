The greeting card machine types its messages through a hotstring file. The elves abbreviated everything, then abbreviated the abbreviations, and nobody remembers how long a finished card is.

Your input has two blocks separated by a blank line. The first block defines hotstrings as `::trigger::replacement`. The second block is a single message. Messages and replacements are lowercase words separated by single spaces. A word expands only when the whole word equals a trigger.

```text
::hh::ho ho
::mc::merry christmas
::gm::good morning
::xm::hh mc
::card::gm elves xm

send card to santa hh
```

**Part 1.** The machine makes a single pass over the message and swaps each trigger word for its replacement. It does not look at the replacement text again. The example becomes `send gm elves xm to santa ho ho`, which is **31** characters long, spaces included.

After a single pass, how many characters long is your message?

**Alpha challenge.** Cache expansion lengths with the maybe operators `?`, `??` and `??=` (alpha.2) and call neither `Has` nor `IsSet`.

<!-- part2 -->

**Part 2.** The machine runs a buggy build where hotstrings also fire on text that other hotstrings typed. It keeps expanding until no trigger words remain. No trigger ever leads back to itself, so the machine always stops.

The example ends as `send good morning elves ho ho merry christmas to santa ho ho`, which is **60** characters long.

How many characters long is your fully expanded message? The card will not fit in memory, so plan accordingly.
