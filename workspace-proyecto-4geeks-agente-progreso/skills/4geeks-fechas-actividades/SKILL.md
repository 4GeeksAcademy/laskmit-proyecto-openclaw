# 4geeks-fechas-actividades

## Propósito

Generar un reporte detallado con **fechas de inicio y culminación** de **todas las actividades** (exercises, lessons, projects) del alumno en la plataforma 4Geeks Academy, agrupadas por **certificado/módulo**. Cada fila muestra: slug de la actividad, título, fecha de inicio, fecha de culminación y estado actual (✅ completada / ⬜ pendiente).

## Requisitos

- Token de acceso a la API de 4Geeks Academy (en `/root/.openclaw/workspace/.env` como `4GEEKS_ACCESS_TOKEN`)
- Python 3
- `curl`

## Ubicación del script

```
/root/.openclaw/workspace/skills/4geeks-actividad/scripts/get_actividad_por_modulo.py
```

## Output

- **Pantalla:** Reporte completo con tablas por certificado + resumen global
- **Archivo:** Se guarda automáticamente en `archivos_resultados/YY-MM-DD-resultado-skill-fechas-actividades.md`

## Cómo ejecutar

```bash
cd /root/.openclaw/workspace/skills/4geeks-actividad/scripts && python3 get_actividad_por_modulo.py
```

Para guardar el resultado en archivos_resultados:

```bash
cd /root/.openclaw/workspace/skills/4geeks-actividad/scripts && python3 get_actividad_por_modulo.py | tee /root/.openclaw/workspace/archivos_resultados/$(date +%y-%m-%d)-resultado-skill-fechas-actividades.md
```

## Procedimiento detallado (reglas)

### 1. Obtener el token

El token se lee de la variable `4GEEKS_ACCESS_TOKEN` en el archivo `/root/.openclaw/workspace/.env`.
**Nunca debe estar hardcodeado en el script.** Se extrae con:

```python
with open(TOKEN_FILE) as f:
    for line in f:
        line = line.strip()
        if line.startswith("4GEEKS_ACCESS_TOKEN"):
            token = line.split("=", 1)[1].strip().strip("'\"").strip()
```

### 2. Consultar la API

**Endpoint:** `https://breathecode.herokuapp.com/v1/assignment/user/me/task`
**Header:** `Authorization: Token <token>` (formato Token, NO Bearer)
**Timeout:** 30 segundos

La respuesta es un array JSON de objetos `task`. Cada task tiene estos campos clave:

| Campo | Tipo | Descripción |
|---|---|---|
| `associated_slug` | string | Identificador único de la actividad |
| `title` | string | Título descriptivo |
| `task_type` | string | `EXERCISE`, `LESSON`, o `PROJECT` |
| `task_status` | string | `DONE` o `PENDING` |
| `created_at` | string (ISO) | Fecha de creación / inicio |
| `delivered_at` | string (ISO) | Fecha de entrega |
| `updated_at` | string (ISO) | Última actualización |
| `cohort` | object | Contiene `id`, `name`, `slug` del certificado |

### 3. Reglas de deduplicación

Una misma actividad (`associated_slug`) puede aparecer varias veces si el alumno está en varios cohorts (certificados). Se aplican estas reglas:

1. **Una actividad se asigna al certificado más específico** (excluyendo el cohort genérico `latam-aie-pt-1`). Si aparece en dos certificados, se prioriza el que aparece primero en `ORDEN_CERTIFICADOS`.
2. **El cohort genérico `latam-aie-pt-1` NO se muestra como certificado independiente.** Es el contenedor general del curso y no debe aparecer en la lista de certificados.
3. **Las actividades que SOLO existen en `latam-aie-pt-1`** (no están en ningún certificado específico) se muestran al final bajo **"Otras actividades (sin certificado específico)"**, agrupadas por módulo estimado.
4. Cuando hay duplicados del mismo slug en el mismo cohort, se prioriza el registro con `task_status = DONE` sobre `PENDING`.

### 4. Orden de los certificados

Los certificados se muestran en un orden fijo que coincide con la plataforma:

```
01 → Web UI Fundamentals with Tailwind CSS
02 → Command line - Git & Github
03 → Coding fundamentals with Typescript
04 → Frontend development with Coding Agents
05 → Personal assistants with Openclaw
06 → Working with AI coding agents
07 → Advanced personal assistants with Openclaw
08 → Coding Fundamentals with Python
09 → Backend development with Coding Agents
10 → Authentication in web applications
11 → Error handling, debugging and testing
00 → AI Engineering Introduction
```

### 5. Columnas de la tabla

| Columna | Fuente | Ancho |
|---|---|---|
| ACTIVIDAD | `associated_slug` truncado a 30 chars | 32 |
| TITULO | `title` truncado a 48 chars | 50 |
| INICIO | `created_at` en formato YYYY-MM-DD (solo fecha) | 10 |
| CULMINACION | `delivered_at` si existe, si no `updated_at`, en YYYY-MM-DD | 12 |
| EST | ✅ si `DONE`, ⬜ si `PENDING` | 6 |

### 6. Fechas

- **INICIO** = `created_at` → primeros 10 caracteres (`YYYY-MM-DD`)
- **CULMINACION** = `delivered_at` si tiene valor, si no `updated_at` → primeros 10 caracteres
- Si no hay fecha disponible, se muestra `—`

**No se calcula duración** porque la API no registra horas reales de trabajo — solo fechas de calendario.

### 7. Clasificación de "Otras actividades"

Cuando una actividad solo está en el cohort genérico, se intenta inferir su módulo usando palabras clave en el slug y el título:

| Palabra clave | Módulo |
|---|---|
| `openclaw` | AI Engineering / OpenClaw |
| `python`, `numpy`, `pandas` | Python |
| `react`, `nextjs`, `context-api` | Frontend / React |
| `api`, `rest`, `fastapi` | Backend / APIs |
| `tailwind`, `css`, `html`, `web`, `seo`, `responsive`, `form` | Web UI / Tailwind |
| `git`, `github`, `command`, `terminal`, `vps`, `ssh` | Command Line / Git |
| `typescript`, `javascript`, `coding`, `program`, `function`, `array`, `object`, `class`, `data` | Coding Fundamentals |
| `test`, `debug`, `error` | Error Handling / Testing |
| `auth`, `session`, `token`, `login`, `password` | Authentication |
| `agent`, `ai` | AI / Coding Agents |

**Importante:** La clasificación inferida es solo una ayuda visual — el alumno debe verificar que esas actividades están en el certificado correcto. Cuando la plataforma las asigne formalmente a un certificado, se moverán automáticamente.

### 8. Tabla resumen final

Al final del reporte se genera una tabla con:

- **TOTAL:** Actividades totales en el certificado
- **COMPLETADAS:** Actividades con status `DONE`
- **PENDIENTES:** Actividades con status `PENDING`
- **AVANCE:** Porcentaje de completadas

Se incluye una fila para **"Otras — sin certificado"** y la fila **TOTAL** global.

## Archivos relacionados

- Script principal: `get_actividad_por_modulo.py`
- Script consolidado (dual mode): `get_actividad.py`
- Outputs históricos: `archivos_resultados/*-resultado-skill-fechas-actividades.md`

## Mantenimiento

El script es **100% automático**. Cuando la plataforma:
- Asigne nuevas actividades → aparecerán automáticamente en su certificado
- Cree nuevos certificados → aparecerán automáticamente (el campo `cohort` viene en cada tarea)
- Complete actividades → cambiarán de ⬜ a ✅

No se requiere mantenimiento manual de diccionarios de módulos ni de mapeos de slugs.