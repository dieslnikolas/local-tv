# Local TV Stack

Home media server: Jellyfin + automated downloading via Radarr/Sonarr.

## Services

| Service | Port | Description |
|---------|------|-------------|
| **Jellyfin** | 8096 | Media server |
| **Homepage** | 3000 | Dashboard |
| **qBittorrent** | 8080 | Torrent client |
| **Prowlarr** | 9696 | Indexer manager |
| **FlareSolverr** | 8191 | Cloudflare bypass (for 1337x etc.) |
| **Radarr** | 7878 | Movie automation |
| **Sonarr** | 8989 | TV show automation |
| **Bazarr** | 6767 | Subtitle downloads |
| **Glances** | 61208 | System monitor |
| **FileBrowser** | 8081 | Web file manager (upload subtitles etc.) |
| **Watchtower** | — | Auto-updates containers daily at 4:00 |

---

## Quick Start

**Requirements:** Docker + Docker Compose plugin on any Linux host (or WSL2).

```bash
git clone <repo> local-tv && cd local-tv
cp .env.example .env
$EDITOR .env
```

Set at minimum: `HOST_IP`, `MEDIA_DIR`, `CONFIG_DIR` — see [.env.example](.env.example) for all variables and descriptions.

Load the variables from `.env` into your current shell, then create the required directories and copy Homepage config:
```bash
set -a && source .env && set +a
mkdir -p "$MEDIA_DIR"/{media/{movies,tv},torrents/{movies,tv}}
mkdir -p "$CONFIG_DIR/homepage"
cp homepage/* "$CONFIG_DIR/homepage/"
```

Start:
```bash
docker compose up -d
```

---

## Configuration

After first start, configure each service once. All URLs use your `HOST_IP`.

### qBittorrent (`:8080`)

> **First login:** qBittorrent v5+ generates a random temporary password on first run.
> Get it from logs: `docker logs qbittorrent 2>&1 | grep -i password`
> Username is `admin`. Then set a permanent password in Settings → Web UI.

1. Settings → Downloads → Default Save Path: `/data/torrents`
2. Settings → Downloads → Categories:
   - `movies` → `/data/torrents/movies`
   - `tv` → `/data/torrents/tv`

