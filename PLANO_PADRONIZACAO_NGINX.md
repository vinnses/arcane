# Plano de padronização (Nginx Lilith como padrão)

## Objetivo
Padronizar os projetos de `asmodeus` e `lilith` com base no modelo de Nginx do Lilith, incorporando fallback por path (modelo Asmodeus) e ajustes operacionais para evitar serviços órfãos, conflitos de nomes e riscos de concorrência em backup/sync.

## Diretrizes acordadas
- Usar o padrão de Nginx do `lilith` como base (vhosts + snippets).
- Incorporar fallback por path (estilo `asmodeus`) como camada complementar.
- Remover blocos de serviços arquivados/inativos do Nginx.
- Evitar `container_name` genérico; usar nomes semânticos por contexto.
- Não depender de `name:` no `compose.yaml` quando o nome padrão do diretório já for suficiente.
- Tratar `kopia` e `webdav` com política de single-writer/single-endpoint para evitar conflito.

## Etapa 1 — Inventário e limpeza de serviços ativos
1. Mapear serviços ativos por host (`asmodeus` e `lilith`) e separar do que está em `archived/`.
2. Ajustar `nginx.conf` para manter somente upstreams realmente ativos.
3. Aplicar a regra específica atual:
   - manter/reintegrar `btop` no Lilith;
   - retirar `jellyfin` do roteamento Nginx se ele sair do conjunto ativo.
4. Validar que não existem `server_name` apontando para serviços inexistentes.

## Etapa 2 — Padronização de nomenclatura e Compose
1. Padronizar `container_name` com nomes significativos, por exemplo:
   - `lilith-nginx`, `lilith-obsidian-syncthing`, `asmodeus-kopia`.
2. Revisar aliases e hostnames para manter clareza operacional em logs e troubleshooting.
3. Remover `name:` dos `compose.yaml` onde ele for redundante.
4. Revisar nomes de network/volume para consistência entre projetos.

## Etapa 3 — Unificação do padrão de Nginx (base Lilith + fallback Asmodeus)
1. Manter arquitetura de vhosts por domínio/subdomínio (padrão Lilith).
2. Consolidar snippets de proxy por classe de serviço:
   - `proxy_params.conf` (padrão);
   - snippets especializados (upload grande, timeout alto, websocket).
3. Adicionar fallback por path em um `server` catch-all, com rota explícita para serviços críticos (ex.: `/kopia/`, `/sync/`, `/zotero/`).
4. Definir convenção única de health endpoint (`/health`) para todos os blocos que fizerem sentido.
5. Garantir logs por serviço (access/error) para facilitar diagnóstico.

## Etapa 4 — Política de segurança operacional (Kopia/WebDAV/Sync)
1. **Kopia**:
   - definir política de single-writer por repositório;
   - evitar duas instâncias gravando no mesmo repo simultaneamente;
   - se houver redundância, usar repo por host ou replicação controlada do storage.
2. **WebDAV (Zotero)**:
   - manter endpoint único para cliente;
   - evitar alternância ativa entre dois servidores sem coordenação.
3. **Sincronização/espelhamento**:
   - documentar estratégia (rsync/rclone/snapshot) e janela operacional;
   - priorizar consistência de dados em vez de “active-active” sem lock distribuído.

## Checkpoints de validação por etapa
- `docker compose config` em cada projeto alterado.
- `nginx -t` no container/projeto Nginx.
- Smoke test de rotas:
  - por vhost (`service.host.hell`);
  - por fallback path (`/service/`) quando aplicável.
- Checklist de regressão:
  - não há upstream órfão;
  - não há nome ambíguo de container;
  - nenhuma rota crítica perdeu acesso.

## Entregáveis esperados
- `compose.yaml` padronizados sem ruído.
- `nginx.conf` limpo, consistente e com fallback controlado.
- Convenção de naming documentada.
- Nota operacional com política de concorrência para Kopia/WebDAV.
