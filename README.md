# Harness SDD

Entorno de control para agentes IA basado en Spec Driven Development. Define cómo el modelo investiga, planifica, implementa y valida — sin improvisar.

## Estructura

```
.harness/
├── agents.md              ← Leader: lee el estado y activa el agente correcto
├── agents/
│   ├── researcher.md      ← Clarifica el requisito, genera research-plan.md
│   ├── planner.md         ← Convierte el research en tareas atómicas (tech-plan.md)
│   ├── implementer.md     ← Ejecuta el tech-plan task por task
│   ├── reviewer.md        ← Valida contra criterios de aceptación
│   └── context-manager.md ← Compacta contexto, detecta envenenamiento
├── research/              ← research-plan.md generado por Researcher
├── tech/                  ← tech-plan.md generado por Planner
└── memory/
    ├── current-progress.json  ← caché de sesión (estado + referencia al Issue de GitHub)
    ├── history.md             ← pointer a GitHub Issues (el historial real está en GitHub)
    └── session-summary.md     ← generado por Context Manager al compactar
```

## Flujo Principal

```
Requisito del usuario
        ↓
   Leader evalúa                          ← también consulta Issues abiertos en GitHub
   (SIMPLE / MEDIO / DIFÍCIL)
        ↓
  [si MEDIO/DIFÍCIL]         [si SIMPLE]
   Researcher                     ↓
   · crea Issue en GitHub          ↓       ← Issue#N abierto con label status:research
   · preguntas                    ↓
   · research-plan.md             ↓
   · pausa → aprobación           ↓
        ↓ ←────────────────────────┘
    Planner
    · detecta stack
    · tech-plan.md (tasks atómicas)
    · actualiza Issue con checklist  ←── label cambia a status:in-progress
    · pausa → aprobación
        ↓
  Implementer
  · localiza archivos (CodeGraph si disponible)
  · task por task, tests tras cada una
  · marca checkbox en el Issue al completar cada task
  · para si algo falla
        ↓
   Reviewer
   · valida criterios + regresiones (CodeGraph)
   · APROBADO → cierra Issue en GitHub  (label: status:done)
   · RECHAZADO → comment con blockers   (label: status:blocked) → vuelve al Implementer
```

## Gestión de Contexto (on-demand)

```
Cualquier agente detecta síntoma
        ↓
   Context Manager
   · verifica contexto vs. archivos reales (anti-envenenamiento)
   · guarda estado en session-summary.md
   · instruye iniciar sesión fresca
        ↓
   Nueva sesión:
   Leader lee session-summary.md → retoma desde la task correcta
```

| Síntoma | Estrategia |
|---------|-----------|
| Respuestas inconsistentes con el plan | Verificación de realidad + bloqueo si hay discrepancia |
| Mismo archivo leído 3+ veces sin cambio | Compactación por solapamiento |
| Respuestas largas, fuera del plan, con relleno | Sliding window — sesión fresca con resumen |
| Tarea completada vuelve a plantearse | Anti-envenenamiento — verifica contra archivos reales |

## Instalación en un proyecto

```bash
# Copia el harness al proyecto
cp -r CLAUDE.md AGENTS.md .harness/ tu-proyecto/

# Opcional pero recomendado para proyectos grandes
cd tu-proyecto
codegraph init -i
```

Al abrir en Claude Code u OpenCode, el Leader se carga automáticamente desde `CLAUDE.md` / `AGENTS.md`.

---

## GitHub Issues como fuente de verdad

El harness usa GitHub Issues como sistema de trazabilidad canónico. `current-progress.json` es solo caché de sesión; el estado real vive en GitHub.

**Repositorio de tracking:** `alvarobozser/harness-eng` (configurable en los agentes)

### Ciclo de vida de un Issue

| Fase | Label | Quién actúa |
|------|-------|-------------|
| Researcher crea el Issue | `harness` + `status:research` | Researcher |
| Planner añade el checklist de tasks | `status:in-progress` | Planner |
| Implementer marca tasks completadas | checkboxes `- [x]` en el body | Implementer |
| Reviewer aprueba | `status:done` + Issue cerrado | Reviewer |
| Reviewer rechaza | `status:blocked` + comment con blockers | Reviewer |

### Al iniciar sesión

El Leader consulta Issues abiertos con label `harness` antes de esperar un nuevo requisito:

```
mcp__github__list_issues  repo="alvarobozser/harness-eng"  state="open"  labels="harness"
```

Si hay Issues abiertos, pregunta al usuario si retomar uno o empezar uno nuevo. Al retomar, sincroniza `current-progress.json` con el `github_issue_number` y el estado de los checkboxes del Issue.

### Historial

El historial de features completados está en GitHub como Issues cerrados:

```
https://github.com/alvarobozser/harness-eng/issues?q=is%3Aissue+is%3Aclosed+label%3Aharness
```

`.harness/memory/history.md` es únicamente un pointer a esa URL — no se escribe manualmente.

---

## CodeGraph (recomendado para proyectos grandes)

[CodeGraph](https://github.com/colbymchenry/codegraph) pre-indexa el código en un grafo de símbolos local. Los agentes consultan el grafo en lugar de explorar archivos — sin subagentes de búsqueda, sin tokens desperdiciados.

**Instalar una sola vez:**

```powershell
# Windows
irm https://raw.githubusercontent.com/colbymchenry/codegraph/main/install.ps1 | iex
```

```bash
# macOS / Linux
curl -fsSL https://raw.githubusercontent.com/colbymchenry/codegraph/main/install.sh | sh
```

**Inicializar en cada proyecto:**

```bash
codegraph init -i
```

El Leader detecta `.codegraph/` al iniciar. Los agentes usan automáticamente:

| Agente | Herramienta | Para qué |
|--------|-------------|----------|
| Researcher | `codegraph_context` | Entender qué ya existe |
| Planner | `codegraph_files` · `codegraph_impact` | Rutas exactas y efectos secundarios |
| Implementer | `codegraph_search` | Localizar archivos sin explorar |
| Reviewer | `codegraph_callers` · `codegraph_impact` | Detectar regresiones |
