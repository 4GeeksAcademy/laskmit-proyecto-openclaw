# 4geeks-pendientes — Obtener trabajo pendiente de 4Geeks Academy

## Propósito
Consultar el trabajo pendiente del estudiante en la cohorte activa `latam-aie-pt-1` de 4Geeks Academy y mostrar 3 tablas detalladas con todos los ítems individualmente:
1. **Proyectos pendientes** — tabla con cada proyecto en una fila (MÓDULO | PROYECTO)
2. **Lecciones pendientes** — tabla con cada lección en una fila (MÓDULO | LECCIÓN)
3. **Ejercicios pendientes** — tabla con cada ejercicio en una fila (MÓDULO | EJERCICIO)

## Endpoints utilizados

### GET /v1/admissions/user/me
- **Propósito**: Obtener información del usuario, incluyendo cohortes activas
- **Autenticación**: `Authorization: Token <token>`
- **Sin parámetros**
- **Respuesta**: Objeto de usuario con `cohorts[]` (cada elemento tiene `cohort.id` y `cohort.slug`)

### GET /v1/assignment/user/me/task
- **Propósito**: Obtener tareas asignadas al usuario
- **Autenticación**: `Authorization: Token <token>`
- **Parámetros query**:
  - `cohort` (id numérico del cohorte): Filtra tareas de una cohorte específica
  - `task_status` (opcional): PENDING, DONE, APPROVED, REJECTED
  - `task_type` (opcional): PROJECT, LESSON, EXERCISE, QUIZ
  - `limit` y `offset` (opcional): Paginación
- **Respuesta**: Lista de tareas, cada una con `associated_slug`, `title`, `task_type`, `task_status`, `revision_status`

## Flujo de uso
1. El script carga el token desde `.env` (variable `4GEEKS_ACCESS_TOKEN`)
2. Consulta `GET /v1/admissions/user/me` para obtener datos del usuario
3. Busca la cohorte con slug `latam-aie-pt-1` y obtiene su `id`
4. Consulta `GET /v1/assignment/user/me/task?cohort=<id>` para obtener todas las tareas de esa cohorte
5. Separa por tipo: `PROJECT`, `LESSON`, `EXERCISE`
6. **Deduplica por `associated_slug`**: el mismo item puede aparecer en múltiples cohortes (el usuario está en varias); se toma el mejor estado:
   - **Proyectos**: Se considera el mejor `revision_status` (APPROVED > REJECTED > PENDING), y si están igual, el mejor `task_status` (DONE > PENDING)
   - **Lecciones y Ejercicios**: Se considera el mejor `task_status` (DONE > PENDING)
7. **Filtra solo PENDING**: `task_status == "PENDING"`
8. **Asigna módulo** a cada item según su `associated_slug` (mapeo manual con fallback por inferencia de palabras clave)
9. **Ordena** alfabéticamente por módulo, luego por título
10. Muestra 3 tablas con bordes de estilo ASCII (`+---+---+`) con todas las filas individuales

## Mapeo Slug → Módulo (diccionario completo)

| Slug | Módulo |
|------|--------|
| `postcard` | AI Engineering |
| `excuses-generator-javascript` | AI Engineering |
| `ai-eng-milestone-choose-company` | AI Engineering |
| `html-css-artist-landing-seo-access` | Web UI / Tailwind |
| `simple-dashboard-tailwind-css` | Web UI / Tailwind |
| `ai-eng-milestone-web-fundamentals` | Web UI / Tailwind |
| `exercise-terminal-challenge` | Command Line, Git y Github |
| `first-collaborative-project-tailwind-css` | Command Line, Git y Github |
| `ai-eng-architectural-proposal` | Backend / APIs |
| `ai-eng-user-authentication-api` | Backend / APIs |
| `agent-hub-ui-specs-and-prompts` | Frontend / React |
| `data-modeling-and-class-diagrams` | TypeScript / Coding Fundamentals |
| `music-playlist-player-modeling-and-class-diagrams` | TypeScript / Coding Fundamentals |
| `typescript-cinema-seat-manager` | TypeScript / Coding Fundamentals |
| `ai-eng-milestone-coding-fundamentals` | TypeScript / Coding Fundamentals |
| `nextjs-airbnb-ui-clone` | Frontend / React |
| `nextjs-wanderlust-explorer` | Frontend / React |
| `chat-interface-real-ai-api` | Frontend / React |
| `ai-eng-milestone-talent-pipeline-tracker` | Frontend / React |
| `openclaw-setup` | AI Engineering / OpenClaw |
| `openclaw-connection` | AI Engineering / OpenClaw |
| `openclaw-skills` | AI Engineering / OpenClaw |
| `openclaw-integration` | AI Engineering / OpenClaw |
| `openclaw-onboarding-agent` | AI Engineering / OpenClaw |
| `company-financial-dashboard-context-project` | AI Coding Agents |
| `company-financial-dashboard-specs-project` | AI Coding Agents |
| `company-financial-dashboard-skills-project` | AI Coding Agents |
| `ai-eng-ai-driven-engineering` | AI Coding Agents |
| `todo-list-cli-python` | Python |
| `learning-to-code-with-python` | Python |
| `conditionals-in-programing-python` | Python |
| `working-with-functions-python` | Python |
| `what-are-third-party-libraries` | Python |
| `understanding-rest-apis` | Backend / APIs |
| `how-to-consume-an-api-in-python` | Python |
| `how-to-read-a-file-in-python` | Python |
| `intro-to-numpy` | Python |
| `intro-to-python-pandas` | Python |
| `what-are-python-dictionaries` | Python |
| `sorting-and-search-algorithms-in-python` | Python |
| `what-is-a-python-list` | Python |
| `python-modules-organizing-and-reusing-code-like-an-expert` | Python |
| `understanding-objects-models-properties-and-dat-en` | TypeScript / Coding Fundamentals |
| `html-fundamentals-building-web-structure-en` | Web UI / Tailwind |
| `css-mastery-from-scratch-en` | Web UI / Tailwind |
| `command-line-fundamentals-for-developers-en` | Command Line, Git y Github |

Si un slug no está en el diccionario, se usa la función `inferir_modulo()` que analiza palabras clave en el slug + título.

## Códigos de estado manejados
| HTTP | Significado | Acción |
|------|-------------|--------|
| 200 | Éxito | Procesa y muestra las 3 tablas |
| 401/403 | Token inválido | Mensaje de error, sugiere ejecutar `verify_token.sh` |
| 000 | Sin conexión | Mensaje de error de conexión |
| Otros | Error inesperado | Muestra el código y los primeros 500 caracteres de respuesta |

## Archivos
- `scripts/get_pendientes.sh` — Script principal ejecutable

## Diagnóstico
Si el script falla por autenticación, ejecutar primero:
```bash
bash skills/4geeks-auth/scripts/verify_token.sh
```

## Notas
- Solo se filtra por cohorte `latam-aie-pt-1`
- Los items se **deduplican por slug** y se toma el mejor estado
- El mapeo módulo se actualiza manualmente si cambia el syllabus
- La API no expone módulo directamente; se infiere del `associated_slug`
- Orden de visualización: alfabético por módulo, luego por título
- **NO se agrupan los ejercicios** — cada ejercicio aparece en su propia fila igual que proyectos y lecciones