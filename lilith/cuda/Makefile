#################################################################################
# GLOBALS                                                                       #
#################################################################################

PYTHON = python
UV = uv
PROJECT = cuda

ifneq (,$(wildcard ./.env))
    include .env
    export
endif

VENV_PATH := .venv
LOCKFILE := uv.lock

#################################################################################
# ENVIRONMENT & DEPENDENCY MANAGEMENT                                           #
#################################################################################

export PATH := $(HOME)/.local/bin:$(PATH)

## Install uv (system level)
.PHONY: install
install:
	@echo ">>> Checking system requirements..."
	@command -v uv >/dev/null 2>&1 || (echo ">>> Installing uv..." && curl -LsSf https://astral.sh/uv/install.sh | sh)
	@echo ">>> Toolchain ready."

## Show environment activation options
.PHONY: info
info:
	@echo ""
	@echo "======================================================================"
	@echo "  ENVIRONMENT CONFIGURATION"
	@echo "----------------------------------------------------------------------"
	@echo "  1. Nested Shell : uv run bash"
	@echo "  2. Manual       : source $(VENV_PATH)/bin/activate"
	@echo "  3. Standalone   : uv run python -m module"
	@echo "======================================================================"

## Install main deps only (production)
.PHONY: build
build:
	@echo ">>> Production build: main dependencies only."
	$(MAKE) sync-prod

## Install everything (main + notebook + science + dev)
.PHONY: dev
dev:
	@echo ">>> Setting up full development environment..."
	$(MAKE) sync-dev
	@$(MAKE) info

## Generate lockfile
.PHONY: lock
lock:
	@echo ">>> Creating lockfile..."
	@rm -f $(LOCKFILE)
	uv lock

## Sync dev environment
.PHONY: sync-dev
sync-dev:
	@echo ">>> Syncing full environment..."
	@if uv sync --locked --all-extras --all-groups; then \
	    echo ">>> Sync OK."; \
	else \
	    echo ">>> Lockfile invalid. Rebuilding..."; \
	    $(MAKE) lock; \
	    uv sync --locked --all-extras --all-groups; \
	fi

## Sync production environment
.PHONY: sync-prod
sync-prod:
	@echo ">>> Syncing production environment..."
	@if uv sync --locked --no-dev; then \
	    echo ">>> Sync OK."; \
	else \
	    echo ">>> Lockfile invalid. Rebuilding..."; \
	    $(MAKE) lock; \
	    uv sync --locked --no-dev; \
	fi

## Verify environment
.PHONY: test-env
test-env:
	uv run $(PYTHON) --version
	uv run $(PYTHON) -c "import sys; print(f'Python: {sys.executable}')"
	uv run $(PYTHON) -c "import $(PROJECT); print(f'Package: {$(PROJECT)}')"

#################################################################################
# CODE QUALITY & TESTING                                                        #
#################################################################################

## Lint (check only)
.PHONY: lint
lint:
	uv run ruff format --check
	uv run ruff check

## Format source code
.PHONY: format
format:
	uv run ruff check --fix
	uv run ruff format

## Run tests
.PHONY: test
test:
	uv run pytest tests

#################################################################################
# CONVENIENCE TARGETS (DOCKER PROFILES)                                         #
#################################################################################

## Start Jupyter Lab
.PHONY: jupyter
jupyter:
	docker compose --profile jupyter up

## Start Jupyter Notebook (classic)
.PHONY: notebook
notebook:
	docker compose --profile jupyter run --rm -p $(JUPYTER_PORT):8888 jupyter \
		jupyter notebook --ip=0.0.0.0 --port=8888 --no-browser \
		--NotebookApp.token=$(JUPYTER_TOKEN)

## Start Code Server
.PHONY: code-server
code-server:
	docker compose --profile code-server up

## Start Btop (GPU monitor)
.PHONY: btop
btop:
	docker compose --profile btop up

#################################################################################
# CLEANUP                                                                       #
#################################################################################

CLEAN_DIRS := .pytest_cache .ruff_cache .mypy_cache .ipynb_checkpoints
CONFIRM_MSG = 🔴 Confirm with "$(1)" or press Enter to cancel

## Remove compiled files and caches
.PHONY: clean
clean:
	find . -type f -name "*.py[co]" -delete
	find . -type d -name "__pycache__" -exec rm -rf {} + 2>/dev/null || true
	find . -type d -name ".ipynb_checkpoints" -exec rm -rf {} + 2>/dev/null || true
	for dir in $(CLEAN_DIRS); do \
		find . -type d -name "$$dir" -exec rm -rf {} + 2>/dev/null || true; \
	done
	find . -type d -name ".tmp*" -exec rm -rf {} + 2>/dev/null || true

## Remove virtual environment (requires confirmation)
.PHONY: purge-venv
purge-venv:
	@echo "$(call CONFIRM_MSG,venv)"
	@read ans; \
	case "$$ans" in \
		venv) rm -rf .venv ;; \
		*) echo "❌ Canceled." ;; \
	esac

