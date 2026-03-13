"""
Logging utilities.

Provides:
- setup_logging(): Configures root logger with console + optional file handler.
- get_log_path(): Generates mirrored log paths from script locations.
- TqdmLoggingHandler: Console handler that respects tqdm progress bars.
"""

from datetime import datetime
import logging
import logging.handlers
from pathlib import Path
import sys
from typing import Optional, Union

from myproject.config import LOG_DIR, PROJECT_ROOT

try:
    from tqdm import tqdm
    HAS_TQDM = True
except ImportError:
    HAS_TQDM = False


class TqdmLoggingHandler(logging.Handler):
    """Logging handler that uses tqdm.write() to avoid breaking progress bars."""

    def emit(self, record):
        try:
            msg = self.format(record)
            tqdm.write(msg)
            self.flush()
        except Exception:
            self.handleError(record)


def setup_logging(log_file_path: Optional[Union[str, Path]] = None) -> logging.Logger:
    """
    Configure the root logger with console and optional file output.

    Args:
        log_file_path: If provided, enables rotating file logging (10 MB, 5 backups).

    Returns:
        The configured root logger.
    """
    root_logger = logging.getLogger()
    if root_logger.hasHandlers():
        root_logger.handlers.clear()

    root_logger.setLevel(logging.DEBUG)

    # ── Formatters ──
    console_fmt = logging.Formatter(
        fmt="{asctime} | {levelname:<8} | {name}:{funcName}:{lineno} - {message}",
        datefmt="%H:%M:%S",
        style="{",
    )
    file_fmt = logging.Formatter(
        fmt="{asctime} | {levelname:<8} | {name:<25} | {funcName:<20} | {message}",
        datefmt="%Y-%m-%d %H:%M:%S",
        style="{",
    )

    # ── Console Handler ──
    if HAS_TQDM:
        console_handler = TqdmLoggingHandler()
    else:
        console_handler = logging.StreamHandler(sys.stderr)

    console_handler.setLevel(logging.DEBUG)
    console_handler.setFormatter(console_fmt)
    root_logger.addHandler(console_handler)

    # ── File Handler ──
    if log_file_path:
        log_path = Path(log_file_path)
        log_path.parent.mkdir(parents=True, exist_ok=True)

        file_handler = logging.handlers.RotatingFileHandler(
            log_path,
            maxBytes=10 * 1024 * 1024,
            backupCount=5,
            encoding="utf-8",
        )
        file_handler.setLevel(logging.DEBUG)
        file_handler.setFormatter(file_fmt)
        root_logger.addHandler(file_handler)

    # ── Noise Reduction ──
    for lib in ["urllib3", "filelock", "matplotlib", "PIL"]:
        logging.getLogger(lib).setLevel(logging.WARNING)

    # ── Priority for project code ──
    logging.getLogger("myproject").setLevel(logging.DEBUG)
    logging.getLogger("__main__").setLevel(logging.DEBUG)

    return root_logger


def get_log_path(script_file: Union[str, Path]) -> Path:
    """
    Generate a timestamped log file path mirroring the script's location.

    Args:
        script_file: The calling script's path (typically __file__).

    Returns:
        Path to the log file under the logs/ directory.
    """
    script_path = Path(script_file).resolve()

    try:
        relative_path = script_path.relative_to(PROJECT_ROOT)
    except ValueError:
        relative_path = Path(script_path.name)

    log_subdir = relative_path.parent / relative_path.stem
    timestamp = datetime.now().strftime("%Y%m%d%H%M%S")

    LOG_DIR.mkdir(parents=True, exist_ok=True)

    return LOG_DIR / log_subdir / f"{timestamp}.log"
