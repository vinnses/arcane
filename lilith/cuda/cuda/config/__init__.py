"""
Global configuration module.

Handles:
1. Global directory definitions (Data, Logs).
2. Simple config file loading (YAML, JSON, TOML).
"""

import json
import logging
from pathlib import Path
import tomllib

import yaml

from cuda import PACKAGE_ROOT, PROJECT_ROOT

logger = logging.getLogger(__name__)

# ── Directory Definitions ────────────────────────────────────────────────────
DATA = PROJECT_ROOT / "data"
LOGS = PROJECT_ROOT / "logs"
LOG_DIR = LOGS

# ── Default Settings Path ────────────────────────────────────────────────────
DEFAULT_SETTINGS = PACKAGE_ROOT / "config" / "settings.yaml"


def load_config(path: Path | str | None = None) -> dict:
    """
    Parse a configuration file based on its extension.

    Supports YAML (.yaml, .yml), JSON (.json), and TOML (.toml).
    Defaults to the built-in settings.yaml if no path is provided.

    Args:
        path: Path to the configuration file. If None, loads default settings.

    Returns:
        Parsed configuration as a dictionary.

    Raises:
        FileNotFoundError: If the file does not exist.
        ValueError: If the file extension is not supported.
    """
    filepath = Path(path) if path else DEFAULT_SETTINGS

    if not filepath.exists():
        raise FileNotFoundError(f"Config file not found: {filepath}")

    suffix = filepath.suffix.lower()

    if suffix in (".yaml", ".yml"):
        with open(filepath, "r", encoding="utf-8") as f:
            return yaml.safe_load(f) or {}

    if suffix == ".json":
        with open(filepath, "r", encoding="utf-8") as f:
            return json.load(f)

    if suffix == ".toml":
        with open(filepath, "rb") as f:
            return tomllib.load(f)

    raise ValueError(f"Unsupported config format: {suffix}")


__all__ = [
    "DATA",
    "LOGS",
    "LOG_DIR",
    "load_config",
]
