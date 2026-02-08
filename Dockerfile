# OpenClaw Docker Stack – baut aus offiziellem GitHub-Repo
# Siehe https://docs.openclaw.ai/install/docker

ARG OPENCLAW_REPO=https://github.com/openclaw/openclaw.git
ARG OPENCLAW_REF=main

FROM node:22-bookworm AS builder

# Bun für Build-Skripte (laut offiziellem OpenClaw Dockerfile)
RUN curl -fsSL https://bun.sh/install | bash
ENV PATH="/root/.bun/bin:${PATH}"

RUN corepack enable

WORKDIR /app

# OpenClaw-Quellcode klonen
RUN apt-get update && apt-get install -y --no-install-recommends git \
  && rm -rf /var/lib/apt/lists/* \
  && git clone --depth 1 --branch "${OPENCLAW_REF}" "${OPENCLAW_REPO}" . || git clone --depth 1 "${OPENCLAW_REPO}" .

ARG OPENCLAW_DOCKER_APT_PACKAGES=""
RUN if [ -n "$OPENCLAW_DOCKER_APT_PACKAGES" ]; then \
  apt-get update && \
  DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends $OPENCLAW_DOCKER_APT_PACKAGES && \
  apt-get clean && rm -rf /var/lib/apt/lists/* /var/cache/apt/archives/*; \
  fi

# Abhängigkeiten (Layer-Cache)
RUN pnpm install --frozen-lockfile

# Build
RUN OPENCLAW_A2UI_SKIP_MISSING=1 pnpm build
ENV OPENCLAW_PREFER_PNPM=1
RUN pnpm ui:build

# Runtime-Stage
FROM node:22-bookworm

ARG OPENCLAW_DOCKER_APT_PACKAGES=""
RUN if [ -n "$OPENCLAW_DOCKER_APT_PACKAGES" ]; then \
  apt-get update && \
  DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends $OPENCLAW_DOCKER_APT_PACKAGES && \
  apt-get clean && rm -rf /var/lib/apt/lists/* /var/cache/apt/archives/*; \
  fi

WORKDIR /app

# Vollständigen Build übernehmen (Monorepo: dist + node_modules + packages)
COPY --from=builder /app .
RUN rm -rf .git 2>/dev/null || true

ENV NODE_ENV=production

RUN chown -R node:node /app
USER node

# Gateway-Start (Compose überschreibt command für --bind/--port)
CMD ["node", "dist/index.js", "gateway", "--allow-unconfigured"]
