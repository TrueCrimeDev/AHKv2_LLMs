# One Expression, Five Node Types: A Harder AHK v2 Benchmark

The clipboard benchmark graded a GUI. GUIs are forgiving — a model can ship overlapping controls, skip the dark theme, botch the undo stack, and still *look* like it did the job in a screenshot. I wanted the opposite: a problem with nowhere to hide. Pure logic, one exact answer per input, graded by a machine that doesn't care how pretty the code is. And one that can't be solved without **real inheritance** — not as decoration, but as the load-bearing structure of the solution.

So the next benchmark problem is an **arithmetic expression evaluator**: parse a string like `2 + 3 * sqrt(16)` into an abstract syntax tree of node objects, then evaluate the tree. Then, writing the grader for it, I fell straight into the exact AutoHotkey trap the benchmark exists to catch. More on that below — it's the best part.

<style>
.xb-trap{background:#121212;border:1px solid #303030;border-left:3px solid #DC3545;border-radius:6px;padding:14px 18px;margin:20px 0;}
.xb-trap b{color:#e3969d;}
.xb-win{background:#121212;border:1px solid #303030;border-left:3px solid #7BC96F;border-radius:6px;padding:14px 18px;margin:20px 0;}
.xb-win b{color:#aee0a3;}
.xb-tests{width:100%;border-collapse:collapse;font-size:13.5px;margin:14px 0;}
.xb-tests th{background:#161616;color:#808080;font-size:11px;text-transform:uppercase;letter-spacing:.8px;padding:9px 10px;border-bottom:1px solid #303030;text-align:left;}
.xb-tests td{padding:7px 10px;border-bottom:1px solid #1a1a1a;color:#c4c4c4;}
.xb-tests td.r{color:#fff;font-family:'JetBrains Mono',monospace;}
.xb-tests tr:hover td{background:#161616;}
.xb-note{color:#7BC96F;}
</style>

## Why pure logic, and why inheritance

The model already had a great pure-logic reference in this repo: a compact `argparse` port — a two-stage parser (a spec reader, then an argv state machine) in a couple hundred lines. It's a fine benchmark shape. But it has *zero* inheritance: it's all static methods over `Map`s. A model can ace it without ever defining a class hierarchy.

An expression evaluator keeps `argparse`'s compact two-stage structure — tokenizer, then a recursive-descent parser — but the parser's *output* is a tree of polymorphic objects instead of a flat `Map`. That single change makes inheritance unavoidable. Each kind of syntax node knows how to evaluate itself:

```ahk2
class Node {
    Eval(env) {
        throw Error("Node.Eval is abstract and must be overridden")
    }
}

class NumNode extends Node {
    __New(val) => this.val := val
    Eval(env) => this.val
}

class BinNode extends Node {
    __New(op, left, right) {
        this.op := op
        this.left := left
        this.right := right
    }
    Eval(env) {
        a := this.left.Eval(env), b := this.right.Eval(env)
        switch this.op {
            case "+": return a + b
            case "-": return a - b
            case "*": return a * b
            case "/":
                if (b = 0)
                    throw Error("Division by zero")
                return a / b
            case "%":
                if (b = 0)
                    throw Error("Modulo by zero")
                return Mod(a, b)
            case "^": return a ** b
        }
    }
}
```

`NumNode`, `VarNode`, `UnaryNode`, `BinNode`, `CallNode` — five concrete classes, each overriding one abstract method. A `BinNode` recurses into its children; a `CallNode` evaluates its arguments and dispatches to a built-in. There's no `abstract` keyword in AHK, so the base `Node` *simulates* one by throwing — a small thing that weeds out models which don't understand why the base exists at all.

The tell I'm watching for: weak models collapse the whole thing into one recursive function that returns numbers, with a `switch` on a string "type" tag. It works, sometimes — and it scores worse, because it skips the structure the problem is actually about.

## The part that's hard even in Python

Before any AHK-specific trouble, expression evaluation has two precedence traps that models get wrong in *every* language:

<table class="xb-tests">
<tr><th>Input</th><th>Correct</th><th>The wrong answer models give</th></tr>
<tr><td class="r">2 ^ 2 ^ 3</td><td class="r">256</td><td><code>^</code> is right-associative: <code>2 ^ (2 ^ 3)</code>. Left-assoc gives 64.</td></tr>
<tr><td class="r">-3 ^ 2</td><td class="r">-9</td><td>Unary minus binds looser than <code>^</code>: <code>-(3 ^ 2)</code>. Naive parsers give 9.</td></tr>
<tr><td class="r">2 ^ -1</td><td class="r">0.5</td><td>Unary on the right of a power. Parsers that forbid it throw.</td></tr>
</table>

Getting these right means a real grammar with the precedence levels ordered correctly and the `^` rule recursing on the *right*. You can't bluff it with a flat operator loop.

## The grader fell into its own trap

Here's the honest bit. The whole premise of this benchmark is that AutoHotkey has a few sharp edges LLMs reliably cut themselves on. The sharpest is this: **AHK identifiers are case-insensitive**, so a variable named the same as its class — even with different casing — *is the same name*, and shadows the class.

I wrote the grader. It constructs the evaluator and runs 50 tests against it. My first line of the runner:

```ahk2
calc := Calc()        ; looks fine. it is not fine.
```

<div class="xb-trap">
<b>This local variable has not been assigned a value.</b><br>
<code>calc := Calc()</code> — because <code>calc</code> and <code>Calc</code> are the same identifier, the right-hand <code>Calc()</code> resolves to the <em>unassigned local</em>, not the class. It threw before a single test ran.
</div>

I renamed the assignment to `engine := Calc()` and ran again. It threw a *second* time — `This value of type "Class" has no method named "Eval"` — because I'd renamed the assignment but not the call site, and the leftover `calc.Eval(...)` now resolved `calc` to the class object itself. Two separate failures, both the same root cause, both in the harness whose entire job is to catch this exact mistake in *other* people's code.

<div class="xb-win">
<b>The fix:</b> one name for the class, a different name for the instance — <code>engine := Calc()</code>, and <code>engine.Eval(...)</code> everywhere. With that, all 50 tests went green. The benchmark's own prompt already lists this trap in its forbidden-patterns section. I read that prompt. I wrote it. I still fell in. That's the case for the benchmark in one anecdote.
</div>

## The 50 tests

The grader is deterministic. Every expected value is a number, compared with a `1e-9` tolerance so `2.5` vs `2.50000` and `4` vs `4.0` both pass — never a string compare. Error cases assert only that *something* threw, never on the message text.

<table class="xb-tests">
<tr><th>Category</th><th>Count</th><th>What it probes</th></tr>
<tr><td>literals + whitespace</td><td class="r">3</td><td>tokenizing, leading/trailing spaces</td></tr>
<tr><td>arithmetic + precedence</td><td class="r">7</td><td>left-assoc <code>+ - * / %</code>, <code>*</code> over <code>+</code></td></tr>
<tr><td>power</td><td class="r">4</td><td>right-assoc <code>^</code>, the precedence traps above</td></tr>
<tr><td>unary</td><td class="r">5</td><td><code>-5</code>, <code>2 * -3</code>, <code>- -4</code></td></tr>
<tr><td>parens / nesting</td><td class="r">3</td><td>grouping, <code>((1))</code></td></tr>
<tr><td>variables</td><td class="r">5</td><td>caller-supplied <code>env</code> lookups</td></tr>
<tr><td>functions</td><td class="r">11</td><td>fixed-arity, nesting, variadic <code>min</code>/<code>max</code></td></tr>
<tr><td>constants</td><td class="r">2</td><td><code>pi</code>, <code>2 * pi</code></td></tr>
<tr><td>errors (must throw)</td><td class="r">10</td><td>÷0, unknown name, parse failures</td></tr>
</table>

The error cases are where the parser quality shows. `3 4` must throw — two numbers with no operator is leftover input, and a sloppy parser silently returns `3` and discards the `4`. `* 3` must throw on a leading operator. `(1 + 2` must throw on the unbalanced paren rather than EOF-crashing. These are cheap to get right with a real recursive-descent parser and surprisingly common to get wrong without one.

## What I expect to separate the field

If the clipboard benchmark is any guide, the funnel will be steep. My predictions for where models will lose points, roughly in order of how many I expect to trip:

1. **The precedence traps** — right-associative `^` and unary-vs-`^`. Universal, language-independent, and most models guess.
2. **The shadow trap** — `result := Result()` and friends. AHK-specific, and even the prompt's own warning doesn't fully inoculate against it (exhibit A: me).
3. **Skipping the hierarchy** — one mega-function with a string-tag `switch`. Runs, scores low.
4. **Soft parse errors** — returning a partial result on `3 4` instead of throwing.
5. **`Map` discipline** — object literals for the environment instead of `Map()` with individual assignment.

No model results yet — this post is the problem reveal, not the scoreboard. The reference solution, the 50-test grader, and the exact prompt are all written and green against the answer key. The next post is 50 models, one expression grammar, and a column of pass rates.
