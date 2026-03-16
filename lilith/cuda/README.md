# CUDA GPU Compute Workspace

Consolidated CUDA/GPU compute environment with Jupyter, VS Code, and system monitoring via btop.

**Stack:** Python 3.12 · UV · Docker · Jupyter · VS Code · btop + GoTTY · CUDA 12.8

## Services

| Service | Command | Access |
|:--------|:--------|:-------|
| **VS Code (devcontainer)** | Open folder in VS Code | Editor attaches to container |
| **Jupyter Lab** | `make jupyter` | `jupyter.lilith.hell` / `localhost:8888` |
| **Jupyter Notebook** | `make notebook` | `localhost:8888` |
| **Code Server** | `make code-server` | `code.lilith.hell` / `localhost:8443` |
| **Btop (GPU monitor)** | `make btop` | `btop.lilith.hell` / `localhost:8686` |
| **Dev Shell** | `docker compose --profile dev up -d && docker exec -it cuda-dev bash` | Terminal |

## Quick Start

```bash
cp .env.example .env
# Edit .env as needed

make jupyter      # Start Jupyter Lab
make code-server  # Start VS Code in browser
make btop         # Start GPU/system monitor
```

### Local setup (without Docker)

```bash
make install   # Install uv
make dev       # Create venv + install all deps
source .venv/bin/activate
```

## Project Structure

```
.
├── .devcontainer/     # VS Code devcontainer config
├── .scripts/          # Shell customizations
├── btop/              # btop config and themes
│   ├── btop.conf
│   └── themes/
├── cuda/              # Python package
│   ├── config/        # Settings loader + YAML
│   └── utils/         # Logging and helpers
├── notebooks/         # Jupyter notebooks
├── data/              # Data files (gitignored)
├── tests/             # pytest tests
├── Dockerfile         # Main workspace image (pytorch base)
├── Dockerfile.btop    # Btop + GoTTY image (nvidia/cuda base)
├── compose.yaml       # Profiles: dev, jupyter, code-server, btop
├── Makefile           # UV lifecycle + convenience targets
└── pyproject.toml     # Dependencies and tool config
```

## Makefile Targets

```bash
make help          # Show all targets
make dev           # Full environment sync
make build         # Production deps only
make lint          # Check with ruff
make format        # Auto-fix with ruff
make test          # Run pytest
make clean         # Remove caches
make docker-down   # Stop containers
make docker-clean  # Remove containers + images
make docker-purge  # Remove everything including volumes
```

## Dependencies

**Main:** pandas, pyyaml, python-dotenv

**Notebook:** jupyterlab, ipykernel, ipywidgets, notebook

**Science:** matplotlib, seaborn, scikit-learn, scipy

**DL:** transformers, datasets, accelerate, tensorflow

**Dev:** pytest, ruff
