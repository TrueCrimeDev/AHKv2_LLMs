# Prompt Engineering for AHK v2 Code Generation

AutoHotkey v2 is a niche language with specific syntax requirements that differ significantly from mainstream languages. LLMs are trained on much more JavaScript, Python, and C# code than AHK, so they may default to patterns from those languages unless guided correctly.

## Why Prompt Engineering Matters for AHK

Effective prompts:

- Specify v2 syntax requirements explicitly
- Prevent common v1/JavaScript contamination
- Guide the LLM toward AHK-idiomatic patterns
- Result in code that runs without modification

## The Essential System Prompt

Start your session with a context-setting prompt:

```
You are an AutoHotkey v2 expert. Follow these requirements strictly:

SYNTAX RULES:
- Use := for ALL assignments (never =)
- Arrays are 1-indexed (first element is arr[1], not arr[0])
- Use Map() for key-value storage (not object literals like {key: value})
- Functions always use parentheses: MyFunc() not MyFunc
- Use &var for ByRef parameters (not ByRef var)
- Fat arrow => only for single-expression functions

GUI RULES:
- Use Gui() object syntax
- Always .Bind(this) for method callbacks in classes
- Events use .OnEvent("EventName", callback)

ERROR HANDLING:
- Never use empty catch blocks
- Use try/catch for risky operations
- Validate parameters at function entry
```

## Prompt Templates by Task Type

### Class Generation

```
Create an AutoHotkey v2 class named [ClassName] that:

PURPOSE:
[Describe what the class does]

REQUIREMENTS:
- Properties: [list properties with types]
- Methods: [list methods with signatures]

CONSTRAINTS:
- Use Map() for any internal key-value storage
- Include proper __Delete cleanup
- Validate parameters in __New
- Support method chaining where appropriate
```

### GUI Application

```
Create an AutoHotkey v2 GUI application that:

WINDOW:
- Title: [title]
- Size: [dimensions or "auto-size"]
- Options: [+Resize, +MinimizeBox, etc.]

CONTROLS:
1. [Control type] - [purpose]
2. [Continue listing controls]

BEHAVIOR:
- [Describe interactions]
- [Describe button actions]

REQUIREMENTS:
- Wrap in a class that extends a base GUI class
- Use .Bind(this) for all event callbacks
- Include proper window close handling
```

## Anti-Pattern Prevention

Add explicit "do not" instructions:

```
DO NOT:
- Use {key: value} object literals for data - use Map("key", value)
- Access arrays with index 0 - AHK arrays start at 1
- Use = for assignment - only := is valid in v2
- Use ComObjCreate() - use ComObject() instead
- Forget .Bind(this) on class method callbacks
- Leave catch blocks empty
- Use global variables without 'global' declaration
```

## Iterative Refinement Technique

For complex scripts, use iterative prompting:

### Step 1: Structure

```
Create the class structure for a [description] application.
Include:
- Class definition with properties
- Method signatures (not implementations)
- Event handler stubs

I want to review the structure before implementation.
```

### Step 2: Core Logic

```
Now implement the core methods:
- [Method 1]: [detailed requirements]
- [Method 2]: [detailed requirements]

Include error handling and validation.
```

### Step 3: Polish

```
Add to the implementation:
- Input validation with descriptive error messages
- Resource cleanup in __Delete
- Method chaining support
```

## Code Review Prompts

Use LLMs to review generated code:

```
Review this AutoHotkey v2 code for:

1. V2 SYNTAX COMPLIANCE
   - Correct assignment operators
   - Proper function call syntax
   - Valid array indexing

2. OOP BEST PRACTICES
   - Proper use of this.
   - Event callback binding
   - Resource cleanup

3. COMMON ANTI-PATTERNS
   - Object literals instead of Map()
   - Missing error handling
   - Global variable usage

[Paste code here]
```

## Complete Example Prompt

```
Create an AutoHotkey v2 class called ClipboardManager that provides:

FEATURES:
1. Clipboard history (last 20 items)
2. Quick paste menu (Ctrl+Shift+V)
3. Search through history
4. Pin frequently used items

REQUIREMENTS:
- Store history in a Map with timestamp keys
- GUI should be dark-themed
- ListView to display history
- Escape closes the popup

CONSTRAINTS:
- Use Map() for all key-value storage
- Bind all callbacks properly with .Bind(this)
- Include __Delete for cleanup
- Handle edge cases (empty clipboard, non-text content)

DO NOT:
- Use object literals {key: value}
- Access arrays with index 0
- Use empty catch blocks

Provide complete, runnable code.
```

## Validation Follow-up

After receiving code, validate:

```
Check the code you just provided:

1. Are all Map() usages correct (not object literals)?
2. Is array indexing 1-based everywhere?
3. Are all class method callbacks using .Bind(this)?
4. Are there any empty catch blocks?
5. Is := used for all assignments?

If you find any issues, provide corrected code.
```

## Quick Reference: Must-Include Constraints

Always include these in AHK v2 prompts:

1. Use := for assignment (never =)
2. Arrays are 1-indexed
3. Use Map() not object literals
4. Use .Bind(this) for class callbacks
5. Use ComObject() not ComObjCreate()
6. Never leave catch blocks empty
7. Use &var for ByRef parameters

## Key Takeaway

Effective prompt engineering for AHK v2 requires explicit syntax constraints, anti-pattern prevention, and iterative refinement. Build a library of tested prompt templates for consistent, high-quality code generation.
