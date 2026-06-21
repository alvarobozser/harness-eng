param(
    [string]$Target = "."
)

$BaseUrl = "https://raw.githubusercontent.com/alvarobozser/harness-eng/main"

if (-not (Test-Path $Target)) {
    Write-Error "El directorio '$Target' no existe"
    exit 1
}

Write-Host "Instalando Harness SDD en $Target..."

$dirs = @(
    "$Target\.harness\agents",
    "$Target\.harness\skills",
    "$Target\.harness\memory",
    "$Target\.harness\research",
    "$Target\.harness\tech"
)
foreach ($d in $dirs) {
    New-Item -ItemType Directory -Force -Path $d | Out-Null
}

$files = @(
    "CLAUDE.md",
    "AGENTS.md",
    ".harness/agents.md",
    ".harness/agents/researcher.md",
    ".harness/agents/planner.md",
    ".harness/agents/implementer.md",
    ".harness/agents/reviewer.md",
    ".harness/agents/context-manager.md",
    ".harness/skills/coding-standards.md"
)

foreach ($f in $files) {
    $localPath = Join-Path $Target ($f -replace '/', '\')
    Invoke-WebRequest -Uri "$BaseUrl/$f" -OutFile $localPath -UseBasicParsing
}

if (-not (Test-Path "$Target\.harness\research\.gitkeep")) {
    New-Item -ItemType File -Path "$Target\.harness\research\.gitkeep" | Out-Null
}
if (-not (Test-Path "$Target\.harness\tech\.gitkeep")) {
    New-Item -ItemType File -Path "$Target\.harness\tech\.gitkeep" | Out-Null
}

if (-not (Test-Path "$Target\.harness\memory\current-progress.json")) {
    @'
{
  "session_id": null,
  "feature": null,
  "github_issue_number": null,
  "github_issue_url": null,
  "status": "done",
  "current_task": null,
  "files_modified": [],
  "blocked_reason": null,
  "last_updated": null
}
'@ | Set-Content "$Target\.harness\memory\current-progress.json" -Encoding utf8
}

if (-not (Test-Path "$Target\.harness\memory\history.md")) {
    @'
# Historial de Features

El historial canónico está en GitHub Issues (ajusta la URL a tu repo):
https://github.com/TU-USUARIO/TU-REPO/issues?q=is%3Aissue+is%3Aclosed+label%3Aharness
'@ | Set-Content "$Target\.harness\memory\history.md" -Encoding utf8
}

Write-Host ""
Write-Host "Harness SDD instalado en $Target"
Write-Host ""
Write-Host "Configura tu repo de GitHub en .harness/agents.md y los agentes individuales."
Write-Host ""
Write-Host "Opcional — activa CodeGraph para proyectos grandes:"
Write-Host "  cd `"$Target`"; codegraph init -i"
Write-Host ""
Write-Host "Abre el proyecto en Claude Code u OpenCode. El Leader carga desde CLAUDE.md."
