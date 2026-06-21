#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TARGET="${1:-}"

if [[ -z "$TARGET" ]]; then
  echo "Usage: ./install.sh <target-project-dir>"
  exit 1
fi

if [[ ! -d "$TARGET" ]]; then
  echo "Error: el directorio '$TARGET' no existe"
  exit 1
fi

echo "Instalando Harness SDD en $TARGET..."

cp "$SCRIPT_DIR/CLAUDE.md" "$TARGET/CLAUDE.md"
cp "$SCRIPT_DIR/AGENTS.md" "$TARGET/AGENTS.md"

mkdir -p "$TARGET/.harness/agents"
mkdir -p "$TARGET/.harness/skills"
mkdir -p "$TARGET/.harness/memory"
mkdir -p "$TARGET/.harness/research"
mkdir -p "$TARGET/.harness/tech"

cp "$SCRIPT_DIR/.harness/agents.md"     "$TARGET/.harness/agents.md"
cp "$SCRIPT_DIR/.harness/agents/"*.md   "$TARGET/.harness/agents/"
cp "$SCRIPT_DIR/.harness/skills/"*.md   "$TARGET/.harness/skills/"

touch "$TARGET/.harness/research/.gitkeep"
touch "$TARGET/.harness/tech/.gitkeep"

if [[ ! -f "$TARGET/.harness/memory/current-progress.json" ]]; then
  cat > "$TARGET/.harness/memory/current-progress.json" << 'EOF'
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
EOF
fi

if [[ ! -f "$TARGET/.harness/memory/history.md" ]]; then
  cat > "$TARGET/.harness/memory/history.md" << 'EOF'
# Historial de Features

El historial canónico está en GitHub Issues (ajusta la URL a tu repo):
https://github.com/TU-USUARIO/TU-REPO/issues?q=is%3Aissue+is%3Aclosed+label%3Aharness
EOF
fi

echo ""
echo "Harness SDD instalado en $TARGET"
echo ""
echo "Configura tu repo de GitHub en .harness/agents.md y los agentes individuales."
echo ""
echo "Opcional — activa CodeGraph para proyectos grandes:"
echo "  cd \"$TARGET\" && codegraph init -i"
echo ""
echo "Abre el proyecto en Claude Code u OpenCode. El Leader carga desde CLAUDE.md."
