# Practical Guide: Building a Harness with SDD

## Índice
1. [Conceptos Base](#conceptos-base)
2. [Qué Tener en Cuenta Antes de Empezar](#qué-tener-en-cuenta)
3. [Estructura Mínima Viable](#estructura-mínima-viable)
4. [Flujo SDD en el Arnés](#flujo-sdd-en-el-arnés)
5. [Primeros Pasos Prácticos](#primeros-pasos-prácticos)
6. [Decisiones Arquitectónicas Críticas](#decisiones-arquitectónicas-críticas)
7. [Indexado de Proyecto: CodeGraph](#indexado-de-proyecto-codegraph)
8. [Gestión Avanzada del Contexto](#gestión-avanzada-del-contexto)

---

## Conceptos Base

### ¿Qué es un Arnés?

Un **arnés** es el entorno que rodea tu modelo de IA. No es el modelo en sí, sino todo lo demás:

- **El bucle de control** (Read → Evaluate → Print → Loop)
- **Las herramientas** (tools/skills) a las que el modelo puede acceder
- **El contexto** que le pasas al modelo
- **La memoria** (externa al modelo)
- **Las reglas** que el modelo debe seguir

**Analogía**: Es como las riendas y la silla que le pones a un caballo. El caballo es el modelo. El arnés es cómo lo controlas.

### ¿Qué es SDD en tu Arnés?

**Spec Driven Development** en tu contexto:

```
RESEARCH PLAN
    ↓
TECH PLAN (con tareas específicas)
    ↓
IMPLEMENTACIÓN (usando tech-plan como fuente de verdad)
    ↓
VALIDACIÓN
```

El **tech-plan** es la fuente de verdad. El modelo nunca improvisa. Siempre sigue el plan.

---

## Qué Tener en Cuenta

### 1. **Simplicidad Extrema**

❌ **NO hagas esto**:
- Equipar el modelo con 50 tools hiperespecializadas
- Darle contexto ilimitado
- Esperar que deduzca qué hacer

✅ **SÍ haz esto**:
- Herramientas mínimas (leer archivo, ejecutar comando, guardar archivo)
- Contexto acotado (máximo 20-40% de la ventana antes de limpiar)
- Instrucciones explícitas sobre qué hacer

**Dato importante**: estudios demuestran que quitando el 80% de sus tools y el rendimiento **mejoró 3x** y usaron **37% menos tokens**.

### 2. **Gestión del Contexto**

El modelo degrada su rendimiento antes de llenar la ventana:
- A partir del **20-40%** ya empieza a degradarse
- A partir del **40%** deberías limpiar contexto

**Tu responsabilidad**: Sacar información relevante **FUERA** de la ventana de contexto (a ficheros, BD, etc.)

```
Ventana de contexto del modelo (pequeña, limpia)
    ↓
MEMORIA EXTERNA (ficheros, BD)
    ↑
Cuando el modelo pregunta "¿Qué hice antes?", lees de memoria
```

El harness implementa esto a través del **Context Manager** (ver sección [Gestión Avanzada del Contexto](#gestión-avanzada-del-contexto)): un agente on-demand que compacta el contexto en `session-summary.md` e instruye al modelo a iniciar sesión fresca. El Leader lo activa automáticamente al detectar síntomas de degradación.

### 3. **No Confíes en lo que el Modelo Dice**

El modelo está entrenado para **parecer verosímil**, no para ser correcto.

**Solución**: El arnés debe **verificar**.

```
Modelo dice: "He implementado la feature"
Tu arnés responde: "Demuéstramelo"
    → Ejecuta tests
    → Valida contra el plan
    → Si pasa, acepta
    → Si no, rechaza y corrige
```

### 4. **Estructura del Proyecto es Ley**

El arnés debe estar **en el repositorio mismo**:

```
mi-proyecto/
├── CLAUDE.md              ← auto-cargado por Claude Code
├── AGENTS.md              ← auto-cargado por OpenCode
├── .harness/
│   ├── agents.md          ← Leader/orquestador: decide qué agente activar y cuándo
│   ├── agents/
│   │   ├── researcher.md      ← fase 1: preguntas + research-plan.md
│   │   ├── planner.md         ← fase 2: tech-plan con tasks atómicas
│   │   ├── implementer.md     ← fase 3: ejecuta task por task
│   │   ├── reviewer.md        ← fase 4: valida o rechaza
│   │   └── context-manager.md ← on-demand: compacta y recupera contexto
│   ├── research/
│   │   └── research-plan.md
│   ├── tech/
│   │   └── tech-plan.md
│   └── memory/
│       ├── current-progress.json
│       ├── history.md
│       └── session-summary.md  ← generado por Context Manager al compactar
├── src/
├── tests/
└── README.md
```

**Importancia**: La estructura IS el arnés. No es solo configuración, es la definición del comportamiento.

**Novedad clave**: cada agente vive en su propio archivo con **frontmatter YAML** que declara su rol, input, output y siguiente agente. El `agents.md` actúa como **Leader**: lee el estado en memory y delega al agente correcto según la fase. Esto mantiene el contexto de cada agente limpio y enfocado.

---

## Estructura Mínima Viable

### Fichero Principal: `.harness/agents.md`

Este es el **punto de entrada**. Define todo.

```markdown
# Arnés de Mi Proyecto

## Reglas Obligatorias

1. Antes de empezar SIEMPRE:
   - Ejecutar: `./init.sh`
   - Leer: `.harness/research/research-plan.md`
   - Leer: `.harness/tech/tech-plan.md`
   
2. No hagas nada fuera del tech-plan

3. Al terminar cada tarea:
   - Ejecuta tests: `npm test`
   - Registra en: `.harness/memory/current-progress.json`

## Mapa del Proyecto

- `/src`: Código fuente
- `/tests`: Tests (OBLIGATORIO ejecutar antes de terminar)
- `.harness/`: Todo lo relacionado con el arnés

## Estado Actual

Leer: `.harness/memory/current-progress.json`
```

### Fichero: `.harness/research/research-plan.md`

```markdown
# Research Plan - [Nombre del Proyecto]

## Objetivo General
[Qué estamos construyendo y por qué]

## Contexto
[Por qué es importante, restricciones, dependencias]

## Decisiones Clave
- [Decisión 1 y razón]
- [Decisión 2 y razón]

## Riesgos Identificados
- [Riesgo 1]
- [Riesgo 2]

## Próximo Paso
→ Leer `tech-plan.md` para especificaciones técnicas
```

### Fichero: `.harness/tech/tech-plan.md`

Este es **MÁS IMPORTANTE**. Es la fuente de verdad.

```markdown
# Tech Plan - [Nombre del Feature/Sprint]

## Resumen Ejecutivo
[En 2-3 líneas qué hace esto]

## Tareas (ORDEN OBLIGATORIO)

### Task 1: [Nombre específico]
**Descripción**: [Exactamente qué se debe hacer]
**Archivos a tocar**: 
  - `/src/components/Button.js` (líneas 10-50)
  - `/tests/Button.test.js` (crear nuevo)

**Criterios de Aceptación**:
- [ ] La función `validateButton()` existe
- [ ] Retorna `true` si válido
- [ ] Los tests pasan: `npm test -- Button.test.js`
- [ ] Sin warnings en el linter

**Estimado**: 15 minutos

### Task 2: [Nombre específico]
[Similar estructura]

## Validación Global
```bash
npm test              # Todos los tests pasan
npm run lint          # Sin errores de estilo
```

## Si Algo Falla
1. Para la ejecución
2. Reporta exactamente qué falló
3. Espera aprobación humana
```

### Fichero: `.harness/memory/current-progress.json`

```json
{
  "session_id": "2025-05-31-001",
  "current_task": "Task 1: Setup Button Component",
  "status": "in_progress",
  "completed_tasks": [],
  "files_modified": [
    "/src/components/Button.js"
  ],
  "last_test_run": "2025-05-31T10:30:00Z",
  "test_result": "PASSED",
  "notes": "Cambios en la función validateButton(), listo para review"
}
```

### Script: `.harness/init.sh`

```bash
#!/bin/bash

echo "🔧 Inicializando arnés..."

# 1. Verificar dependencias
if ! command -v npm &> /dev/null; then
  echo "❌ npm no está instalado"
  exit 1
fi

# 2. Verificar ficheros críticos
if [ ! -f ".harness/tech/tech-plan.md" ]; then
  echo "❌ Falta tech-plan.md"
  exit 1
fi

# 3. Ejecutar tests
echo "🧪 Ejecutando tests..."
npm test
if [ $? -ne 0 ]; then
  echo "❌ Tests fallaron. No puedo continuar."
  exit 1
fi

# 4. Validar linter
npm run lint
if [ $? -ne 0 ]; then
  echo "⚠️  Warnings en linter (no crítico, pero aviso)"
fi

echo "✅ Arnés inicializado. Listo para trabajar."
```

---

## Flujo SDD en el Arnés

### Fase 0: LEADER (Orquestador)

**Quién**: `agents.md` — se carga automáticamente al abrir el proyecto  
**Input**: estado en `memory/current-progress.json`  
**Decide**: qué agente activar según el estado y la complejidad del requisito

```
Leader evalúa complejidad:
  SIMPLE (≤3 archivos, <2h, scope claro) → activa Planner directamente
  MEDIO o DIFÍCIL                        → activa Researcher primero

Leader evalúa estado en memory:
  done / vacío        → espera requisito
  awaiting_*_approval → muestra el plan y espera aprobación
  in_progress         → retoma con Implementer
  awaiting_review     → activa Reviewer
  blocked             → reporta y espera instrucción
```

El Leader nunca implementa ni diseña — solo orquesta.

### Fase 1: RESEARCH (Uno sólo)

**Quién**: Agente "Researcher"  
**Input**: Requirement de alto nivel  
**Output**: `research-plan.md`

```
Prompt del Researcher:
"Dado este requirement, investiga:
1. ¿Qué necesitamos?
2. ¿Cómo afecta al proyecto existente?
3. ¿Qué dependencias hay?
4. ¿Qué puede salir mal?

Escribe en: .harness/research/research-plan.md
NO CONTINÚES HASTA AQUÍ. Pausa para aprobación humana."
```

### Fase 2: TECH-PLAN (Especificación Técnica)

**Quién**: Agente "Planner"  
**Input**: `research-plan.md`  
**Output**: `tech-plan.md` con tareas secuenciales

```
Prompt del Planner:
"Lee research-plan.md.
Ahora define EXACTAMENTE:
1. Qué archivos tocar (rutas + líneas)
2. Qué funciones crear/modificar
3. Tests específicos que pasar
4. Orden de ejecución

Escribe en: .harness/tech/tech-plan.md
PAUSA AQUÍ. Espera aprobación humana."
```

**Checklist antes de aprobar el tech-plan**:
- ¿Son las tareas atómicas? (una cosa por task)
- ¿Tienen criterios de aceptación medibles?
- ¿El orden tiene sentido?
- ¿Hay dependencias explícitas?

### Fase 3: IMPLEMENTACIÓN (Sigue el Plan Ciegamente)

**Quién**: Agente "Implementer"  
**Input**: `tech-plan.md`  
**Modo**: Loop por cada tarea

```
Para cada Task en tech-plan.md:
  1. Localiza los archivos:
       Si CodeGraph activo → codegraph_search "{símbolo}"
       Si no              → lee por ruta directa
  2. Haz EXACTAMENTE lo que dice el plan
  3. Ejecuta tests
  4. Si PASA:
     - Registra en current-progress.json
     - Continúa con siguiente task
  5. Si FALLA:
     - PARA EJECUCIÓN
     - Reporta qué salió mal
     - Espera corrección manual o nuevas instrucciones
```

### Fase 4: VALIDACIÓN (Review Independiente)

**Quién**: Agente "Reviewer"  
**Input**: Código + `tech-plan.md`  
**Output**: Aprobación o rechazo

```
Reviewer valida:
1. ¿Se cumplió cada criterio de aceptación?
2. ¿Todos los tests pasan?
3. ¿El código sigue las convenciones?
4. ¿No hay regresiones en otras partes?

Si TODO OK → Marca como DONE en memory
Si hay issues → Devuelve al Implementer
```

---

## Primeros Pasos Prácticos

### Paso 1: Copiar el Harness al Proyecto

```bash
# Desde el repositorio del harness
cp -r CLAUDE.md AGENTS.md .harness/ tu-proyecto/
```

Esto incluye el Leader (`agents.md`) y los 4 archivos de agente ya configurados.

**Opcional pero recomendado** para proyectos con código existente:

```bash
cd tu-proyecto
codegraph init -i   # indexa el proyecto para los agentes
```

### Paso 2: Escribir tu Primer Research Plan

**Manualmente** (sin IA), responde esto:

1. **¿Qué construyes?**  
   *Ejemplo*: "Sistema de gestión de notas con búsqueda CLI"

2. **¿Por qué?**  
   *Ejemplo*: "Necesito una herramienta interna rápida"

3. **¿Qué NO haremos?**  
   *Ejemplo*: "No habrá UI gráfica, solo CLI. No persistirá en BD remota."

4. **¿Cuál es la arquitectura mental?**  
   *Ejemplo*: "Model → Controller → Repository pattern"

Escríbelo en `research-plan.md`.

### Paso 3: Definir tu Tech Plan Manualmente (Primera Vez)

Desglosa TU requirement en **tareas atómicas**:

```markdown
# Tech Plan - MVP Gestor de Notas

## Task 1: Setup Base Structure
- Crear `/src/note.js` con clase Note
- Propiedades: id, title, content, createdAt
- Tests en `/tests/note.test.js`

## Task 2: Command Parser
- Crear `/src/commands.js`
- Parsear entrada CLI: `add`, `list`, `search`
- Tests para cada comando

## Task 3: Search Implementation
- Implementar búsqueda en `/src/search.js`
- Búsqueda case-insensitive en title y content
- Tests de búsqueda
```

### Paso 4: Abre el Proyecto en tu Agente

Abre el proyecto en Claude Code u OpenCode. El Leader se carga automáticamente desde `CLAUDE.md` / `AGENTS.md` y espera un requisito. No necesitas apuntar manualmente a ningún archivo.

---

## Decisiones Arquitectónicas Críticas

### 1. **¿Quién Decide el Orden de Tareas?**

❌ El modelo (puede equivocarse, perder contexto)  
✅ **Tú humano**, en el `tech-plan.md`

### 2. **¿Cuándo Para el Modelo?**

**Siempre que**:
- Un test falla
- Encuentra ambigüedad en el plan
- Necesita aprobación humana (después de research, después de plan)

**Nunca continúe sin** que tú estés de acuerdo.

### 3. **¿Cómo Mantienes Contexto?**

**NO**: Dejarle todo el historial de chat  
**SÍ**: Guardar en ficheros lo relevante:
- Estado actual (`current-progress.json`)
- Decisiones (`research-plan.md`)
- Plan (`tech-plan.md`)
- Historial (`memory/history.md`)

Cuando vuelvas, el modelo **lee ficheros**, no chat.

### 4. **¿Cómo Evitas que el Modelo Invente?**

**Técnica del "Doble Check"**:
```
Modelo: "Voy a implementar búsqueda"
Tú: "¿Dónde dice eso en tech-plan.md?"
Modelo: "En Task 3"
Tú: "OK, adelante. Pero SOLO Task 3"
```

### 5. **¿Cuándo Usas Subagentes?**

**Subagentes = equipos especializados**

```
Leader (orquestador)
  ├─ Researcher (invierte en problemas)
  ├─ Planner (diseña solución)
  ├─ Implementer (codifica)
  └─ Reviewer (valida)
```

**Cuándo NO necesitas subagentes**:
- Tareas pequeñas (< 30 min)
- Proyecto simple (< 5 tareas)

**Cuándo SÍ necesitas**:
- Flujo largo (> 10 tareas)
- Necesitas especialización (reviewer independiente)
- Contexto muy grande (cada agente "limpio")

---

## Plantilla Rápida para tu Primer Arnés

### `CLAUDE.md` (raíz del proyecto)
```markdown
@.harness/agents.md
```

### `AGENTS.md` (raíz del proyecto)
```markdown
# Harness

Lee `.harness/agents.md` completo antes de cualquier acción en este proyecto.
```

### `.harness/agents.md` (Leader)
```markdown
---
name: Harness Leader
role: orchestrator
agents:
  - path: .harness/agents/researcher.md
    activates_when: requisito MEDIO o DIFÍCIL
  - path: .harness/agents/planner.md
    activates_when: requisito SIMPLE o research aprobado
  - path: .harness/agents/implementer.md
    activates_when: tech-plan aprobado o status in_progress
  - path: .harness/agents/reviewer.md
    activates_when: status awaiting_review
  - path: .harness/agents/context-manager.md
    activates_when: síntomas de degradación o envenenamiento de contexto
---

# Harness Leader

Lee `.harness/memory/current-progress.json` y activa el agente correcto.
Nunca implementes directamente. Siempre delega.
```

### `.harness/agents/researcher.md` (ejemplo de estructura con frontmatter)
```markdown
---
name: Researcher
role: researcher
phase: 1
input: requisito de alto nivel
output: .harness/research/research-plan.md
memory_status_al_terminar: awaiting_research_approval
next: planner (tras aprobación humana)
---

# Agente: Researcher

Tu único objetivo: entender el requisito. Máx 5 preguntas. Genera research-plan.md. Pausa para aprobación.
```

### `.harness/tech/tech-plan.md`
```markdown
# Tech Plan - [Tu Nombre del Feature]

## Entorno
- Tests: `{comando}`

## Tareas

### Task 1: [Nombre concreto]
**Archivos**: `ruta/archivo.ext` — {crear/modificar}
**Qué hacer**: {descripción exacta}
**Criterios de Aceptación**:
- [ ] {criterio medible}
**Validación**: `{test específico}`
```

---

## Indexado de Proyecto: CodeGraph

En proyectos grandes, los agentes pierden tokens buscando archivos con grep/glob. [CodeGraph](https://github.com/colbymchenry/codegraph) resuelve esto: pre-indexa el código en un grafo de símbolos local y expone herramientas MCP que los agentes consultan directamente.

**Resultados medidos** (7 codebases reales): ~25% menos coste, ~62% menos tool calls, ~23% más rápido.

### Instalación

```bash
# macOS / Linux
curl -fsSL https://raw.githubusercontent.com/colbymchenry/codegraph/main/install.sh | sh

# Windows
irm https://raw.githubusercontent.com/colbymchenry/codegraph/main/install.ps1 | iex

# Por proyecto
codegraph init -i
```

### Cómo lo usan los agentes del harness

| Agente | Herramienta | Para qué |
|--------|-------------|----------|
| Researcher | `codegraph_context` | Ver qué ya existe antes de preguntar |
| Planner | `codegraph_files` · `codegraph_impact` | Rutas exactas y efectos secundarios |
| Implementer | `codegraph_search` | Localizar archivos sin explorar |
| Reviewer | `codegraph_callers` · `codegraph_impact` | Detectar regresiones |

Si no está instalado, los agentes degradan a búsqueda manual sin romperse. Es una mejora opcional, no un requisito.

---

## Gestión Avanzada del Contexto

El contexto largo es uno de los fallos más silenciosos en sistemas de agentes. Los síntomas aparecen despacio y el modelo nunca avisa — simplemente empieza a comportarse peor.

### Síntomas a Vigilar

| Síntoma | Nombre | Gravedad |
|---------|--------|----------|
| El agente contradice el plan o "recuerda" código que no existe | Envenenamiento | Crítica |
| El agente propone repetir tasks ya completadas | Envenenamiento | Crítica |
| El mismo archivo se lee 3+ veces sin cambio | Solapamiento excesivo | Media |
| Respuestas más largas, con relleno, fuera del plan | Degradación por longitud | Media |
| El modelo pierde el hilo entre tool calls | Fatiga de contexto | Baja-media |

### Estrategias Implementadas

**Sliding Window + Summarize**

Cuando el contexto se satura, el Context Manager no lo trunca sin más — lo comprime en un `session-summary.md` con solo lo que importa: estado actual, decisiones clave, advertencias. La siguiente sesión arranca limpia cargando solo ese resumen.

```
Sesión larga (contexto saturado)
    ↓ Context Manager
session-summary.md  ←  estado comprimido
    ↓ nueva sesión
Leader lee summary → retoma desde task correcta
```

**Verificación de Realidad (Anti-Envenenamiento)**

Ante síntomas de envenenamiento, el Context Manager no compacta ciegamente. Primero verifica: lee los archivos reales y cruza con lo que el modelo "recuerda". Si hay discrepancia → bloqueo y revisión humana obligatoria.

```
Contexto dice: "implementé UserService.create()"
Archivo real:  UserService.create() no existe
    ↓
blocked: "envenenamiento de contexto detectado"
    ↓ revisión humana
```

### Cuándo Actúa el Context Manager

El Leader lo activa. Cualquier agente puede solicitarlo. No requiere intervención manual — es parte del flujo normal cuando las sesiones son largas.

---

## Resumen: Los 3 Principios Clave

1. **Simplicidad Extrema**  
   → Menos tools, menos contexto, más claro

2. **Ficheros Son Ley**  
   → `research-plan.md` → `tech-plan.md` → Ejecución  
   → El modelo SIGUE, no inventa

3. **Verifica Todo**  
   → Tests deben pasar  
   → Reviewer independiente  
   → Tú apruebas antes de continuar

---