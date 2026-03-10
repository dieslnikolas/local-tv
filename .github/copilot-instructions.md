# Copilot Instructions

## Project Purpose

Local TV Stack is a self-hosted home media server built entirely with Docker Compose.
It combines Jellyfin (media playback), Radarr/Sonarr (automated movie/show downloading),
qBittorrent (torrent client), Prowlarr (indexer manager), FlareSolverr (Cloudflare bypass),
Bazarr (subtitle downloader), Homepage (dashboard), FileBrowser (web file manager), and
Glances (system monitor), with Watchtower handling automatic nightly image updates.

There is **no application source code** — this repo is pure infrastructure-as-code (Docker
Compose YAML + dashboard config YAML files).

---

## Repository Structure

```
local-tv/
├── docker-compose.yml      # Single Compose file defining all services
├── .env.example            # Template for required environment variables
├── .env                    # Local config (never committed — in .gitignore)
└── homepage/               # Dashboard config files copied to CONFIG_DIR on setup
    ├── bookmarks.yaml
    ├── docker.yaml
    ├── services.yaml
    ├── settings.yaml
    └── widgets.yaml
```

---

## Key Services and Ports (defaults, overridable via `.env`)

| Service       | Port  | Description                        |
|---------------|-------|------------------------------------|
| Jellyfin      | 8096  | Media server                       |
| Homepage      | 3000  | Dashboard                          |
| qBittorrent   | 8080  | Torrent client                     |
| Prowlarr      | 9696  | Indexer manager                    |
| FlareSolverr  | 8191  | Cloudflare bypass                  |
| Radarr        | 7878  | Movie automation                   |
| Sonarr        | 8989  | TV show automation                 |
| Bazarr        | 6767  | Subtitle downloader                |
| Glances       | 61208 | System monitor                     |
| FileBrowser   | 8081  | Web file manager                   |
| Watchtower    | —     | Auto-updates containers at 04:00   |

---

## Environment Variables

All runtime configuration lives in `.env` (copy from `.env.example`). The three required
variables are:

- `HOST_IP` — LAN IP of the host machine
- `MEDIA_DIR` — absolute path to media storage (mounted as `/data` in containers)
- `CONFIG_DIR` — absolute path for service config/database persistence

All ports are configurable via `PORT_*` variables. API keys for the Homepage dashboard
widgets are optional but enable live service stats.

---

## Contribution Guidelines

- **All changes go through `docker-compose.yml`** — this is the single source of truth for
  the stack.
- **Environment variables only** — never hardcode IPs, paths, passwords, or ports. Always
  use the corresponding `${VARIABLE}` placeholder.
- **Use existing image conventions** — most images are `lscr.io/linuxserver/*`; they share
  `PUID`, `PGID`, `TZ` environment variables and the `/config` volume pattern. Follow this
  pattern for any new services.
- **Validate the Compose file** after every change:
  ```bash
  docker compose config
  ```
- **Prefer `restart: unless-stopped`** for all long-running services.
- **Keep the `homepage/` YAML files in sync** with any service additions or port changes —
  they define the dashboard widgets.
- **Update `.env.example`** when adding new environment variables — include a comment
  explaining where to find the value.
- **Update `README.md`** when adding services, changing ports, or altering setup steps.

---

## Common Commands

```bash
# Validate Compose file (no Docker daemon needed for syntax check)
docker compose config

# Start all services
docker compose up -d

# Stop all services
docker compose down

# Tail logs for a specific service
docker compose logs <service-name> -f

# Pull latest images and restart
docker compose pull && docker compose up -d

# Restart a single service
docker compose restart <service-name>
```

---

## Key Principles

- **Hardlinks over copies** — `MEDIA_DIR` is mounted as `/data` in every container so
  Radarr/Sonarr can hardlink from `downloads/` to `movies/` or `shows/` without
  duplicating data on disk.
- **Internal networking** — containers communicate by service name (e.g., `radarr`,
  `qbittorrent`) over the default Compose bridge network; never use `HOST_IP` for
  inter-container communication.
- **No secrets in git** — `.env` is listed in `.gitignore`; keep it that way.
