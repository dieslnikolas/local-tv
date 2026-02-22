# Jak to používat – rychlý průvodce

## Start / Stop

```bash
# Spustit (v složce local-tv)
docker compose up -d

# Zastavit
docker compose down
```

---

## Chci stáhnout film

1. Otevři **http://localhost:7878** (Radarr)
2. Klikni na **Movies → Add New**
3. Napiš název filmu anglicky (např. `Inception`)
4. Vyber film ze seznamu
5. **Quality Profile** nech `Any`
6. Klikni **Add Movie** → Radarr sám najde a stáhne

Film se automaticky objeví v Jellyfin na **http://localhost:8096**

---

## Chci stáhnout seriál

1. Otevři **http://localhost:8989** (Sonarr)
2. **Series → Add New** → napiš název
3. Root Folder: `/tv` (seriály) nebo `/cartoons` (pohádky s CZ dabingem)
4. **Add Series**

---

## Chci přidat soubor ručně (bez stahování)

Zkopíruj soubor do správné složky se správným názvem:

```
C:\Media\movies\Název Filmu (rok)\Název Filmu (rok).mkv
C:\Media\shows\Název Seriálu\Season 01\S01E01.mkv
C:\Media\cartoons\Název Pohádky\Název Pohádky (rok).mkv
```

Příklady:
```
C:\Media\movies\Oppenheimer (2023)\Oppenheimer (2023).mkv
C:\Media\movies\Shrek (2001)\Shrek (2001).mkv
C:\Media\cartoons\Lví král (1994)\Lví král (1994).mkv
```

Pak v Jellyfin klikni: **Dashboard → Scan All Libraries** (nebo počkej, skenuje automaticky).

---

## Sledování na Samsung TV

**Přes prohlížeč** (funguje hned):
- Na TV otevři prohlížeč → `http://192.168.20.11:8096`

**Přes app** (lepší zážitek):
- Samsung App Store → hledej `Jellyfin`
- Po instalaci zadej server: `http://192.168.20.11:8096`

---

## Přístupy – přehled

| Co | Kde |
|----|-----|
| Filmy a sledování | http://localhost:8096 |
| Stáhnout film | http://localhost:7878 |
| Stáhnout seriál/pohádku | http://localhost:8989 |
| Stav stahování | http://localhost:8080 |
| Rozcestník | http://localhost:7575 |

**Login všude:** `admin` / `admin`

---

## Problémy

**Film se neobjevuje v Jellyfin?**
- Zkontroluj název souboru – musí být `Název (rok).mkv`
- Spusť ruční scan v Jellyfin

**Stahování nefunguje?**
- Zkontroluj Prowlarr → http://localhost:9696 → indexery musí být zelené
- Zkus jiný indexer

**Kontejner spadl?**
```bash
docker compose logs <název>   # např. docker compose logs jellyfin
docker compose restart <název>
```
