# CloudAHK

CloudAHK exposes a lightweight FastAPI service that runs AutoHotkey v2 scripts on the host machine. The API is designed for experimentation, automation, and remote execution scenarios where you need a simple HTTP interface to the AutoHotkey interpreter.

## Prerequisites

- Python 3.10+
- Node.js 18+ (required for the ANTLR parsing endpoint)
- AutoHotkey v2 installed locally (set `AHK_V2_PATH` to the interpreter if it is not on a default path)

## Setup

```
cd cloudahk
pip install -r requirements.txt
python httpd.py
```

Set the interpreter location if AutoHotkey v2 is not on a standard path:

```
set AHK_V2_PATH=C:\Program Files\AutoHotkey\v2\AutoHotkey.exe
```

## Running the API

```powershell
python httpd.py
```

Environment variables (optional):

- `AHK_V2_PATH` – explicit path to `AutoHotkey64.exe`
- `CLOUDAHK_HOST` – bind address (default `0.0.0.0`)
- `CLOUDAHK_PORT` – port (default `8000`)
- `CLOUDAHK_RELOAD` – set to `true` to enable autoreload in development
- `CLOUDAHK_LOG_LEVEL` – uvicorn log level (default `info`)

### Optional: Enable the ANTLR parser endpoint

The `/v2/parse` route shells out to the TypeScript/ANTLR project in the sibling `Parser/` directory. Run the following once to install dependencies and build the CLI used by the API:

```powershell
cd ..\Parser
npm install
npm run build:parser
```

Re-run `npm run build:parser` whenever you modify the grammar or the sources under `Parser/src`.

## REST Endpoints

- `GET /health` – readiness probe; reports whether the interpreter and parser are available
- `POST /v2/run` – execute an AutoHotkey v2 script
- `POST /v2/parse` – lex and parse AutoHotkey v2 source using the ANTLR grammar

Request body for `/v2/run`:

```json
{
  "code": "MsgBox \"Hello from AutoHotkey v2!\"",
  "args": [],
  "timeout": 10.0,
  "stdin": null,
  "prepend_requires": true
}
```

Example using `curl`:

```powershell
curl -X POST http://localhost:8000/v2/run `
     -H "Content-Type: application/json" `
     -d '{"code":"MsgBox \"Hello\"" }'
```

Response:

```json
{
  "exit_code": 0,
  "stdout": "",
  "stderr": "",
  "timed_out": false,
  "duration": 0.42,
  "interpreter": "C:\\Program Files\\AutoHotkey\\v2\\AutoHotkey64.exe"
}
```

Request body for `/v2/parse` (fields are optional unless noted):

```json
{
  "code": "MsgBox 'hello'",
  "include_tree": true,
  "include_tokens": false,
  "include_dot": false,
  "show_all_nodes": true
}
```

Example response (truncated):

```json
{
  "lexer_errors": [],
  "parser_errors": [],
  "errors": [],
  "tree": { "type": "rule", "name": "program", "children": [/* ... */] },
  "metrics": { "lexMs": 5.3, "parseMs": 32.8, "totalMs": 38.1 }
}
```

If `include_dot` is set to `true`, the response includes a `dot` property containing a Graphviz description of the parse tree that you can feed to `dot`/`Viz.js` for rendering.

The API writes scripts to temporary files and cleans them up after execution. By default, `#Requires AutoHotkey v2.0` is prepended unless you provide your own directive.
