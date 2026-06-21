#!/usr/bin/env bash
set -euo pipefail

TARGET="${1:-.}"
BASE_URL="https://raw.githubusercontent.com/alvarobozser/harness-eng/main"

if [[ ! -d "$TARGET" ]]; then
  echo "Error: el directorio '$TARGET' no existe"
  exit 1
fi

echo "Instalando Harness SDD en $TARGET..."

mkdir -p \
  "$TARGET/.harness/agents" \
  "$TARGET/.harness/skills" \
  "$TARGET/.harness/memory" \
  "$TARGET/.harness/research" \
  "$TARGET/.harness/tech"

FILES=(
  "CLAUDE.md"
  "AGENTS.md"
  ".harness/agents.md"
  ".harness/agents/researcher.md"
  ".harness/agents/planner.md"
  ".harness/agents/implementer.md"
  ".harness/agents/reviewer.md"
  ".harness/agents/context-manager.md"
  ".harness/skills/coding-standards.md"
)

for f in "${FILES[@]}"; do
  curl -fsSL "$BASE_URL/$f" -o "$TARGET/$f"
done

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
