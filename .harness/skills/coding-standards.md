---
name: coding-standards
role: skill
description: >
  Checklist de buenas prácticas de implementación que el Implementer
  debe aplicar en cada task. Agnóstico de lenguaje.
---

# Skill: Coding Standards

> Lee este archivo al inicio de cada sesión de implementación. Aplica cada punto como condición de aceptación implícita: si tu código no cumple alguno, corrígelo antes de marcar la task como completada.

---

## 1. Nomenclatura

- Nombres descriptivos e intencionales; sin abreviaturas no universales.
- Variables booleanas con prefijo `is_`, `has_`, `can_`, `should_`.
- Sin magic numbers: extrae constantes con nombre y con unidad si aplica (`MAX_RETRIES = 3`, `TIMEOUT_MS = 5000`).
- Nombres de funciones con verbo: `fetch_user`, `validate_token`, `build_payload`.

## 2. Funciones

- Una función = una responsabilidad. Guía: ≤ 20 líneas.
- Máx. 3–4 parámetros; si necesitas más, agrupa en un objeto/DTO.
- Usa guard clauses para casos de error al principio; evita anidamiento profundo.
- Sin efectos secundarios ocultos: si una función modifica estado externo, refléjalo en su nombre.

## 3. Manejo de Errores

- Nunca silencies excepciones: `catch (e) {}` está prohibido.
- Captura excepciones específicas, no la clase base genérica.
- Loguea con contexto suficiente: qué operación falló, con qué inputs, en qué estado.
- APIs: retorna errores estructurados y consistentes (RFC 7807 o equivalente).
- No uses excepciones para control de flujo normal.

## 4. Tests

- Toda lógica de negocio nueva lleva tests unitarios.
- Patrón AAA: **Arrange** → **Act** → **Assert**. Sin mezclar.
- Tests independientes entre sí: sin orden de ejecución implícito, sin estado compartido mutable.
- El nombre describe el comportamiento esperado: `test_returns_404_when_user_not_found`.
- Un assert conceptual por test (puede ser varias líneas, pero una sola idea).

## 5. Seguridad

- Nunca hardcodees credenciales, API keys ni secrets en el código.
- Valida y sanitiza toda entrada externa antes de usarla (usuario, API, fichero, env var).
- Mínimo privilegio: solicita solo los permisos/scopes estrictamente necesarios.
- No loguees datos sensibles (tokens, passwords, PII).
- Escapa correctamente los datos antes de usarlos en queries, templates o comandos de shell.

## 6. Código Limpio

- Inmutabilidad por defecto donde el lenguaje lo permita.
- Cierra recursos explícitamente (streams, conexiones, file handles).
- Sin código muerto ni TODOs sin ticket asociado.
- Sin imports no usados.
- Comenta el *por qué*, no el *qué*: el código describe el qué; el comentario, la razón no obvia.

## 7. Commits (Conventional Commits)

```
feat(scope): descripción corta en imperativo
fix(scope): descripción corta
refactor / docs / test / chore
```

- Commits atómicos: una unidad lógica por commit.
- No subas `.env`, binarios, ficheros generados ni secrets.
- El body del commit explica el *por qué* si no es obvio.

---

## Checklist Pre-Entrega (por task)

Antes de marcar una task como completada, verifica:

- [ ] Nombres descriptivos, sin magic numbers
- [ ] Funciones con una sola responsabilidad
- [ ] Errores manejados y logueados con contexto
- [ ] Tests unitarios para la lógica nueva (si aplica)
- [ ] Sin secrets hardcodeados
- [ ] Sin código muerto ni imports no usados
- [ ] Mensaje de commit en Conventional Commits
