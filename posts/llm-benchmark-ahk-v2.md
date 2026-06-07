# Five LLMs Take the AHK v2 Benchmark — Graded by Running the Code

Most "which model writes better code" comparisons end in vibes: you read two
snippets, decide one looks cleaner, and move on. AutoHotkey v2 lets us do better.
Because the language is small and a script can print a single value to stdout, we
can give every model the *same* tiny problem, **run** its answer on the real
AutoHotkey v2 interpreter, and compare the output to a known-correct value. No
human judgment, no cherry-picking — the interpreter is the judge.

This post is the result of doing exactly that across five current flagship
models. It is the companion to the [Opus 4.8 examples](post.html?slug=opus-4.8-examples)
post, which was explicitly *illustrative, not a benchmark*. This one is the
benchmark.

The harness, tasks, and raw results live in
[`bench/`](https://github.com/TrueCrimeDev/AHKv2_LLMs/tree/main/bench).

---

## How it works

Each task is phrased so the answer is one deterministic value. Every model gets
an identical, idiom-free prompt asking for an AHK v2 function named `Solve()`
that returns that value — for example:

> *"Count how often each space-separated word occurs in the sentence "the quick
> brown fox the lazy dog the end", and return the highest occurrence count of
> any single word."* → `3`

The harness wraps each reply with a one-line driver, `FileAppend(String(Solve()), "*")`,
runs it on `AutoHotkey64.exe` (here, under Wine + a virtual display so it works
headless on a Linux box), captures stdout, and compares it to the expected
value. A model can land in three states per task:

- **✅ pass** — stdout matched.
- **❌ wrong** — it ran, but produced the wrong value.
- **⚠️ did not run** — a syntax or runtime error, i.e. it wasn't valid v2 at all.

That last column is the interesting one. A model trained mostly on Python and
JavaScript — or on AutoHotkey **v1** — tends to write code that *looks* right
but trips on a v2-specific rule, and then it doesn't run. The benchmark catches
those automatically.

There are 21 tasks split across two tiers: a universal computation core
(closures, recursion, sorting, regex, maps, bitwise, variadics, formatting) and
a depth tier covering OOP, error handling, and the AHK-specific surface
(`DllCall`, `Buffer`/`NumPut`, file I/O, `DateDiff`).

## The scorecard

| Model | Score |
| :--- | :--: |
| `google/gemini-3.1-pro-preview` | **21 / 21** |
| `openai/gpt-5.5` | **19 / 21** |
| `x-ai/grok-4.20` | **19 / 21** |
| `deepseek/deepseek-v4-pro` | **18 / 21** |
| `meta-llama/llama-4-maverick` | **12 / 21** |

Gemini 3.1 Pro is the only model to clear the whole board. The rest are
separated almost entirely by **v2-specific footguns**, not by algorithmic
ability — every model nailed Fibonacci, Collatz, bit-counting, and `DllCall`.
What follows are the actual mistakes, copied verbatim from the run.

---

## 1. The case-insensitive identifier collision

This is the most instructive failure in the whole set. Here is GPT-5.5's answer
to the stack task — and it is, by the standards of any other language, perfect:

```cpp
class Stack {
    __New() {
        this.items := []
    }
    Push(value) {
        this.items.Push(value)
    }
    Pop() {
        return this.items.Pop()
    }
    Peek() {
        return this.items[this.items.Length]
    }
}

Solve() {
    stack := Stack()
    stack.Push(10)
    stack.Push(20)
    stack.Push(30)
    stack.Pop()
    stack.Pop()
    stack.Push(40)
    return stack.Peek()
}
```

It does not run. The error is *"This local variable has not been assigned a
value."* The culprit: **AHK v2 identifiers are case-insensitive.** The local
variable `stack` and the class `Stack` are the *same name*. Assigning to `stack`
turns that name into a local, so the `Stack()` on the right-hand side no longer
resolves to the class — it's a reference to an unassigned local. Renaming the
local to `s` is the *only* change needed to make it return `40`.

The same trap cost GPT-5.5 the inheritance task too (a local `dog` versus a
class `Dog`). It's a genuinely subtle rule, and a model carries no scar tissue
for it unless it has really absorbed v2.

## 2. Iterating a Map: keys, or key-value pairs?

The `word-frequency` task drew the cleanest split in the benchmark. Compare the
losing and winning loops, both counting with a `Map()`.

Grok 4.20 (⚠️ — *"Expected a Number but got a String"*):

```cpp
max := 0
for count in counts          ; single variable over a Map yields the KEY
    if (count > max)         ; so `count` is a word like "the" -> string > number
        max := count
```

Gemini 3.1 Pro (✅):

```cpp
for _, count in wordCounts   ; two variables -> key, value
    if count > maxCount
        maxCount := count
```

In AHK v2, `for x in someMap` binds `x` to each **key**, not each value. Grok's
loop variable `count` was actually a word, and comparing a string with `>` to a
number throws. Gemini used the two-variable form and got the value. One missing
loop variable is the entire difference between 19/21 and 21/21.

Llama 4 Maverick failed the same task a different way — by inventing an API:

```cpp
for value in count.Values {   ; Map has no `.Values` property in v2
    ...
}
```

`Map` has no `.Values` member in AHK v2. This is the classic "borrowed from
another language's dictionary" mistake, and it fails fast.

## 3. `catch e` is not `catch as e`

DeepSeek V4 Pro's error-handling answer reads naturally if you're coming from
AHK v1 or most other languages:

```cpp
Solve() {
    try
        ThrowBoom()
    catch e                  ; v1 habit: `e` looks like the output variable
        return e.Message
}
```

It doesn't load. In AHK v2, the word after `catch` is an **error class to
filter on**, not the variable to bind. To capture the error object you need the
`as` keyword: `catch Error as e` (or just `catch as e`). Without it, v2 reads
`e` as a class name, can't find it, and rejects the script. The three models
that wrote `catch as e` passed; the ones that wrote `catch e` did not.

## 4. Property syntax, `A_Random`, and other v1-isms

A scattering of failures came from reaching for things that simply aren't in v2:

- **Indexed property where a plain one belongs.** Llama declared
  `Property[] { get => ... }` — the bracketed form is for `__Item`-style indexed
  properties and needs parameters; a plain value property is just `Property { get => ... }`.
- **`A_Random`.** One file built a temp path with `A_Random`, which is not a v2
  built-in variable (v2 exposes randomness through the `Random()` function). The
  reference doesn't resolve and the script stalls.
- **Hallucinated methods.** Across runs we also saw `arr.Sort()` and
  `someInteger.BitCount()` — neither exists in v2. AHK v2 has *no* built-in
  `Array.Sort()`; you implement it or route through the `Sort()` command.
- **`DateDiff` argument shape** and a sign-flipped result (`-155` where `155`
  was expected — right magnitude, dates subtracted the other way).

None of these are reasoning failures. They're knowledge failures, specific to a
language whose rules diverge from the mainstream in small, unforgiving ways.

---

## A note on rigor (and one bug that was ours)

The first run of this benchmark showed *every* model failing *every* OOP task —
a result far too clean to be real. It wasn't. The original prompt said "return
only the function definition", which nudged models to declare their class
**inside** `Solve()`. AHK v2 forbids nesting a class in a function, so the
scripts failed to load — through no fault of the model. The fix was to let the
prompt invite top-level classes and helpers; after that, the OOP columns mostly
turned green and the case-collision failure in §1 stood out as a *real* one.

The lesson cuts both ways: an execution-graded benchmark will faithfully report
your harness's mistakes alongside the models'. When a column looks impossibly
bad, suspect the harness first. Every failure quoted above was re-run by hand to
confirm it's the model's, not ours.

## How to read this

The headline ranking matters less than the failure modes. These are five capable
models; what separates them on AutoHotkey v2 is almost entirely a handful of
language-specific traps — case-insensitive names, key-versus-value iteration,
`catch as`, the absent `Array.Sort()`, `Random()` over `A_Random`. If you
generate AHK v2 with any of them, those are the exact spots to read closely
before you trust the output. And as always: run it. The interpreter is the only
reviewer that can't be talked into a wrong answer.

The full task list, harness, and per-task matrix are in
[`bench/`](https://github.com/TrueCrimeDev/AHKv2_LLMs/tree/main/bench); validate
anything surprising against the [AHK v2 docs](https://www.autohotkey.com/docs/v2/).
