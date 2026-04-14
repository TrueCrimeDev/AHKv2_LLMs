# CloudAHK: Remote AHK v2 Execution via REST API

CloudAHK is a lightweight FastAPI service that runs AutoHotkey v2 scripts on the host machine through a simple HTTP interface. Send code, get stdout/stderr back. It also includes an ANTLR-based parser endpoint that returns full parse trees, token streams, and Graphviz DOT output for any AHK v2 source.

The project lives in `cloudahk/` in this repo. It consists of three parts: the Python API server, an AHK v2 client class, and an ANTLR parser bridge.

---

## Architecture

```
┌──────────────┐     POST /v2/run     ┌───────────────┐     subprocess     ┌──────────────┐
│  AHK Client  │ ──────────────────── │  FastAPI       │ ──────────────── │  AutoHotkey   │
│  or curl     │                      │  (api.py)      │                  │  v2 Interpreter│
└──────────────┘     JSON response    └───────────────┘     stdout/stderr └──────────────┘
                                            │
                                            │ POST /v2/parse
                                            ▼
                                      ┌───────────────┐
                                      │  ANTLR Parser  │
                                      │  (TypeScript)  │
                                      └───────────────┘
```

The API writes your code to a temp file, runs it with the local AHK interpreter, captures output, and cleans up. No persistent state.

---

## Quick Start

### Prerequisites

- Python 3.9+
- AutoHotkey v2 installed locally

### Setup

```ahk2
; From the cloudahk/ directory:
; python -m venv .venv
; .venv\Scripts\Activate.ps1
; pip install -r requirements.txt
; python httpd.py
```

The server starts on `http://localhost:8000` by default.

### Run a Script

```ahk2
; curl example:
; curl -X POST http://localhost:8000/v2/run \
;      -H "Content-Type: application/json" \
;      -d '{"code": "FileAppend(\"hello world\", \"*\")"}'
```

Response:

```ahk2
; {
;   "exit_code": 0,
;   "stdout": "hello world",
;   "stderr": "",
;   "timed_out": false,
;   "duration": 0.42,
;   "interpreter": "C:\\Program Files\\AutoHotkey\\v2\\AutoHotkey64.exe"
; }
```

---

## AHK v2 Client

`CloudAhkClient.ahk` lets you call the API from other AHK scripts:

```ahk2
#Requires AutoHotkey v2.0

client := CloudAhkClient("http://localhost:8000")

; Execute remote code
response := client.Run('FileAppend("test", "*")')
MsgBox("Output: " . response.stdout)

; Check API health
health := client.Health()
MsgBox("Status: " . health.status)
```

The client uses `WinHttp.WinHttpRequest.5.1` COM object for HTTP, builds JSON payloads manually (no external dependencies), and parses responses into AHK objects.

### Run Options

```ahk2
; With options
opts := Map()
opts["timeout"] := 5.0
opts["args"] := ["--verbose"]
opts["stdin"] := "input data"
opts["prepend_requires"] := false

response := client.Run(myCode, opts)
```

| Option | Default | Description |
|--------|---------|-------------|
| `timeout` | 10.0 | Max execution time in seconds |
| `args` | `[]` | Command-line args exposed via `A_Args` |
| `stdin` | `""` | Data piped to script's stdin |
| `prepend_requires` | `true` | Auto-add `#Requires AutoHotkey v2.0` |

---

## REST API Endpoints

### GET /health

Readiness probe. Reports interpreter and parser availability.

```ahk2
; Response:
; { "status": "ready", "interpreter": "C:\\...\\AutoHotkey64.exe", "parser": "ready" }
```

### POST /v2/run

Execute AHK v2 source code. The API writes the code to a temp file, runs it, captures output, and cleans up.

| Field | Type | Default | Description |
|-------|------|---------|-------------|
| `code` | string | required | AHK v2 source to execute |
| `args` | string[] | `[]` | Command-line arguments |
| `timeout` | float | 10.0 | Max seconds (capped at 30) |
| `stdin` | string | null | Stdin input |
| `prepend_requires` | bool | true | Auto-add #Requires directive |

### POST /v2/parse

Parse AHK v2 source using the ANTLR grammar. Returns the parse tree, token stream, and optional Graphviz DOT output.

| Field | Type | Default | Description |
|-------|------|---------|-------------|
| `code` | string | required | AHK v2 source to parse |
| `include_tree` | bool | true | Include parse tree |
| `include_tokens` | bool | false | Include token stream |
| `include_dot` | bool | false | Include Graphviz DOT |
| `show_all_nodes` | bool | true | Show all nodes in DOT |

---

## Template Manager

`TemplateManager.ahk` generates AHK v2 scripts from templates in the `templates/` directory. Available templates:

| Template | Description |
|----------|-------------|
| `simple_msgbox.ahk` | Basic MsgBox script |
| `tooltip_notifier.ahk` | Tooltip notification |
| `hotkey_generator.ahk` | Hotkey with action |
| `class_generator.ahk` | OOP class scaffold |
| `gui_generator.ahk` | GUI window template |
| `system_info.ahk` | System info reporter |

---

## Environment Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `AHK_V2_PATH` | auto-detect | Path to AutoHotkey v2 interpreter |
| `CLOUDAHK_HOST` | `0.0.0.0` | Bind address |
| `CLOUDAHK_PORT` | `8000` | Port |
| `CLOUDAHK_RELOAD` | `false` | Enable uvicorn autoreload |
| `CLOUDAHK_LOG_LEVEL` | `info` | Uvicorn log level |

---

## Use Cases

- **LLM code generation**: Generate AHK v2 code with an LLM, execute it via CloudAHK, check output, iterate
- **CI/CD testing**: Run AHK v2 test suites from a build pipeline
- **Remote automation**: Trigger desktop automation from a server or mobile device
- **Code validation**: Parse AHK v2 source to catch syntax errors before execution
- **Education**: Build web-based AHK v2 playgrounds that execute code server-side
