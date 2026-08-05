# 4geeks-projects — Obtener mis proyectos de 4Geeks Academy

## Propósito
Recuperar la lista de proyectos asignados al usuario, agrupar por `associated_slug` (tomando el mejor estado entre todas las cohortes), y mostrar 4 tablas con 2 columnas: **Módulo | Proyecto**.

## Endpoint
**GET** `https://breathecode.herokuapp.com/v1/assignment/user/me/task`

- Autenticación: `Authorization: Token <token>`
- Sin trailing slash (con slash devuelve 404 HTML)

## Flujo de uso
1. El script carga el token desde `.env` (variable `4GEEKS_ACCESS_TOKEN`)
2. Hace GET al endpoint con `Authorization: Token`
3. Filtra solo proyectos (`task_type == "PROJECT"`)
4. **Agrupa por `associated_slug`** — el mismo proyecto aparece una vez por cohorte; se toma el mejor estado (APROBADO > ENTREGADO > PENDIENTE)
5. Asigna **módulo** según el slug del proyecto (mapeo manual)
6. Clasifica en **4 categorías**:
   - **APROBADOS**: `revision_status == "APPROVED"`
   - **RECHAZADOS**: `revision_status == "REJECTED"`
   - **ESPERANDO APROBACIÓN**: `task_status == "DONE"` sin aprobar ni rechazar
   - **PENDIENTES**: `task_status == "PENDING"`
7. Muestra resumen numérico, luego una tabla por categoría con formato `MÓDULO | PROYECTO`

## Mapeo Slug → Módulo

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

## Códigos de estado manejados
| HTTP | Significado | Acción |
|------|-------------|--------|
| 200 | Éxito | Procesa y muestra los proyectos |
| 401/403 | Token inválido | Mensaje de error, sugiere ejecutar `verify_token.sh` |
| 000 | Sin conexión | Mensaje de error de conexión |
| Otros | Error inesperado | Muestra el código y los primeros 500 caracteres de respuesta |

## Archivos
- `scripts/get_projects.sh` — Script principal ejecutable

## Diagnóstico
Si el script falla por autenticación, ejecutar primero:
```bash
bash skills/4geeks-auth/scripts/verify_token.sh
```

## Notas
- Los proyectos se **deduplican por slug** y se toma el mejor estado entre cohortes
- El mapeo módulo se actualiza manualmente si cambia el syllabus
- La API no expone módulo directamente; se infiere del `associated_slug` y el cohort
- Orden de visualización: alfabético por módulo, luego por título del proyecto