### Jellyfin (`:8096`)
1. Run setup wizard, create admin account
2. Add libraries: Movies → `/data/media/movies`, Shows → `/data/media/tv`
3. Dashboard → API Keys → create a key and put it in `.env` as `JELLYFIN_API_KEY`
4. **Hardware acceleration (optional):** see [GPU Acceleration](#gpu-acceleration) below

### Radarr (`:7878`)
1. Settings → Media Management → Root Folders → `/data/media/movies`
2. Settings → Download Clients → `+` → qBittorrent: host `qbittorrent`, port `8080`, username `admin`, password from `.env`, category `movies`
3. Settings → Connect → `+` → Emby/Jellyfin: host `jellyfin`, port `8096`, API key from `.env`
4. Settings → General → API Key → copy to `.env` as `RADARR_API_KEY`

### Sonarr (`:8989`)
1. Settings → Media Management → Root Folders → `/data/media/tv`
2. Settings → Download Clients → `+` → qBittorrent: host `qbittorrent`, port `8080`, username `admin`, password from `.env`, category `tv`
3. Settings → Connect → `+` → Emby/Jellyfin: same as Radarr
4. Settings → General → API Key → copy to `.env` as `SONARR_API_KEY`

### Prowlarr (`:9696`)
> Needs Radarr and Sonarr API keys — grab them first (previous step).

1. Settings → Indexer Proxies → `+` → FlareSolverr: host `http://flaresolverr:8191`, tag `flare`
2. Settings → Apps → `+` → Radarr: host `radarr`, port `7878`, API key from `.env`
3. Settings → Apps → `+` → Sonarr: host `sonarr`, port `8989`, API key from `.env`
4. Indexers → `+` → e.g. `1337x` → tag `flare` → Test → Save
5. Settings → General → API Key → copy to `.env` as `PROWLARR_API_KEY`

### Bazarr (`:6767`)
1. Settings → Radarr: `http://radarr:7878` + API key from `.env` → Save
2. Settings → Sonarr: `http://sonarr:8989` + API key from `.env` → Save
3. Settings → Languages → `+` profile: Czech (priority 1), English (priority 2)
4. Apply the profile to both Radarr and Sonarr sections in Bazarr settings
5. Settings → Providers → `+` → OpenSubtitles.com (free account needed)
6. System → Tasks → **Search for missing subtitles** (run once to backfill)
7. Settings → General → API Key → copy to `.env` as `BAZARR_API_KEY`

### FileBrowser (`:8081`)

> **First login:** FileBrowser generates a random password on first run.
> Get it from logs: `docker logs filebrowser 2>&1 | grep password`
> Username is `admin`. Then change the password in Settings.

1. Settings (top right) → User Management → admin → change password → Save
2. Two folders are available:
   - `/media` — all media files (movies, shows, downloads)
   - `/config` — service configs, including Homepage YAML files at `/config/homepage/`

Edit Homepage config directly in the browser: navigate to `/config/homepage/`, click a `.yaml` file → Edit. Changes take effect immediately without restarting anything.

### API keys for Homepage dashboard
After filling in all API keys in `.env`, restart to apply:
```bash
docker compose up -d
```
See [.env.example](.env.example) for the full list of variables.

---

## Folder structure

```
local-tv/
├── docker-compose.yml
├── docker-compose.gpu.yml  ← GPU acceleration override (optional)
├── .env                    ← your local config (not in git)
├── .env.example            ← template
└── (CONFIG_DIR)/           ← service configs (create this and subfolders manually)
    ├── jellyfin/
    ├── qbittorrent/
    ├── radarr/
    ├── sonarr/
    ├── prowlarr/
    ├── bazarr/
    ├── homepage/
    └── filebrowser/

(MEDIA_DIR)/                ← mounted as /data in all containers
├── media/
│   ├── movies/             ← Radarr root folder / Jellyfin Movies library
│   └── tv/                 ← Sonarr root folder / Jellyfin TV Shows library
└── torrents/
    ├── movies/             ← qBittorrent category "movies"
    └── tv/                 ← qBittorrent category "tv"
```

All containers share the same `/data` mount → hardlinks work:
after download Radarr/Sonarr hardlink `torrents/ → media/` without copying the file.
qBittorrent continues seeding from `torrents/`, Jellyfin reads from `media/`.

> This layout follows the [Trash Guides recommended structure](https://trash-guides.info/File-and-Folder-Structure/Hardlinks-and-Instant-Moves/)
> for instant imports and zero-copy hardlinks.

---

## GPU Acceleration

Hardware-accelerated transcoding reduces CPU usage during video playback.
Use the `docker-compose.gpu.yml` override to enable it:

```bash
docker compose -f docker-compose.yml -f docker-compose.gpu.yml up -d
```

### Intel / AMD (VAAPI)

1. Verify the GPU is accessible on the host: `ls /dev/dri` should show `card0` and `renderD128`
2. Start with the GPU override (command above)
3. Jellyfin → Dashboard → Playback → Transcoding:
   - Hardware acceleration: **VAAPI**
   - VA-API device: `/dev/dri/renderD128`
   - Enable all available hardware decoders and encoders
4. Verify: start a video that requires transcoding (e.g., change quality to force it) → Dashboard → Active Devices — should show **Transcode (HW)** next to the stream and no significant CPU spike

### NVIDIA

1. Install [NVIDIA Container Toolkit](https://docs.nvidia.com/datacenter/cloud-native/container-toolkit/install-guide.html) on the host
2. In `docker-compose.gpu.yml`, comment out the `devices:` block and uncomment the `deploy:` block
3. Start with the GPU override (command above)
4. Jellyfin → Dashboard → Playback → Transcoding → Hardware acceleration: **NVENC**

---

## Useful commands

```bash
docker compose up -d           # start
docker compose down            # stop
docker compose logs sonarr -f  # logs
docker compose pull && docker compose up -d  # manual update
```

---

## Troubleshooting

**Not showing in Jellyfin?**
- Filename must be `Title (year).mkv` for movies, `S01E01.mkv` for episodes
- Radarr/Sonarr → Connect → Emby/Jellyfin triggers instant scan after download

**"Folder is not writable by user abc" in Radarr/Sonarr?**
- Media directory isn't owned by the user matching your PUID/PGID
- Fix: `sudo chown -R 1000:1000 /your/media/dir` (replace 1000 with your PUID/PGID - but 1000 is default)

**Downloads not working?**
- Prowlarr → indexers must be green; try a different indexer

**Container crashed?**
```bash
docker compose logs <name>
docker compose restart <name>
```

---

## Samsung TV

- Browser: `http://<HOST_IP>:8096`
- App: Samsung App Store → Jellyfin → enter server URL
- DLNA: TV → Source → Media Player (auto-discovers via port 1900)
