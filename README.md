# Agent Rules

[![License: CC0-1.0](https://img.shields.io/badge/license-CC0%201.0-lightgrey.svg)](https://creativecommons.org/publicdomain/zero/1.0/)

Catálogo reutilizable de reglas, workflows y skills para agentes de desarrollo. Su propósito es que Windsurf, Cascade y los plugins de JetBrains trabajen con un proceso consistente, trazable y orientado primero al dominio.

## ¿Qué es SDD?

**Spec-Driven Development (SDD)** significa que una especificación verificable dirige el cambio de software. Antes de modificar código se define qué problema se resuelve, qué comportamiento espera el usuario, qué reglas de negocio deben preservarse y qué evidencia demostrará que el resultado es correcto.

La spec no es un documento decorativo creado después de programar. Es el registro vivo que conecta:

```text
necesidad del usuario
  -> reglas y lenguaje del dominio
  -> escenarios de aceptación
  -> plan y tareas pequeñas
  -> tests y cambios de código
  -> evidencia de verificación
  -> documentación y cierre
```

Este repositorio combina cuatro prácticas complementarias:

- **SDD** conserva intención, decisiones, trazabilidad y evidencia.
- **BDD** descubre el valor, los ejemplos y el comportamiento en lenguaje de negocio.
- **TDD** conduce el diseño interno mediante ciclos RED, GREEN y refactor.
- **ATDD** demuestra el resultado observable desde el límite ejecutable del sistema.

## Principio domain-first

El diseño comienza en el negocio, no en controladores, tablas, SDKs, colas ni frameworks. Antes de elegir detalles técnicos, la spec identifica:

- la capacidad de negocio y su bounded context;
- el lenguaje ubicuo y el significado preciso de sus términos;
- quién posee cada política: agregado, entidad, value object o servicio de dominio;
- invariantes, transiciones válidas e inválidas y eventos de dominio;
- ejemplos exitosos, contraejemplos y casos límite.

De ese modelo se derivan las capas y puertos técnicos. Si el dominio no cambia, la spec debe declarar `domain: not_affected` y justificarlo con evidencia; no se inventan objetos de dominio para cambios que sólo afectan orquestación o entrega.

## Reglas, workflows y skills

Los tres tipos de artefacto tienen responsabilidades distintas:

| Artefacto | Función | Ejemplo |
|---|---|---|
| Regla | Restricción permanente que el agente debe respetar | Orden inside-out, aislamiento de tests o límites de arquitectura |
| Workflow | Procedimiento con fases, decisiones, gates y evidencia | Crear una spec, implementar un cambio o corregir un bug |
| Skill | Criterio especializado que mejora cómo se ejecuta el trabajo | Modelado DDD/CQRS o ingeniería backend senior |

Los nombres y `workflow_id` son parte de la interfaz del agente. El ID del frontmatter es la identidad canónica y el nombre estable del archivo debe reflejar ese ID; ninguno se renombra salvo que cambie materialmente la intención del artefacto.

### Tipos de activación

- `always_on`: baseline breve de una regla o skill; se carga cuando también coincide su scope o `globs`.
- `model_decision`: regla, skill o workflow especializado; el agente lo carga sólo cuando el alcance lo requiere.
- `manual`: workflow principal que el usuario o el agente invoca explícitamente.
- `automatic`: workflow disparado por una condición objetiva, por ejemplo validación de PR o checkpoint de contexto.

No se permiten otros valores de `trigger`. `always_on` se reserva para constituciones y perfiles compactos; una guía extensa o especializada debe usar `model_decision` para no consumir contexto en tareas ajenas.

### Carga y precedencia para IA

La memoria global es el bootstrap compacto. Para cada tarea, el agente carga un solo workflow principal, las reglas comunes requeridas por esa fase, un solo perfil de lenguaje y únicamente las reglas de boundary afectadas. No carga el catálogo completo ni varias skills que repitan el mismo baseline.

Las reglas comunes obligatorias fijan el mínimo de seguridad, gates y dirección de dependencias. Las reglas locales del proyecto prevalecen cuando son más específicas o estrictas y no relajan ese mínimo; las reglas de lenguaje y boundary sólo lo especializan. Si dos instrucciones del mismo nivel son incompatibles, el agente debe señalar los archivos y la contradicción durante la planificación, sin inventar una tercera política.

En Cascade puede pedirse un workflow por su ID exacto. Por ejemplo:

```text
Usa WORKFLOW-CSHARP_SDD_IMPLEMENT_CHANGE_WORKFLOW para implementar este cambio.
Usa WORKFLOW-COMMON_SDD_FIX_BUG_WORKFLOW para diagnosticar y corregir este defecto.
```

El agente debe abrir el archivo correspondiente, seguir sus gates y registrar el routing en la spec. No debe improvisar un workflow a partir del nombre ni sustituirlo por una lista genérica de pasos.

## Cómo se componen los workflows

Una tarea tiene un solo workflow principal y puede invocar workflows de apoyo. Los workflows comunes gobiernan el ciclo SDD; los de lenguaje adaptan la ejecución; los de REST, Lambda, SNS o SQS añaden detalles del límite sin reemplazar el ciclo principal.

Ejemplo para una funcionalidad REST en C#:

```text
WORKFLOW-COMMON_SDD_SPEC_WORKFLOW
  -> WORKFLOW-COMMON_BDD_SPECIFICATION_WORKFLOW
  -> WORKFLOW-CSHARP_SDD_IMPLEMENT_CHANGE_WORKFLOW       # principal
       -> WORKFLOW-COMMON_REST_API_DESIGN_WORKFLOW      # apoyo
       -> WORKFLOW-CSHARP_REST_API_WORKFLOW             # adaptador
  -> gates de limpieza, seguridad, cobertura y documentación
  -> WORKFLOW-COMMON_SDD_VERIFY_SPEC_WORKFLOW
```

Un cambio vertical puede contener varios `work_type`, pero sigue perteneciendo a una sola spec y a un solo workflow de implementación:

```text
domain-rule
application-command
application-query
rest-endpoint
lambda-rest-endpoint
persistence-adapter
message-consumer
domain-event
sns-publisher
sqs-consumer
composition-root
boundary-integration-test
ci-pipeline
documentation
```

No se crea un workflow nuevo por endpoint, use case, repositorio, evento o registro de DI. Esas unidades se expresan como tareas pequeñas dentro del lifecycle.

## Selección del workflow principal

| Necesidad | Workflow principal |
|---|---|
| Crear o modificar una spec | [`WORKFLOW-COMMON_SDD_SPEC_WORKFLOW`](./common/workflows/common-sdd-spec.workflow.md) |
| Ejecutar el ciclo completo | [`WORKFLOW-COMMON_SDD_CHANGE_LIFECYCLE_WORKFLOW`](./common/workflows/common-sdd-change-lifecycle.workflow.md) |
| Corregir un defecto | [`WORKFLOW-COMMON_SDD_FIX_BUG_WORKFLOW`](./common/workflows/common-sdd-fix-bug.workflow.md) |
| Refactorizar sin cambiar comportamiento | [`WORKFLOW-COMMON_SDD_REFACTOR_LIFECYCLE_WORKFLOW`](./common/workflows/common-sdd-refactor-lifecycle.workflow.md) |
| Refactorizar production code | [`WORKFLOW-COMMON_SDD_REFACTOR_PRODUCTION_CODE_WORKFLOW`](./common/workflows/common-sdd-refactor-production-code.workflow.md) |
| Refactorizar unit tests | [`WORKFLOW-COMMON_SDD_REFACTOR_UNIT_TESTS_WORKFLOW`](./common/workflows/common-sdd-refactor-unit-tests.workflow.md) |
| Refactorizar integration tests de infraestructura | [`WORKFLOW-COMMON_SDD_REFACTOR_INTEGRATION_TESTS_WORKFLOW`](./common/workflows/common-sdd-refactor-integration-tests.workflow.md) |
| Refactorizar HTTP integration tests | [`WORKFLOW-COMMON_SDD_REFACTOR_HTTP_TESTS_WORKFLOW`](./common/workflows/common-sdd-refactor-http-tests.workflow.md) |
| Migrar tests legacy a la estructura canónica | [`WORKFLOW-COMMON_SDD_MIGRATE_LEGACY_TESTS_WORKFLOW`](./common/workflows/common-sdd-migrate-legacy-tests.workflow.md) |
| Implementar backend Go | [`WORKFLOW-GO_SDD_IMPLEMENT_CHANGE_WORKFLOW`](./languages/go/workflows/go-sdd-implement-change.workflow.md) |
| Implementar backend C# | [`WORKFLOW-CSHARP_SDD_IMPLEMENT_CHANGE_WORKFLOW`](./languages/csharp/workflows/csharp-sdd-implement-change.workflow.md) |
| Implementar una feature React | [`WORKFLOW-REACT_IMPLEMENT_FEATURE_WORKFLOW`](./languages/react/workflows/react-implement-feature.workflow.md) |
| Cambiar un frontend web ligero | [`WORKFLOW-WEB_IMPLEMENT_FRONTEND_CHANGE_WORKFLOW`](./languages/web/workflows/web-implement-frontend-change.workflow.md) |
| Crear o modificar GitHub Actions | [`WORKFLOW-COMMON_SDD_CREATE_GITHUB_ACTIONS_PIPELINE_WORKFLOW`](./common/workflows/common-sdd-create-github-actions-pipeline.workflow.md) |
| Revisar un pull request | [`WORKFLOW-COMMON_REVIEW_PULL_REQUEST_WORKFLOW`](./common/workflows/common-review-pull-request.workflow.md) |
| Validar evidencia y registrar `verified` | [`WORKFLOW-COMMON_SDD_VERIFY_SPEC_WORKFLOW`](./common/workflows/common-sdd-verify-spec.workflow.md) |

La taxonomía completa y las equivalencias heredadas están en [common-workflow-taxonomy.md](./common/rules/common-workflow-taxonomy.md).

## Ciclo SDD e inside-out TDD

Todo cambio de comportamiento sigue este orden:

```text
plan read-only
  -> Gate 1: autorizar creación o modificación de la spec
  -> descubrir valor, ejemplos, BDD y modelo de dominio
  -> crear spec, plan, tareas, routing y trazabilidad
  -> Gate 2: autorizar el inicio de RED
  -> Domain RED -> Gate 3-DOMAIN -> GREEN/refactor -> layer gate
  -> Application RED -> Gate 3-APPLICATION -> GREEN/refactor -> core gate
  -> si cambia producción externa: Boundary RED -> Gate 3-BOUNDARY
  -> Infrastructure -> Interface -> Composition/IaC
  -> Boundary GREEN a través del composition root real
  -> gates de limpieza, seguridad, cobertura y documentación según el riesgo
  -> convergencia entre spec, código, tests y documentación
  -> validación final de la spec y registro del estado verified
```

Los gates humanos de implementación son:

1. **Gate 1** autoriza escribir los artefactos de la spec.
2. **Gate 2** autoriza crear y ejecutar el primer RED.
3. **Gate 3** revisa evidencia RED real antes del GREEN de cada capa afectada. La aprobación de Domain no autoriza Application ni Boundary.

La revisión final de evidencia confirma que los artefactos convergen y registra `status: verified`; no renombra la carpeta.

La producción de una capa no se modifica hasta que exista un test de esa capa fallando por la razón esperada, se apruebe su Gate 3 y haya pasado el gate de la capa interior. Boundary RED sólo se crea cuando cambia producción externa; si no cambia, se conserva evidencia GREEN y se registra `not_affected`.

## Artefactos de una spec

Cada cambio vive en una carpeta propiedad del proyecto:

```text
specs/
  constitution.md
  features/
    0001-feature-slug/
      spec.md
      change-summary.md
      acceptance.feature
      invariants.md                 # cuando cambia el dominio
      plan.md
      tasks.md
      workflow-routing.md
      parallel-tracks.md
      traceability.yaml
      red-green-refactor.md
      security-review.md
      code-quality-review.md
      verification.md
      handoffs/
      history/
```

Los IDs estables enlazan intención y evidencia: `FEAT-*`, `US-*`, `REQ-*`, `SCN-*`, `T-*`, `TEST-*`, `CHG-*` y `ART-*`. Cada definición incluye también un título legible. `workflow-routing.md` declara el workflow principal y los workflows de apoyo de cada fase y tarea.

Cuando se consume el 60% del contexto, [`WORKFLOW-COMMON_SDD_CONTEXT_CHECKPOINT_WORKFLOW`](./common/workflows/common-sdd-context-checkpoint.workflow.md) crea un handoff reanudable y pausa el trabajo nuevo. La spec permanece en su ruta estable y se valida mediante [`WORKFLOW-COMMON_SDD_VERIFY_SPEC_WORKFLOW`](./common/workflows/common-sdd-verify-spec.workflow.md).

## Modelo de tests backend

Los backends usan exactamente dos suites de runtime:

- `unit`: comportamiento de Domain y Application sin infraestructura externa.
- `integration`: suite bajo `tests/integration/` con dos scopes: `http/` como ruta canónica de compatibilidad para la entrada pública real e `infrastructure/` para adapters contra bases de datos, colas, caches y storage locales reales. En sistemas no HTTP, el primer scope usa la entrada real de mensaje, worker o CLI y se denomina boundary integration test, no HTTP test.

Domain, Application, HTTP integration e Infrastructure integration deben poder ejecutarse por separado, desde estado limpio y sin consumir fixtures o estado mutable de otra capa. HTTP e Infrastructure siguen siendo scopes de la misma suite `integration`. Las APIs de terceros se simulan con WireMock u otra herramienta equivalente; la infraestructura local se levanta con Docker, Testcontainers o emuladores fieles.

Los gates obligatorios incluyen limpieza, seguridad, documentación y cobertura de producción del proyecto de al menos 90%. Mutation testing y E2E crítico se activan según el riesgo.

## Dependency Injection por módulo

Cada módulo de negocio es dueño de su composición. El ejecutable conoce la entrada pública del módulo, pero no registra manualmente sus repositorios, handlers o servicios internos.

En C#, cada módulo expone un extension method por capa:

```text
Add<Module>Domain(...)
Add<Module>Application(...)
Add<Module>Infrastructure(...)
Add<Module>Interface(...)
Add<Module>Module(...)          # fachada que compone las capas
```

El composition root llama únicamente a `Add<Module>Module(...)`. Las reglas detalladas están en [csharp-dependency-injection.md](./languages/csharp/rules/csharp-dependency-injection.md).

En Go, cada módulo posee `internal/<module>/di`, donde construye sus dependencias y expone una entrada de módulo. `cmd` o el composition root importa esa entrada y no cablea los detalles internos de otros módulos. Véase [go-dependency-injection.md](./languages/go/rules/go-dependency-injection.md).

## Estructura del repositorio

```text
common/
  rules/       # constitución SDD, arquitectura, testing y guardrails
  workflows/   # lifecycle común y procedimientos de apoyo
  skills/      # capacidades reutilizables entre lenguajes
  templates/   # plantillas de evidencia y handoff

languages/
  csharp/      # reglas, workflows y skills de .NET
  go/          # reglas, workflows y skills de Go
  react/       # React + TypeScript + Vite
  web/         # frontend web ligero

tools/
  validate-sdd-change.sh
  validate-bdd-spec.sh
  create-sdd-context-checkpoint.sh
  windsurf/
```

`common/` contiene el comportamiento canónico compartido. Los directorios de lenguaje sólo agregan detalles de ejecución y no pueden relajar los gates comunes.

## Instalación global en Windsurf y JetBrains

El repositorio es la fuente de verdad. No deben copiarse reglas administradas dentro de cada proyecto HBK.

```bash
bash tools/windsurf/install-global.sh
bash tools/windsurf/verify-global.sh
```

La instalación publica el catálogo de usuario en:

```text
~/.codeium/windsurf/common/
~/.codeium/windsurf/global_workflows/
~/.codeium/windsurf/skills/
~/.codeium/windsurf/memories/global_rules.md
```

En macOS también se publica el fallback de sistema en `/Library/Application Support/Windsurf/`. Si se requieren privilegios administrativos:

```bash
sudo bash tools/windsurf/install-system.sh
```

El instalador sincroniza el MCP compartido usado por Rider, GoLand y WebStorm. Sus roots incluyen `~/Projects/HBK` y este repositorio. Después de instalar o cambiar roots se deben reiniciar completamente los IDEs.

La resolución de un workflow sigue este orden:

1. catálogo canónico común o del lenguaje;
2. catálogo global de usuario;
3. fallback de sistema para JetBrains.

Los detalles de resolución y mantenimiento están en [tools/windsurf/README.md](./tools/windsurf/README.md).

## Validación

El propio catálogo valida metadata, IDs, triggers, referencias, links, presupuesto `always_on` y thresholds compartidos mediante:

```bash
bash tools/validate-agent-catalog.sh
```

Los proyectos consumidores ejecutan la política SDD en CI mediante:

```bash
bash tools/validate-sdd-change.sh
```

La validación comprueba estructura, IDs, routing, riesgo, orden de capas y evidencia requerida. No reemplaza los tests, la revisión de seguridad, la cobertura ni los demás gates; sólo confirma que sus artefactos son coherentes.

Para verificar el catálogo instalado localmente:

```bash
bash tools/windsurf/verify-global.sh
```

## Fuente de verdad

- Las reglas reutilizables viven en `common/` y `languages/`.
- Las specs pertenecen al proyecto consumidor y viven en `specs/`.
- No se mantienen copias administradas en `.windsurf/`, `.agents/`, `.devin/`, `AGENTS.md` o `.windsurfrules` de cada proyecto.
- Los cambios al catálogo se realizan aquí, se validan y después se vuelven a publicar globalmente.

## Licencia

Este proyecto se publica bajo CC0 1.0 Universal. Véase [LICENSE.md](./LICENSE.md).
