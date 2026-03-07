Generate `.devcontainer/Dockerfile` and `.devcontainer/devcontainer.json` for this project.

## Two-layer architecture

There is a two-layer Docker setup for devcontainers:

**Layer 1 (base project container)** — A Dockerfile that contains everything needed to *build and run the project itself*: language runtimes, system libraries, databases, etc. This is what lives in `.devcontainer/` and is what YOU are generating.

**Layer 2 (dispatch wrapper)** — A separate Dockerfile (outside the project) that wraps Layer 1 with everything needed for *Claude Code to work on the project*: Node.js, Claude Code CLI, GitHub CLI, firewall tools, sudo, etc. You do NOT generate this layer — it is handled automatically by the `dc-build` script.

Your job is to generate Layer 1 only.

## Steps

### 1. Detect the project stack

Scan config files to identify languages, runtimes, package managers, system dependencies, and services. Check files like: `package.json`, `pyproject.toml`, `Makefile`, `requirements.txt`, `go.mod`, `Cargo.toml`, `Gemfile`, `docker-compose.yml`, CI workflows (`.github/workflows/`), `.tool-versions`, `.node-version`, `.python-version`, `.nvmrc`, etc.

### 2. Generate `.devcontainer/Dockerfile`

Rules:
- Use a `mcr.microsoft.com/devcontainers/` base image (these include a `vscode` user):
  - Python: `python:1-<version>-bookworm`
  - Node-only: `javascript-node:1-<version>-bookworm`
  - Go: `go:1-<version>-bookworm`
  - Multi-language or other: `base:bookworm` + manual installs
- Install only what the project needs to build and run
- **Do NOT install** things handled by Layer 2: Claude Code, gh CLI, iptables, ipset, iproute2, dnsutils, jq, or sudo. (Node.js/npm ARE fine if the project itself needs them.)
- **Do NOT add** a `USER` directive — Layer 2 handles this
- Build context is the repo root (not `.devcontainer/`), so COPY paths are relative to repo root (e.g. `COPY .devcontainer/script.sh /usr/local/bin/script.sh`)

### 3. Generate `.devcontainer/devcontainer.json`

The dispatch scripts only parse two fields from this file:
- `postCreateCommand` (string) — runs after container creation to install project deps
- `mounts` (array of strings) — additional Docker mounts (e.g. caches)

Also include standard fields for VS Code compatibility: `name`, `build.dockerfile`, `build.context`.

**Note:** The `features` field (e.g. Docker-in-Docker) is NOT supported by the dispatch scripts — they use `docker run` directly, not the devcontainer CLI. If features like Docker-in-Docker are needed, install them directly in the Dockerfile.

### 4. Create the files

Write both files into `.devcontainer/`.

## Key constraint: do NOT install Claude Code

The `dc-build` wrapper already installs Claude Code, Node.js 20, gh CLI, sudo, iptables, ipset, iproute2, dnsutils, jq, firewall init script, and sets `USER vscode`. The base Dockerfile must only contain project-specific dependencies.

## Lessons learned

### Stale Yarn apt source in devcontainer base images
The `mcr.microsoft.com/devcontainers/python` (and possibly other) base images include a Yarn apt repo (`https://dl.yarnpkg.com/debian`) with an expired GPG key. Remove it before `apt-get update`:
```dockerfile
RUN rm -f /etc/apt/sources.list.d/yarn.list \
    && apt-get update && ...
```

### NodeSource: use the modern repo setup, not setup_XX.x
The `setup_20.x` script is deprecated and installs Debian's Node.js 18 instead. Use the manual GPG key + repo approach:
```dockerfile
RUN mkdir -p /etc/apt/keyrings \
    && curl -fsSL https://deb.nodesource.com/gpgkey/nodesource-repo.gpg.key \
       | gpg --dearmor -o /etc/apt/keyrings/nodesource.gpg \
    && echo "deb [signed-by=/etc/apt/keyrings/nodesource.gpg] https://deb.nodesource.com/node_20.x nodistro main" \
       > /etc/apt/sources.list.d/nodesource.list
```

### Baking dependencies into the image
The workspace is mounted at `/workspace` at runtime, overlaying anything the image had there. This means:
- **Python deps**: Install globally with `pip install`. Set `ENV PYTHONPATH=/workspace/backend` (or wherever the project code lives) so the project's own modules are importable without `pip install -e`.
- **Node.js deps**: `node_modules` must exist inside the mounted workspace, so `npm install` must run at startup. Pre-populate the npm cache during build (`npm ci --ignore-scripts` in a temp dir) so the runtime `npm install` is near-instant.

### Services needed by tests
If the project needs services (databases, caches, etc.) for tests, prefer installing them directly in the Dockerfile and starting them via the entrypoint script. This avoids Docker-in-Docker complexity and lets `dc-connect` run without `--privileged`.
