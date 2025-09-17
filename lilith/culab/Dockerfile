FROM pytorch/pytorch:2.8.0-cuda12.8-cudnn9-devel AS devel


RUN apt-get update && \
    apt-get install -y \
    curl \
    git \
    gnupg \
    locales\
    sudo \
    vim && \
    rm -rf /var/lib/apt/lists/*

RUN locale-gen en_US.UTF-8

ARG LANG=en_US.UTF-8
ARG LC_ALL=en_US.UTF-8
ARG TZ=America/Sao_Paulo

RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime

RUN curl -fsSL https://code-server.dev/install.sh | sh

ENV USER=devel
ENV UID=1000
ENV GID=1000

RUN groupadd --gid ${GID} ${USER}
RUN useradd --uid ${UID} --gid ${GID} -m -s /bin/bash ${USER}

RUN echo "${USER} ALL=(root) NOPASSWD:ALL" > /etc/sudoers.d/${USER} && \
    chmod 0440 /etc/sudoers.d/${USER}

USER ${USER}

WORKDIR /workspace

#RUN chown -R ${UID}:${GID} /workspace

#CMD ["code-server", "--bind-addr", "0.0.0.0:8080"]
