param(
    [Parameter(Mandatory=$true, HelpMessage="Ruta al proyecto destino")]
    [string]$Target
)

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path

if (-not (Test-Path $Target)) {
    Write-Error "El directorio '$Target' no existe"
    exit 1
}

Write-Host "Instalando Harness SDD en $Target..."

Copy-Item "$ScriptDir\CLAUDE.md" "$Target\CLAUDE.md" -Force
Copy-Item "$ScriptDir\AGENTS.md" "$Target\AGENTS.md" -Force

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

Copy-Item "$ScriptDir\.harness\agents.md"    "$Target\.harness\agents.md" -Force
Copy-Item "$ScriptDir\.harness\agents\*.md"  "$Target\.harness\agents\" -Force
Copy-Item "$ScriptDir\.harness\skills\*.md"  "$Target\.harness\skills\" -Force

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
