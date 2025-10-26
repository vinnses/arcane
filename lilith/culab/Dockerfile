FROM pytorch/pytorch:2.8.0-cuda12.8-cudnn9-devel AS dev


RUN apt-get update && \
    apt-get install -y \
    curl \
    git \
    locales\
    sudo \
    vim && \
    rm -rf /var/lib/apt/lists/*

RUN locale-gen en_US.UTF-8

ARG LANG=en_US.UTF-8
ARG LC_ALL=en_US.UTF-8
ARG TZ=America/Sao_Paulo

RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime

ARG USER=devel
ARG UID=1000
ARG GID=1000

RUN groupadd --gid ${GID} ${USER}
RUN useradd --uid ${UID} --gid ${GID} -m -s /bin/bash ${USER}

RUN echo "${USER} ALL=(root) NOPASSWD:ALL" > /etc/sudoers.d/${USER} && \
    chmod 0440 /etc/sudoers.d/${USER}

# RUN chown -R ${UID}:${GID} /opt/conda

USER ${USER}
WORKDIR /workspace

RUN conda create -y --name culab --clone base

RUN conda init bash

RUN echo "conda activate culab" >> ~/.bashrc

SHELL ["conda", "run", "-n", "culab", "/bin/bash", "-c"]

RUN conda install -n culab -y jupyterlab pandas numpy matplotlib scikit-learn
#RUN pip install transformers huggingface-hub

EXPOSE 8888

COPY --chown=${USER}:${USER} entrypoint.sh /usr/local/bin/entrypoint.sh
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]

CMD ["jupyter", "lab", "/workspace", "--ip=0.0.0.0", "--port=8888", "--no-browser", "--allow-root", "--NotebookApp.token='123mudar'"]
