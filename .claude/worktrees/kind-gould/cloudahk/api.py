#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import asyncio
import json
import logging
import os
import shutil
import tempfile
import time
from pathlib import Path
from typing import Any, Dict, List, Optional

from fastapi import FastAPI, HTTPException
from fastapi.responses import JSONResponse
from pydantic import BaseModel, Field

APP_TITLE = "CloudAHK v2"
DESCRIPTION = "REST API for executing AutoHotkey v2 scripts with the local interpreter."
VERSION = "0.1.0"
MAX_TIMEOUT_SECONDS = 30.0

logger = logging.getLogger("cloudahk.api")
logging.basicConfig(level=logging.INFO)


def _candidate_interpreter_paths() -> List[Path]:
    """Return likely locations for an AutoHotkey v2 interpreter."""
    candidates: List[Optional[Path]] = []
    env_path = os.getenv("AHK_V2_PATH")
    if env_path:
        candidates.append(Path(env_path))
    base_dir = Path(__file__).resolve().parent
    candidates.extend(
        [
            base_dir / "ahk" / "v2" / "AutoHotkey64.exe",
            base_dir / "ahk" / "v2" / "AutoHotkeyU64.exe",
            base_dir / "ahk" / "v2" / "AutoHotkey.exe",
            base_dir / "AutoHotkey64.exe",
            base_dir / "AutoHotkeyU64.exe",
            base_dir / "AutoHotkey.exe",
            Path(r"C:\Program Files\AutoHotkey\v2\AutoHotkey.exe"),
            Path(r"C:\Program Files\AutoHotkey\v2\AutoHotkey64.exe"),
            Path(r"C:\Program Files\AutoHotkey\v2\AutoHotkeyU64.exe"),
            Path(r"C:\Program Files\AutoHotkey\AutoHotkey64.exe"),
            Path(r"C:\Program Files\AutoHotkey\AutoHotkeyU64.exe"),
            Path(r"C:\Program Files\AutoHotkey\AutoHotkey.exe"),
            Path(r"C:\Program Files (x86)\AutoHotkey\v2\AutoHotkey32.exe"),
            Path(r"C:\Program Files (x86)\AutoHotkey\AutoHotkey32.exe"),
        ]
    )
    # Deduplicate while preserving order
    seen = set()
    unique_candidates: List[Path] = []
    for candidate in candidates:
        if candidate is None:
            continue
        candidate = candidate.expanduser()
        if candidate in seen:
            continue
        seen.add(candidate)
        unique_candidates.append(candidate)
    return unique_candidates


def _resolve_interpreter() -> Path:
    for candidate in _candidate_interpreter_paths():
        if candidate.is_file():
            return candidate
    raise FileNotFoundError(
        "AutoHotkey v2 interpreter could not be located. "
        "Set the AHK_V2_PATH environment variable to the interpreter executable."
    )


def _resolve_lib_dir(base_dir: Path) -> Optional[Path]:
    env_path = os.getenv("AHK_LIB_DIR")
    if env_path:
        lib_path = Path(env_path).expanduser()
        if lib_path.is_dir():
            return lib_path
        logger.warning("AHK_LIB_DIR environment variable points to non-existent directory.")
    candidate = base_dir / "ahk" / "Lib"
    return candidate if candidate.is_dir() else None


def _resolve_parser_cli(base_dir: Path) -> tuple[Optional[List[str]], Optional[Path]]:
    parser_dir = base_dir.parent / "Parser"
    if not parser_dir.is_dir():
        logger.warning("Parser directory not found")
        return None, None

    build_artifact = parser_dir / "dist" / "cli.js"
    if not build_artifact.is_file():
        logger.warning("Parser CLI build output not found; run `npx tsc` inside the Parser directory.")
        return None, parser_dir

    node_modules = parser_dir / "node_modules"
    if not node_modules.is_dir():
        logger.warning("Parser dependencies not installed")
        return None, parser_dir

    return ["node", str(build_artifact)], parser_dir


app = FastAPI(title=APP_TITLE, description=DESCRIPTION, version=VERSION)
# Maintain backwards compatibility with existing tooling that imports cloudapi.
cloudapi = app

# CORS: allow the playground and local development to call the API
try:
    from fastapi.middleware.cors import CORSMiddleware
    app.add_middleware(
        CORSMiddleware,
        allow_origins=["*"],
        allow_methods=["*"],
        allow_headers=["*"],
    )
except ImportError:
    pass