## Remove data directory (requires confirmation)
.PHONY: purge-data
purge-data:
	@echo "$(call CONFIRM_MSG,data)"
	@read ans; \
	case "$$ans" in \
		data) rm -rf data/* 2>/dev/null || true ;; \
		*) echo "❌ Canceled." ;; \
	esac

## Remove logs (requires confirmation)
.PHONY: purge-logs
purge-logs:
	@echo "$(call CONFIRM_MSG,logs)"
	@read ans; \
	case "$$ans" in \
		logs) \
			find . -type f -name "*.log" -delete 2>/dev/null || true; \
			rm -rf logs/* 2>/dev/null || true ;; \
		*) echo "❌ Canceled." ;; \
	esac

## Nuclear: purge everything
purge-all: clean purge-venv purge-logs purge-data

#################################################################################
# DOCKER CONTROLLER                                                             #
#################################################################################

define BLOCK_IN_DOCKER
	@if [ -f /.dockerenv ]; then \
		echo "❌ ERROR: '$(MAKECMDGOALS)' cannot run inside a container."; \
		exit 1; \
	fi
endef

.PHONY: docker-down docker-clean docker-purge

docker-down:
	$(BLOCK_IN_DOCKER)
	docker compose -p $(COMPOSE_PROJECT_NAME) down

docker-clean:
	$(BLOCK_IN_DOCKER)
	docker compose -p $(COMPOSE_PROJECT_NAME) down --rmi all --remove-orphans

docker-purge:
	$(BLOCK_IN_DOCKER)
	@echo "🔴 WARNING: This will delete containers, images, and volumes."
	@echo -n "Type '$(COMPOSE_PROJECT_NAME)' to confirm: "; \
	read ans; \
	if [ "$$ans" != "$(COMPOSE_PROJECT_NAME)" ]; then \
		echo "❌ Canceled."; \
		exit 1; \
	fi
	docker compose -p $(COMPOSE_PROJECT_NAME) down --rmi all --volumes --remove-orphans

#################################################################################
# UTILITY                                                                       #
#################################################################################

## Keep container alive for attach
.PHONY: sleep
sleep:
	@echo ">>> Sleeping (waiting for attach)..."
	sleep infinity

#################################################################################
# HELP                                                                          #
#################################################################################

.DEFAULT_GOAL := help

define PRINT_HELP_PYSCRIPT
import re, sys; \
lines = '\n'.join([line for line in sys.stdin]); \
matches = re.findall(r'\n## (.*)\n[\s\S]+?\n([a-zA-Z_-]+):', lines); \
print('Available rules:\n'); \
print('\n'.join(['{:25}{}'.format(*reversed(match)) for match in matches]))
endef
export PRINT_HELP_PYSCRIPT

help:
	@uv run $(PYTHON) -c "$$PRINT_HELP_PYSCRIPT" < $(MAKEFILE_LIST)
