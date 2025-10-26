FROM python:3.12-slim

# ENV POETRY_NO_INTERACTION=1
# ENV POETRY_VIRTUALENVS_IN_PROJECT=false

ENV POETRY_NO_INTERACTION=1 \
    POETRY_VIRTUALENVS_IN_PROJECT=true \
    POETRY_VIRTUALENVS_CREATE=true \
    PATH="/workspace/.venv/bin:$PATH"


RUN apt-get update && apt-get install -y sudo \
    git \
    vim \
    make \
    curl \
    ca-certificates && \
    rm -rf /var/lib/apt/lists/* &&\
    update-ca-certificates

ARG USER=devel
ARG UID=1000
ARG GID=1000

RUN if ! getent group ${GID} >/dev/null 2>&1; then \
    groupadd --gid ${GID} ${USER}; \
    fi

RUN if id -u ${USER} >/dev/null 2>&1; then \
    usermod --uid ${UID} --gid ${GID} ${USER}; \
    else \
    useradd --uid ${UID} --gid ${GID} -m -s /bin/bash ${USER}; \
    fi

RUN echo "${USER} ALL=(root) NOPASSWD:ALL" > /etc/sudoers.d/${USER} && \
    chmod 0440 /etc/sudoers.d/${USER}

USER ${USER}

RUN pip install poetry

# RUN curl -sSL https://install.python-poetry.org | python3 -
ENV PATH="/home/${USER}/.local/bin:${PATH}"

# RUN poetry config repositories.pypi https://pypi.org/simple
# RUN poetry config http-basic.pypi "" ""

ARG PROJECT_ROOT=/workspace

WORKDIR ${PROJECT_ROOT}

#COPY . .
RUN mkdir lifelog && touch lifelog/__init__.py

COPY pyproject.toml poetry.lock README.md LICENSE ./

# RUN poetry install --no-root
RUN poetry install

# RUN poetry run python -m ipykernel install --name="lifelog-kernel" --display-name="lifelog Kernel"

# Usar poetry run para executar comandos, ou adicionar ao bashrc
# RUN echo 'if [ -f "${PROJECT_ROOT}/pyproject.toml" ]; then source $(poetry env info --path)/bin/activate 2>/dev/null || true; fi' >> /home/${USER}/.bashrc
