# setup-keys.ps1
# Reads API keys from service config files and updates .env automatically.
# Run after the stack has started for the first time.
#
# Usage:
#   .\setup-keys.ps1

$envFile = ".\.env"

if (-not (Test-Path $envFile)) {
    Write-Error ".env file not found. Copy .env.example to .env first."
    exit 1
}

function Set-EnvValue($file, $key, $value) {
    $content = Get-Content $file -Raw
    $content = $content -replace "(?m)^$key=.*$", "$key=$value"
    Set-Content $file $content.TrimEnd() -NoNewline
}

function Get-XmlApiKey($configPath) {
    if (-not (Test-Path $configPath)) { return $null }
    try {
        $xml = [xml](Get-Content $configPath -ErrorAction Stop)
        return $xml.Config.ApiKey
    } catch {
        return $null
    }
}

Write-Host ""
Write-Host "Reading API keys from service configs..."
Write-Host ""

$updated = @()
$missing = @()

# Radarr
$key = Get-XmlApiKey ".\config\radarr\config.xml"
if ($key) {
    Set-EnvValue $envFile "RADARR_API_KEY" $key
    Write-Host "  [OK] Radarr"
    $updated += "Radarr"
} else {
    Write-Host "  [--] Radarr   (config not found – is the stack running?)"
    $missing += "Radarr"
}

# Sonarr
$key = Get-XmlApiKey ".\config\sonarr\config.xml"
if ($key) {
    Set-EnvValue $envFile "SONARR_API_KEY" $key
    Write-Host "  [OK] Sonarr"
    $updated += "Sonarr"
} else {
    Write-Host "  [--] Sonarr   (config not found)"
    $missing += "Sonarr"
}

# Prowlarr
$key = Get-XmlApiKey ".\config\prowlarr\config.xml"
if ($key) {
    Set-EnvValue $envFile "PROWLARR_API_KEY" $key
    Write-Host "  [OK] Prowlarr"
    $updated += "Prowlarr"
} else {
    Write-Host "  [--] Prowlarr (config not found)"
    $missing += "Prowlarr"
}

Write-Host ""

if ($updated.Count -gt 0) {
    Write-Host "Restarting homepage to apply new keys..."
    docker compose restart homepage
    Write-Host ""
}

Write-Host "Still requires manual setup in .env:"
Write-Host "  JELLYFIN_API_KEY  – Jellyfin -> Dashboard -> Advanced -> API Keys -> +"
Write-Host "  QBIT_PASSWORD     – qBittorrent -> Settings -> Web UI -> Authentication"
Write-Host ""
