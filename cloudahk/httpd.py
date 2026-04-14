#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import logging
import os
from typing import Optional

import uvicorn

DEFAULT_HOST = "0.0.0.0"
DEFAULT_PORT = 8000
DEFAULT_RELOAD = False
DEFAULT_LOG_LEVEL = "info"

logger = logging.getLogger("cloudahk.httpd")


def _get_env_flag(name: str, default: bool) -> bool:
    value = os.getenv(name)
    if value is None:
        return default
    return value.strip().lower() in {"1", "true", "yes", "on"}


def _get_env_int(name: str, default: int) -> int:
    raw = os.getenv(name)
    if raw is None:
        return default
    try:
        return int(raw)
    except ValueError:
        logger.warning("Invalid integer for %s=%s; falling back to %d", name, raw, default)
        return default


def main(
    host: Optional[str] = None,
    port: Optional[int] = None,
    reload: Optional[bool] = None,
    log_level: Optional[str] = None,
) -> None:
    resolved_host = host or os.getenv("CLOUDAHK_HOST", DEFAULT_HOST)
    resolved_port = port or _get_env_int("CLOUDAHK_PORT", DEFAULT_PORT)
    resolved_reload = reload if reload is not None else _get_env_flag("CLOUDAHK_RELOAD", DEFAULT_RELOAD)
    resolved_log_level = log_level or os.getenv("CLOUDAHK_LOG_LEVEL", DEFAULT_LOG_LEVEL)

    uvicorn.run(
        "api:cloudapi",
        host=resolved_host,
        port=resolved_port,
        reload=resolved_reload,
        log_level=resolved_log_level,
    )


if __name__ == "__main__":
    logging.basicConfig(level=logging.INFO, format="%(asctime)s [%(levelname)s] %(name)s: %(message)s")
    main()
