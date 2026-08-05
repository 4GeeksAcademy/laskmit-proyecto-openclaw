# 4geeks-actividad — Actividad en la plataforma 4Geeks Academy

## Propósito
Consultar la actividad del estudiante en la plataforma 4Geeks, mostrando para cada lección:

- **Certificado** al que pertenece (Web UI, Typescript, Python, etc.)
- **Nombre** de la lección
- **Fecha de inicio** (mínimo entre `created_at` y `opened_at`)
- **Fecha de culminación** (`updated_at` más reciente cuando `task_status == "DONE"`)
- **Duración total** en horas entre inicio y culminación

## Endpoint utilizado

### GET /v1/assignment/user/me/task
- **Propósito**: Obtener todas las asignaciones del usuario (lecciones, ejercicios, proyectos)
- **Autenticación**: `Authorization: Token <token>`
- **Filtro**: Internamente se filtran solo las de tipo `LESSON`

## Lógica de agrupación

Las lecciones se agrupan por **Certificado** según el campo `cohort.name` de cada tarea en la API. El orden de presentación es el mismo que aparece en la plataforma:

1. Web UI Fundamentals with Tailwind CSS
2. Command line - Git & Github
3. Coding fundamentals with Typescript
4. Frontend with React
5. Personal assistants with Openclaw
6. Working with AI coding agents
7. Advanced personal assistants with Openclaw
8. Coding Fundamentals with Python
9. Backend development with Coding Agents
10. Authentication in web applications
11. Error handling, debugging and testing
    *AI Engineering Introduction (certificado 0, inicial)*

Las lecciones que pertenecen al cohort general `latam-aie-pt-1` se muestran al final si no están ya cubiertas por un certificado específico.

## Lógica de duración

- **Inicio**: fecha más temprana entre `created_at` y `opened_at`
- **Culminación**: `updated_at` más reciente entre las entradas con `task_status == "DONE"`
- **Duración**: `culminación - inicio` en horas; si no hay fecha de culminación se muestra `—`

## Deduplicación
Una misma lección puede aparecer en múltiples cohorts. El script:
1. Si una lección ya fue mostrada en un certificado específico, no se repite en el cohort general
2. Por cada lección, toma la fecha de inicio más temprana y la de culminación más reciente

## Archivos
- `scripts/get_actividad.sh` — Script wrapper ejecutable
- `scripts/get_actividad.py` — Script principal en Python

## Formato de salida
```
  Certificado
  +-------------------------------+------------------+------------+---------------------+----------+
  | LECCION                       | TITULO           | INICIO     | CULMINACION         | DURACION |
  +-------------------------------+------------------+------------+---------------------+----------+
  | slug                          | Título           | YYYY-MM-DD | YYYY-MM-DD HH:MM    | 12.3h    |
  +-------------------------------+------------------+------------+---------------------+----------+
```

Al final se muestra un resumen con total de lecciones, completadas vs pendientes, y tiempo total invertido.