class RunRequest(BaseModel):
    code: str = Field(..., description="AutoHotkey v2 script source to execute.")
    args: List[str] = Field(
        default_factory=list,
        description="Command-line arguments that will be exposed via A_Args.",
    )
    timeout: float = Field(
        default=10.0,
        gt=0.0,
        le=MAX_TIMEOUT_SECONDS,
        description=f"Maximum execution time in seconds (capped at {MAX_TIMEOUT_SECONDS} s).",
    )
    stdin: Optional[str] = Field(
        default=None,
        description="Data piped to the script's standard input.",
    )
    encoding: str = Field(
        default="utf-8-sig",
        description="Encoding used when writing the temporary script file.",
    )
    prepend_requires: bool = Field(
        default=True,
        description="Prepend '#Requires AutoHotkey v2.0' unless already present.",
    )


class RunResponse(BaseModel):
    exit_code: int
    stdout: str
    stderr: str
    timed_out: bool
    duration: float
    interpreter: str


class ParseRequest(BaseModel):
    code: str = Field(..., description="AutoHotkey v2 source to parse.")
    include_tree: bool = Field(
        default=True,
        description="Include the ANTLR parse tree in the response.",
    )
    include_tokens: bool = Field(
        default=False,
        description="Include the token stream returned by the lexer.",
    )
    include_dot: bool = Field(
        default=False,
        description="Include a Graphviz DOT representation of the parse tree.",
    )
    show_all_nodes: bool = Field(
        default=True,
        description="Render all nodes in the DOT output (uncheck to collapse simple chains).",
    )
    add_trailing_newline: bool = Field(
        default=True,
        description="Append a trailing newline before parsing to match editor behaviour.",
    )
    timeout: float = Field(
        default=5.0,
        gt=0.0,
        le=MAX_TIMEOUT_SECONDS,
        description=f"Maximum parser runtime in seconds (capped at {MAX_TIMEOUT_SECONDS} s).",
    )


class ParseResponse(BaseModel):
    tokens: Optional[List[Dict[str, Any]]] = None
    lexer_errors: List[Dict[str, Any]]
    parser_errors: List[Dict[str, Any]]
    errors: List[Dict[str, Any]]
    tree: Optional[Dict[str, Any]] = None
    metrics: Dict[str, float]
    dot: Optional[str] = None


def _get_interpreter_path() -> Path:
    interpreter = getattr(app.state, "interpreter_path", None)
    if interpreter is None:
        raise HTTPException(
            status_code=503,
            detail="AutoHotkey v2 interpreter is unavailable. Configure the AHK_V2_PATH environment variable.",
        )
    return interpreter


async def _run_script(interpreter_path: Path, payload: RunRequest) -> RunResponse:
    temp_dir = Path(tempfile.mkdtemp(prefix="ahk-api-"))
    script_path = temp_dir / "script.ah2"

    script_body = payload.code
    if payload.prepend_requires:
        stripped = script_body.lstrip()
        if not stripped.startswith("#Requires"):
            script_body = "#Requires AutoHotkey v2.0\n" + script_body

    script_path.write_text(script_body, encoding=payload.encoding)

    argv = [
        str(interpreter_path),
        "/ErrorStdOut",
        "/CP65001",
        str(script_path),
        *payload.args,
    ]

    stdin_bytes = payload.stdin.encode("utf-8") if payload.stdin is not None else None

    start = time.perf_counter()
    try:
        process = await asyncio.create_subprocess_exec(
            *argv,
            stdout=asyncio.subprocess.PIPE,
            stderr=asyncio.subprocess.PIPE,
            stdin=asyncio.subprocess.PIPE if stdin_bytes is not None else None,
            cwd=str(temp_dir),
        )
    except FileNotFoundError as exc:
        raise HTTPException(status_code=500, detail=f"Interpreter not found: {exc}") from exc
    except OSError as exc:
        raise HTTPException(status_code=500, detail=f"Failed to start interpreter: {exc}") from exc

    try:
        try:
            stdout, stderr = await asyncio.wait_for(
                process.communicate(stdin_bytes),
                timeout=payload.timeout,
            )
            timed_out = False
        except asyncio.TimeoutError:
            process.kill()
            stdout, stderr = await process.communicate()
            timed_out = True
        duration = time.perf_counter() - start
        exit_code = process.returncode if process.returncode is not None else -1
        return RunResponse(
            exit_code=exit_code,
            stdout=stdout.decode("utf-8", errors="replace"),
            stderr=stderr.decode("utf-8", errors="replace"),
            timed_out=timed_out,
            duration=duration,
            interpreter=str(interpreter_path),
        )
    finally:
        shutil.rmtree(temp_dir, ignore_errors=True)


