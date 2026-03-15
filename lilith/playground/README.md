# Data Science Workspace

Containerized Python data science workspace with multiple access modes.

**Stack:** Python 3.12 · UV · Docker · Jupyter · VS Code

## Quick Start

### 1. Initialize your project

```bash
# Edit .env with your project name
vim .env  # Set PROJECT=yourname

# Run the init script to rename the package
bash scripts/init_project.sh
```

### 2. Choose your access mode

| Mode | Command | Access |
|:-----|:--------|:-------|
| **VS Code (devcontainer)** | Open folder in VS Code | Editor attaches to container |
| **Jupyter Lab** | `make jupyter` | Browser → `localhost:8888` |
| **Jupyter Notebook** | `make notebook` | Browser → `localhost:8888` |
| **Code Server** | `make code-server` | Browser → `localhost:8443` |
| **Shell** | `docker compose --profile dev up -d && docker exec -it <name>-dev bash` | Terminal |

### 3. Manual setup (without Docker)

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
├── <project>/         # Python package
│   ├── config/        # Settings loader + YAML
│   └── utils/         # Logging and helpers
├── notebooks/         # Jupyter notebooks
├── data/              # Data files (gitignored)
├── tests/             # pytest tests
├── Dockerfile         # Single image, all tools
├── compose.yaml       # Profiles: dev, jupyter, code-server
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

**Dev:** pytest, ruff
