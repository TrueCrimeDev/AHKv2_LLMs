<!-- posts/example-post.md -->
[//]: # (title: Using AutoHotkey v2 with Coding Agents and LLMs)
[//]: # (date: 2025-11-17)
[//]: # (tags: AutoHotkey v2, LLMs, automation, workflows)

# Using AutoHotkey v2 with Coding Agents and LLMs

AutoHotkey v2 is a surprisingly good match for coding agents and large language models. The language is compact, expressive, and focused on practical desktop automation, which means a short prompt or a small code sample often carries a lot of intent. When an LLM understands that intent, it can help you move from a rough idea to a working script in a few iterations.

In day‑to‑day work, the biggest friction with AutoHotkey is usually not the language itself, but the tiny details: remembering which window class to target, tweaking a send sequence so it behaves well in one stubborn application, or restructuring a script that grew from twenty lines to two hundred. Coding agents are good at this kind of incremental editing, especially when you keep the prompt grounded in real code.

Another benefit is that v2's more consistent syntax maps nicely onto the mental model LLMs use for mainstream languages. You can describe your script in terms of functions, modules, and "handlers" for different hotkeys, and most agents will respond with code that is at least structurally sound. From there you can refine naming, add comments, and shape the script into something you are comfortable maintaining.

A simple workflow is to treat the agent as a drafting companion: you keep control of the overall design, and the model helps with the repetitive or mechanical parts. You might paste a failing hotkey function into a prompt, ask for a less fragile way to detect a window, or request a small refactor that separates configuration from behavior.

Some practical use cases that work well in this style include:

- Generating boilerplate AHK v2 scripts for new projects or machines.
- Refactoring older v1-style hotkey logic into clearer v2 functions.
- Explaining cryptic error messages or unexpected behavior in existing scripts.
- Sketching out alternative implementations for a tricky automation step.
- Reviewing a script for obvious race conditions or missing checks.

Here is a short AutoHotkey-style snippet that could be handed to a coding agent for improvement or extension:

```cpp
; Simple AHK v2 hotkey that toggles mute and shows a tooltip
#Requires AutoHotkey v2.0
#SingleInstance Force

^!m:: {
    SoundSetMute -1  ; toggle
    isMuted := SoundGetMute()
    msg := isMuted ? "Muted system volume" : "Unmuted system volume"
    ToolTip msg, 0, 0
    SetTimer () => ToolTip(), -900
}
```

The script is intentionally small, but it still gives the model something concrete to work with. You can ask for a version that logs each toggle to a file, adds basic error handling, or integrates with a larger "productivity" script that manages multiple hotkeys. Over time, this kind of iterative collaboration lets you build a personal library of AHK v2 tools that feel tailored to how you actually use your machine, with the LLM handling most of the boilerplate along the way.
