# Local TV Stack

Home media server built on Jellyfin with automated downloading.

## Services

| Service | URL | Description |
|---------|-----|-------------|
| **Jellyfin** | http://localhost:8096 | Media server – watch movies and shows |
| **Homepage** | http://localhost:3000 | Services dashboard |
| **qBittorrent** | http://localhost:8080 | Torrent client |
| **Prowlarr** | http://localhost:9696 | Torrent indexer manager |
| **FlareSolverr** | http://localhost:8191 | Cloudflare bypass proxy (for 1337x etc.) |
| **Radarr** | http://localhost:7878 | Automated movie downloads |
| **Sonarr** | http://localhost:8989 | Automated TV show downloads |
| **Bazarr** | http://localhost:6767 | Automatic subtitle downloads (cs-CZ + EN) |
| **Watchtower** | *(no UI)* | Automatic container updates (daily at 4:00) |

---

## Quick Start

### 1. Prerequisites
- [Docker Desktop](https://www.docker.com/products/docker-desktop/) installed and running

### 2. Create `.env` file
```bash
cp .env.example .env
```
Then edit `.env`:
```
HOST_IP=192.168.xxx.yyy   # your local IP – find it via ipconfig
MEDIA_DIR=C:/Media        # where your media and downloads will live
```

### 3. Create media folders
```powershell
mkdir C:\Media\movies
mkdir C:\Media\shows
mkdir C:\Media\downloads
```

### 4. Start the stack
```bash
docker compose up -d
```

### 5. Get qBittorrent password (first run only)
```bash
docker logs qbittorrent 2>&1 | grep "password"
```

---

## Initial Setup

Do these in order — each service depends on the previous ones.

### 1. Jellyfin (http://localhost:8096)
1. Run the setup wizard – create an admin account
2. Add libraries (set preferred metadata language to your preference for each):
   - **Movies** → `/media/movies`
   - **Shows** → `/media/shows`
3. Dashboard → Advanced → **API Keys** → `+` → copy the key into `.env` as `JELLYFIN_API_KEY`

### 2. qBittorrent (http://localhost:8080)
1. Log in (`admin` / password from logs above), then immediately change it: Settings → Web UI → Authentication
2. Settings → Downloads → Default Save Path: `/downloads`
3. Settings → Downloads → add two categories:
   - `radarr` → save path `/downloads/radarr`
   - `sonarr` → save path `/downloads/sonarr`
4. Copy your new password into `.env` as `QBIT_PASSWORD`

### 3. Prowlarr (http://localhost:9696)
**FlareSolverr proxy** (needed for 1337x and similar Cloudflare-protected sites):
1. Settings → **Indexers** → scroll to **Indexer Proxies** → `+` → FlareSolverr
   - Host: `http://flaresolverr:8191`, Tags: `flare` → Save

**Connect to Radarr & Sonarr:**
2. Settings → **Apps** → `+` → Radarr: host `radarr`, port `7878`, API key from Radarr → Settings → General
3. Settings → **Apps** → `+` → Sonarr: host `sonarr`, port `8989`, API key from Sonarr → Settings → General

**Add 1337x:**
4. Indexers → **+ Add Indexer** → search `1337x` → Tags: `flare` → Test → Save
   *(The `flare` tag routes requests through FlareSolverr — must match exactly)*

### 4. Radarr (http://localhost:7878)
1. Settings → Media Management → Root Folders → `+` → `/movies`
2. Settings → Download Clients → `+` → qBittorrent: host `qbittorrent`, port `8080`, category `radarr`
3. Settings → Connect → `+` → **Emby/Jellyfin**: host `jellyfin`, port `8096`, API key from `.env`
   *(This notifies Jellyfin instantly after each download — no manual scan needed)*

### 5. Sonarr (http://localhost:8989)
1. Settings → Media Management → Root Folders → `+` → `/shows`
2. Settings → Download Clients → `+` → qBittorrent: host `qbittorrent`, port `8080`, category `sonarr`
3. Settings → Connect → `+` → **Emby/Jellyfin**: same config as Radarr above

### 6. Bazarr (http://localhost:6767)
Automatically downloads subtitles for your entire library.

1. Settings → **Radarr**: enable, URL `http://radarr:7878`, API key from Radarr → Settings → General → Save & test
2. Settings → **Sonarr**: enable, URL `http://sonarr:8989`, API key from Sonarr → Settings → General → Save & test
3. Settings → **Languages** → Add profile: Czech (first) + English (fallback) → assign to both Radarr and Sonarr
4. Settings → **Providers** → `+` → **OpenSubtitles.com** (free account at opensubtitles.com)
5. System → Tasks → **Search for missing subtitles** → run once to backfill existing library

### 7. Homepage (http://localhost:3000)
Run the setup script to fill API keys automatically:
```powershell
.\setup-keys.ps1
```
Then add the remaining keys to [`.env`](.env) manually:

| Variable | Where to find it |
|---|---|
| `JELLYFIN_API_KEY` | copied in step 1 |
| `QBIT_PASSWORD` | set in step 2 |
| `BAZARR_API_KEY` | Bazarr → Settings → General → Security → API Key |

```bash
docker compose restart homepage
```

---

## Downloading

### Download a movie
1. Open **http://localhost:7878** (Radarr)
2. Movies → **Add New** → type the movie name in English (e.g. `Inception`)
3. Select the movie from the list, leave Quality Profile as `Any`
4. Click **Add Movie** – Radarr will find and download it automatically

The movie will appear in Jellyfin automatically.

### Download a TV show
1. Open **http://localhost:8989** (Sonarr)
2. Series → **Add New** → type the show name
3. Root Folder: `/shows`
4. Click **Add Series**

### Add a file manually

Copy the file into the correct folder with the right naming:

```
C:\Media\movies\Movie Title (year)\Movie Title (year).mkv
C:\Media\shows\Show Name\Season 01\S01E01.mkv
```

Examples:
```
C:\Media\movies\Oppenheimer (2023)\Oppenheimer (2023).mkv
C:\Media\shows\Breaking Bad\Season 01\S01E01.mkv
```

Then in Jellyfin: Dashboard → **Scan All Libraries** (or wait, it scans automatically).

---

## Samsung TV

**Via browser** (works immediately):
- Open browser on TV → `http://<HOST_IP>:8096`

**Via app** (better experience):
- Samsung App Store → search for **Jellyfin**
- After install, enter server: `http://<HOST_IP>:8096`
- If not in App Store: TV → Settings → Support → About TV → press `12345` → enable Developer Mode

**DLNA** (built-in player):
- TV → Source → Media Player → finds Jellyfin automatically (port 1900)

---

## Folder structure

```
local-tv/
├── docker-compose.yml
├── .env                    ← your local config (not in git)
├── .env.example            ← template to copy from
├── config/                 ← service configs (created automatically, not in git)
│   ├── jellyfin/
│   ├── qbittorrent/
│   ├── radarr/
│   ├── sonarr/
│   ├── prowlarr/
│   └── homepage/
│
C:/Media/                   ← your media (path from .env)
├── movies/
├── shows/
└── downloads/              ← in-progress downloads (moved to movies/shows when done)
```

> All service configs live in `config/` – restarting (`docker compose down && up -d`) preserves everything.
> Deleting `config/` means you'll need to reconfigure from scratch.

---

## Useful commands

```bash
# Start the stack
docker compose up -d

# Stop the stack
docker compose down

# View service logs
docker logs jellyfin -f

# Update images manually (Watchtower does this automatically)
docker compose pull && docker compose up -d

# Container status
docker compose ps
```

---

## Troubleshooting

**Movie/show not showing in Jellyfin?**
- Check filename – must be `Title (year).mkv` for movies, `S01E01.mkv` for episodes
- Run a manual scan: Jellyfin → Dashboard → **Scan All Libraries**
- On Windows/Docker, automatic file detection doesn't work reliably – fix: set up Jellyfin connection in Radarr and Sonarr (Settings → Connect → Emby/Jellyfin) so they notify Jellyfin right after each download

**Can't delete media from Jellyfin?**
- Three dots on a title → Delete – Jellyfin will delete the file from disk
- If it says "access denied", make sure you're logged in as an admin account

**Downloads not working?**
- Prowlarr → http://localhost:9696 → indexers must be green
- Try a different indexer

**Container crashed?**
```bash
docker compose logs <name>   # e.g. docker compose logs sonarr
docker compose restart <name>
```

---

## Moving to a NAS / another PC

1. Copy the entire `local-tv/` folder including `config/`
2. Edit `.env` – set new `HOST_IP`
3. Move or mount media over the network (NFS/SMB)
4. `docker compose up -d`
