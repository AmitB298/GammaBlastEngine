from __future__ import annotations
import json
import os
from pathlib import Path
from typing import Any, Dict
from pydantic import BaseModel, Field, ConfigDict

ENV_FILE = Path(".env")  # optional


def _load_dotenv_simple(path: Path) -> None:
    """Simple .env loader (key=value per line)."""
    if not path.exists():
        return
    for line in path.read_text(encoding="utf-8").splitlines():
        line = line.strip()
        if not line or line.startswith("#") or "=" not in line:
            continue
        key, val = line.split("=", 1)
        os.environ.setdefault(key.strip(), val.strip())


class Settings(BaseModel):
    """Global runtime configuration for GammaBlastEngine."""

    model_config = ConfigDict(arbitrary_types_allowed=True)

    env: str = Field(default_factory=lambda: os.getenv("GBE_ENV", "dev"))
    toggles_path: Path = Field(default=Path("configs/defaults.toggles.json"))


def load_settings() -> Settings:
    """Load .env (if present) and build a Settings object."""
    _load_dotenv_simple(ENV_FILE)
    return Settings()


def load_toggles(path: Path) -> Dict[str, Any]:
    """Read a JSON toggle file safely."""
    try:
        return json.loads(path.read_text(encoding="utf-8"))
    except FileNotFoundError:
        return {}
    except Exception:
        return {}


def save_toggles(path: Path, data: Dict[str, Any]) -> None:
    """Write a toggle file (pretty-printed JSON)."""
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(
        json.dumps(data, indent=2, ensure_ascii=False),
        encoding="utf-8",
    )
