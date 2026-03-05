#!/bin/bash
set -e

# Ativa o ambiente Conda. A linha abaixo é mais robusta que 'conda activate'
# pois funciona em scripts não-interativos.
source /opt/conda/bin/activate culab

# Agora que o ambiente está ativo, o shell sabe onde encontrar 'jupyter'.
# O comando "exec $@" executa qualquer comando que for passado para este script.
# No nosso caso, será o CMD do Dockerfile.
exec "$@"