def _get_parser_cli() -> tuple[List[str], Path]:
    command = getattr(app.state, "parser_cli", None)
    parser_dir = getattr(app.state, "parser_dir", None)
    if not command or parser_dir is None:
        raise HTTPException(
            status_code=503,
            detail="ANTLR parser is unavailable. Install dependencies by running `npm install` inside the Parser directory.",
        )
    return command, parser_dir


async def _run_parser(
    command: List[str],
    parser_dir: Path,
    payload: ParseRequest,
) -> Dict[str, Any]:
    request = {
        "code": payload.code,
        "includeTree": payload.include_tree,
        "includeTokens": payload.include_tokens,
        "includeDot": payload.include_dot,
        "showAll": payload.show_all_nodes,
        "addTrailingNewline": payload.add_trailing_newline,
    }

    try:
        process = await asyncio.create_subprocess_exec(
            *command,
            stdin=asyncio.subprocess.PIPE,
            stdout=asyncio.subprocess.PIPE,
            stderr=asyncio.subprocess.PIPE,
            cwd=str(parser_dir),
        )
    except FileNotFoundError as exc:
        raise HTTPException(status_code=500, detail=f"Parser command not found: {exc}") from exc
    except OSError as exc:
        raise HTTPException(status_code=500, detail=f"Failed to start parser: {exc}") from exc

    payload_bytes = json.dumps(request).encode("utf-8")

    try:
        stdout, stderr = await asyncio.wait_for(
            process.communicate(payload_bytes),
            timeout=payload.timeout,
        )
    except asyncio.TimeoutError:
        process.kill()
        stdout, stderr = await process.communicate()
        raise HTTPException(status_code=504, detail="ANTLR parser timed out.") from None

    if process.returncode != 0:
        message = stderr.decode("utf-8", errors="replace").strip() or "Parser process failed."
        raise HTTPException(status_code=500, detail=message)

    try:
        result = json.loads(stdout.decode("utf-8"))
    except json.JSONDecodeError as exc:
        raise HTTPException(status_code=500, detail="Parser returned invalid JSON.") from exc

    if not payload.include_tokens:
        result.pop("tokens", None)
    if not payload.include_tree:
        result.pop("tree", None)
    if not payload.include_dot:
        result.pop("dot", None)

    return result


@app.on_event("startup")
async def startup_event() -> None:
    base_dir = Path(__file__).resolve().parent
    app.state.base_dir = base_dir
    app.state.lib_dir = _resolve_lib_dir(base_dir)
    parser_command, parser_dir = _resolve_parser_cli(base_dir)
    app.state.parser_cli = parser_command
    app.state.parser_dir = parser_dir
    try:
        app.state.interpreter_path = _resolve_interpreter()
    except FileNotFoundError as exc:
        app.state.interpreter_path = None
        logger.error("%s", exc)
    else:
        logger.info("Using AutoHotkey v2 interpreter at %s", app.state.interpreter_path)
    if app.state.lib_dir:
        logger.info("Library directory available")
    if parser_command and parser_dir:
        logger.info("ANTLR parser CLI available")
    elif parser_dir:
        logger.warning(
            "ANTLR parser CLI dependencies missing; run `npm install` in Parser directory to enable /v2/parse."
        )


@app.get("/health")
async def health() -> JSONResponse:
    interpreter = getattr(app.state, "interpreter_path", None)
    status = "ready" if interpreter else "degraded"
    parser_available = getattr(app.state, "parser_cli", None)
    parser_status = "ready" if parser_available else "degraded"
    return JSONResponse(
        {
            "status": status,
            "interpreter": str(interpreter) if interpreter else None,
            "parser": parser_status,
        }
    )


@app.post("/v2/run", response_model=RunResponse)
async def run_v2(payload: RunRequest) -> RunResponse:
    interpreter_path = _get_interpreter_path()
    return await _run_script(interpreter_path, payload)

@app.post("/v2/parse", response_model=ParseResponse)
async def parse_v2(payload: ParseRequest) -> ParseResponse:
    command, parser_dir = _get_parser_cli()
    result = await _run_parser(command, parser_dir, payload)
    return ParseResponse(**result)
