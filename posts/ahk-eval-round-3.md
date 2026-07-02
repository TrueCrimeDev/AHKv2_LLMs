# AHK-Eval Round 3: Self-Tests, and What Happens When the Harness Is Real

[Round 2](post.html?slug=ahk-eval-context-arms) ended on a blind spot: probe-based repair only helps when the bug shows on the probe — GPT-5.5's `Pivot` sailed through the single public example and died on the hidden cases. The fix it suggested: let the model write and run *its own* tests. Round 3 does that, twice over:

- **+self-tests** (all 13 models) — after writing the function, the model writes **up to 6 test cases of its own, derived from the spec** (JSON, frozen after generation). The harness runs the function against the public example plus the model's own tests, feeds failures back, and allows up to two repair rounds. The submission is the revision that passed the most probes. Hidden cases still never enter the loop — and neither does any *oracle*: the model's own expected values can be wrong, and nothing corrects them.
- **+Claude Code** (the three Claude models) — no scripted loop at all. Each task runs a fresh headless [Claude Code](https://claude.com/claude-code) session: same rules card in the system prompt, tools enabled, the fork interpreter's path in the prompt, and instructions to verify before answering. The model decides what to test, runs the real interpreter itself, and iterates. This is the arm every other arm was approximating.

Same 36 tasks, same 181 hidden cases, same driver, same fork. All fresh generations.

## The Ladder

<div class="bm-wrap"><table class="bm-heat"><thead><tr><th style="text-align:left">Model</th><th>cold</th><th>+card</th><th>+feedback</th><th>+self-tests</th><th>+Claude Code</th></tr></thead><tbody><tr><td class="h-name">GPT-5.5</td><td class="h-emer">35</td><td class="h-emer">35</td><td class="h-emer">35</td><td class="h-emer">36/36</td><td class="h-dim">—</td></tr><tr><td class="h-name">Fable 5</td><td class="h-emer">34</td><td class="h-emer">35</td><td class="h-emer">36/36</td><td class="h-emer">36/36</td><td class="h-emer">36/36</td></tr><tr><td class="h-name">Gemini 3.1 Pro</td><td class="h-emer">32</td><td class="h-emer">32</td><td class="h-emer">35</td><td class="h-emer">34</td><td class="h-dim">—</td></tr><tr><td class="h-name">Kimi K2.6</td><td class="h-emer">30</td><td class="h-amber">26</td><td class="h-emer">32</td><td class="h-emer">32</td><td class="h-dim">—</td></tr><tr><td class="h-name">Opus 4.8</td><td class="h-emer">29</td><td class="h-emer">29</td><td class="h-emer">34</td><td class="h-emer">35</td><td class="h-emer">36/36</td></tr><tr><td class="h-name">Grok 4.3</td><td class="h-emer">28</td><td class="h-amber">25</td><td class="h-emer">31</td><td class="h-emer">35</td><td class="h-dim">—</td></tr><tr><td class="h-name">MiniMax M3</td><td class="h-amber">26</td><td class="h-amber">24</td><td class="h-emer">30</td><td class="h-emer">33</td><td class="h-dim">—</td></tr><tr><td class="h-name">Sonnet 4.6</td><td class="h-amber">25</td><td class="h-amber">27</td><td class="h-amber">29</td><td class="h-emer">34</td><td class="h-emer">35</td></tr><tr><td class="h-name">GLM-5</td><td class="h-amber">25</td><td class="h-amber">27</td><td class="h-amber">29</td><td class="h-emer">30</td><td class="h-dim">—</td></tr><tr><td class="h-name">GPT-5.1</td><td class="h-amber">22</td><td class="h-amber">25</td><td class="h-amber">25</td><td class="h-amber">24</td><td class="h-dim">—</td></tr><tr><td class="h-name">DeepSeek V4 Pro</td><td class="h-amber">22</td><td class="h-amber">26</td><td class="h-amber">27</td><td class="h-emer">34</td><td class="h-dim">—</td></tr><tr><td class="h-name">Qwen3 Coder</td><td class="h-amber">16</td><td class="h-amber">15</td><td class="h-amber">18</td><td class="h-amber">23</td><td class="h-dim">—</td></tr><tr><td class="h-name">Mistral Large 3</td><td class="h-red">9</td><td class="h-red">12</td><td class="h-red">15</td><td class="h-red">17</td><td class="h-dim">—</td></tr></tbody></table></div>

Field means, in order: **25.6 → 26.0 → 28.9 → 31.0**. The full ladder now reads: documentation is worth a third of a task, one probe repair is worth three, self-tests are worth five and a half.

## Self-Tests Fixed Exactly What Round 2 Said They Would

`Pivot` — the blind-spot task — went **4 solves cold, 5 with probe-repair, 9 with self-tests**. GPT-5.5, whose `Pivot` slipped through round 2's public probe, wrote its own edge cases this time, caught the bug the probe couldn't see, and posted **36/36** — the first perfect run by a non-Fable model. Models wrote 5.9 tests per task on average; 146 of 468 cells used at least one repair round; 397 finished passing every probe they wrote.

The pattern held across the mid-field, and violently: **DeepSeek V4 Pro +12 over cold** (22 → 34), Grok +7, Sonnet +9, MiniMax +7, Qwen3 Coder +7. Writing tests is cheaper than being smarter.

And the one falsification the arm design predicted showed up on schedule: **GPT-5.1 got *worse* than probe-repair** (25 → 24). Its own expected values were wrong often enough (13 of its 36 cells never passed their own probes) that the loop optimized toward its own misreadings. Self-tests are an amplifier: they amplify spec understanding, including bad spec understanding.

## The Real Harness

The scripted arms are simulations of a coding harness. The last arm is one: headless **Claude Code**, tools on, real interpreter, the model choosing its own verification strategy. Three models, 36 tasks each:

<div class="bm-wrap"><table class="bm-heat"><thead><tr><th style="text-align:left">Model</th><th>cold</th><th>+Claude Code</th><th>Δ</th><th>hidden cases</th><th>cost</th></tr></thead><tbody><tr><td class="h-name">Fable 5</td><td class="h-emer">34</td><td class="h-emer">36/36</td><td class="h-emer">+2</td><td class="h-emer">181/181</td><td class="h-dim">$21.94</td></tr><tr><td class="h-name">Opus 4.8</td><td class="h-emer">29</td><td class="h-emer">36/36</td><td class="h-emer">+7</td><td class="h-emer">181/181</td><td class="h-dim">$10.03</td></tr><tr><td class="h-name">Sonnet 4.6</td><td class="h-amber">25</td><td class="h-emer">35/36</td><td class="h-emer">+10</td><td class="h-emer">180/181</td><td class="h-dim">$3.89</td></tr></tbody></table></div>

Two perfect runs and a 35 — from models that scored 29 and 25 cold. **Sonnet 4.6 inside Claude Code matches cold GPT-5.5.** The harness was worth more than two model tiers, at about eleven cents a task. Each model averaged ~3 agent turns per task: write the function, write a test script, run it against the fork, fix, answer.

Sonnet's single miss is the suite's most stubborn survivor: `Pivot`, 4/5 hidden cases — its self-written tests passed, one hidden edge didn't. Some bugs outlive every harness short of the hidden suite itself.

## The Conflict-of-Interest Line, One Last Time

Fable 5 built this benchmark and all three harness arms, and sat every one of them under the same protocol as the field (bare Anthropic API for the scripted arms; for the Claude Code arm, the same headless CLI as Opus and Sonnet). It has now posted **36/36, 181/181 in three consecutive arms** — probe-repair, self-tests, and Claude Code. Cold, it scored 34 and wrote its favorite trap twice. The gap between those two numbers is the entire subject of this series.

## Takeaway

Four interventions, one ordering, no exceptions worth betting against:

1. **Documentation** (+0.4 tasks): a coin flip that hurts strong models as often as it helps weak ones.
2. **One probe repair** (+3.3): the cheapest reliable lift; blind to bugs the probe misses.
3. **Self-tests** (+5.4): fixes the blind spot; amplifies bad spec-reading (one model regressed).
4. **A real agentic harness**: turns mid-tier models into near-perfect systems for ~$0.11/task.

If you write AHK v2 with a model — any model — the data says: don't buy it a rules file, buy it a runner.

*Method notes: v2.1-alpha.30+Console fork throughout; driver, hidden cases, and extraction identical to rounds 1–2. Self-test arm: OpenRouter `temperature 0.2` (Fable 5 via Anthropic API, default sampling), tests capped at 6 and frozen after generation, up to two repair rounds, best-probe revision submitted. Claude Code arm: `claude -p` v2.1.198, `--append-system-prompt` = the same rules card, `--allowedTools Write,Read,Edit,Bash`, max 25 turns, fresh scratch directory per task, billed via API key; per-task costs from the CLI's own accounting ($35.86 total for 108 tasks). Fable 5 wrote the harness arms and this post; all grading is the same automated pipeline as round 1.*
