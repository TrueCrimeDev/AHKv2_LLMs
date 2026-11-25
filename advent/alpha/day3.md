The wish ledger is a tree of regions, streets, houses and fields, and most of it was never filled in. Tinsel patched the holes with fallbacks, shortcuts and shared branches. The elves need totals out of it anyway.

Your input has two blocks separated by a blank line: statements, then queries.

A path is a list of names joined by dots, such as `north.maple.h1.weight`. A path is unset when any step along it is missing. A path of four names holds an integer. A shorter path holds a branch. A chain is a list of terms joined by `??`, and its value is its first term that is set. Every term is a path except the last, which is an integer or the word `unset`. A chain never mixes integers and branches.

Each statement is `target := chain` or `target ??= chain`:

- `:=` stores the chain's value at the target and creates any missing branches on the way there. When the chain's value is unset, it removes the target instead.
- `??=` does nothing when the target is already set. An empty branch counts as set. Otherwise it behaves like `:=`, except that an unset value changes nothing.
- Storing a branch stores a reference, not a copy, the way AutoHotkey objects behave. Both paths then lead to the same branch, and a change made through either shows through both.
- Removing a path removes that name only. A branch still reachable by another path lives on.

Each query is `@N chain`, and its chain always ends in an integer.

```text
north.maple.h1.weight := 7
north.maple.h1.cocoa ??= 2
south.oak := north.maple ?? unset
south.oak.h1.weight := 9
north.maple.h1.cocoa ??= 5
north.maple := unset
north.maple.h2.soot := south.oak.h1.weight ?? 1
south.oak.h1.bells ??= north.maple.h1.bells ?? unset

@4 north.maple.h1.weight ?? 4
@6 north.maple.h1.weight ?? south.oak.h1.weight ?? 4
@8 south.oak.h1.bells ?? north.maple.h2.soot ?? 0
```

Statement 3 makes `south.oak` and `north.maple` the same branch, so statement 4 changes the weight seen through both. Statement 5 does nothing. Statement 6 removes the name `north.maple`, but `south.oak` still reaches the branch. Statement 7 builds a fresh `north.maple`. Statement 8 finds nothing to store.

**Part 1.** Ignore the `@N` tags. Run every statement, then evaluate every query. The example's queries give 4, 9 and 9, for a total of **22**.

What is the sum of all query values?

**Alpha requirements.** Run in v2.1 mode. Do every lookup with `?.`, `?` and `??`, every conditional store with `??=`, and every removal by assigning `unset`. Call none of `Has`, `HasProp`, `HasOwnProp`, `IsSet`, `Delete`, `DeleteProp`, and write no `try`.

**Left for you to discover.** Exactly which step of `a?.b.c` may be unset, and where a trailing `?` is allowed.

<!-- part2 -->

**Part 2.** The tags matter. Evaluate each query against the ledger as it stood right after statement N ran, counting statements from 1. The example's queries now give 9, 9 and 9, for a total of **27**.

What is the sum of all query values, each taken at its own moment?
