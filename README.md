# 🏠 Local TV Stack

Domácí media server postavený na Jellyfin + automatizace stahování.

## Přehled služeb

| Služba | URL | Popis |
|--------|-----|-------|
| **Jellyfin** | http://localhost:8096 | Media server – sledování filmů a seriálů |
| **Homarr** | http://localhost:7575 | Dashboard všech služeb |
| **qBittorrent** | http://localhost:8080 | Torrent klient |
| **Prowlarr** | http://localhost:9696 | Správce torrent indexerů |
| **Radarr** | http://localhost:7878 | Automatické stahování filmů |
| **Sonarr** | http://localhost:8989 | Automatické stahování seriálů |

---

## Rychlý start

### 1. Předpoklady
- [Docker Desktop](https://www.docker.com/products/docker-desktop/) nainstalovaný a spuštěný

### 2. Uprav `.env` soubor
```
HOST_IP=192.168.1.100   # tvoje IP – zjistíš přes ipconfig
MEDIA_DIR=D:/Media      # kde máš / budeš mít média
DOWNLOADS_DIR=D:/Downloads/Torrents
```

### 3. Vytvoř složky pro média
```powershell
mkdir D:\Media\movies
mkdir D:\Media\shows
mkdir D:\Media\cartoons
mkdir D:\Downloads\Torrents
```

### 4. Spusť stack
```bash
docker compose up -d
```

### 5. První spuštění – zjisti heslo qBittorrent
```bash
docker logs qbittorrent 2>&1 | grep "password"
```

---

## Nastavení po prvním spuštění

### Jellyfin (http://localhost:8096)
1. Průvodce prvním spuštěním – vytvoř admin účet
2. Přidej knihovny:
   - **Filmy** → `/media/movies`
   - **Seriály** → `/media/shows`
   - **Pohádky** → `/media/cartoons`
3. V nastavení → Přehrávání → zapni **preferovaný jazyk titulků: čeština**
4. Při přidání knihovny nastav **preferovaný jazyk metadat: čeština**

### qBittorrent (http://localhost:8080)
1. Přihlas se (user: `admin`, heslo viz logy výše)
2. Nastavení → Stahování:
   - Default Save Path: `/downloads`
3. Nastav kategorii pro Radarr: `/downloads/movies`
4. Nastav kategorii pro Sonarr: `/downloads/tv`

### Prowlarr (http://localhost:9696)
1. Nastav indexery (torrent stránky) – např. 1337x, RARBG mirror, apod.
2. Settings → Apps → přidej Radarr a Sonarr (API klíče najdeš v jejich nastaveních)

### Radarr (http://localhost:7878)
1. Settings → Media Management → Root Folders: `/movies`
2. Settings → Download Clients → přidej qBittorrent (host: `qbittorrent`, port: `8080`)
3. Settings → Indexers se synchronizují automaticky přes Prowlarr

### Sonarr (http://localhost:8989)
1. Settings → Media Management → Root Folders: `/tv` a `/cartoons`
2. Settings → Download Clients → přidej qBittorrent
3. Indexery přes Prowlarr

---

## Samsung TV

### Možnost A – prohlížeč (funguje hned)
1. Zjisti IP svého PC: `ipconfig` → IPv4 adresa (např. `192.168.1.100`)
2. Na Samsung TV otevři prohlížeč a jdi na: `http://192.168.1.100:8096`

### Možnost B – nativní app (doporučeno)
1. Na Samsung TV → App Store → hledej **"Jellyfin"**
2. Pokud není dostupná, lze sideloadovat přes Samsung Developer Mode:
   - TV → Nastavení → Podpora → Informace o TV → rychle stiskni `12345`
   - Zapni Developer Mode, zadej IP svého PC
   - Pak nainstaluj Jellyfin Tizen app

### DLNA (alternativa pro zabudovaný přehrávač)
Samsung TV umí přehrávat přímo přes DLNA – Jellyfin ho vysílá automaticky na portu 1900.
TV → Zdroj → Přehrávač médií → vyhledá Jellyfin automaticky.

---

## Struktura složek

```
local-tv/
├── docker-compose.yml
├── .env                    ← uprav před spuštěním
├── config/                 ← konfigurace služeb (automaticky se vytvoří)
│   ├── jellyfin/
│   ├── qbittorrent/
│   ├── radarr/
│   ├── sonarr/
│   ├── prowlarr/
│   └── homarr/
│
D:/Media/                   ← tvoje média (cesta z .env)
├── movies/                 ← filmy (en titulky / dabing)
├── shows/                  ← seriály
└── cartoons/               ← pohádky (CZ dabing)
```

---

## Užitečné příkazy

```bash
# Spustit stack
docker compose up -d

# Zastavit stack
docker compose down

# Zobrazit logy služby
docker logs jellyfin -f

# Aktualizovat všechny image
docker compose pull && docker compose up -d

# Stav kontejnerů
docker compose ps
```

---

## Přesun na NAS / půdní PC

Až budeš chtít přesunout na jiný počítač:
1. Zkopíruj celou složku `local-tv/` včetně `config/`
2. Uprav `.env` – nová `HOST_IP`
3. Média přesuň nebo namountuj přes síť (NFS/SMB)
4. `docker compose up -d`

Konfigurace všech služeb je v `config/` – nepřijdeš o nastavení.
