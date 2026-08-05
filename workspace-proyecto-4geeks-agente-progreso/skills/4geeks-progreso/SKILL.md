# 4geeks-progreso — Resumen de progreso académico en 4Geeks Academy

## Propósito
Consultar el progreso total del estudiante a través de **todas las cohortes activas**, deduplicando por `associated_slug` y mostrando:

1. **Resumen general** — progreso general en barra visual + porcentaje
2. **Resumen por tipo** — tablas de proyectos, lecciones y ejercicios con completados vs pendientes
3. **Progreso por módulo** — matriz módulo × tipo con conteo completado/total
4. **Cohortes activas** — lista de cohortes en las que el estudiante está inscrito
5. **Detalle de pendientes** — todos los ítems pendientes agrupados por módulo, con cada título individual

## Endpoints utilizados

### GET /v1/admissions/user/me
- **Propósito**: Obtener información del usuario, incluyendo todas las cohortes
- **Autenticación**: `Authorization: Token <token>`
- **Respuesta**: Objeto de usuario con `cohorts[]` (cada elemento tiene `cohort.id`, `cohort.slug`, `educational_status`)

### GET /v1/assignment/user/me/task
- **Propósito**: Obtener **todas** las tareas del usuario sin filtrar por cohorte
- **Autenticación**: `Authorization: Token <token>`
- **Parámetros query**: ninguno — se obtienen todas las tareas de todas las cohortes
- **Respuesta**: Lista completa de tareas a través de todas las cohortes del usuario

## Diferencias clave con skills anteriores

| Aspecto | Skills anteriores (pendientes/proyectos) | Este skill (progreso) |
|---------|------------------------------------------|----------------------|
| Filtro | Solo cohorte `latam-aie-pt-1` | **Todas** las cohortes |
| Salida | Tablas con todos los ítems | Resumen con barras + detalle |
| Dedup | Por cohorte | **Global** — mejor estado entre todas las cohortes |
| Información | Listado de pendientes | Visión general de progreso |

## Flujo de uso
1. El script carga el token desde `.env`
2. Consulta `GET /v1/admissions/user/me` para obtener datos del usuario y sus cohortes
3. Consulta `GET /v1/assignment/user/me/task` (sin filtro) para obtener **todas** las tareas
4. **Deduplica globalmente por `associated_slug`** tomando el mejor estado entre cohortes:
   - **Proyectos**: prioriza `revision_status` (APPROVED > REJECTED > PENDING), luego `task_status` (DONE > PENDING)
   - **Lecciones y Ejercicios**: prioriza `task_status` (DONE > PENDING)
5. Clasifica cada ítem en un módulo según su `associated_slug`
6. Calcula progreso: total vs completados vs pendientes
7. Muestra resumen general, tabla por tipo, tabla por módulo, cohortes activas y detalle de pendientes

## Estados considerados

### Proyectos
- **APROBADOS**: `revision_status == "APPROVED"` (revisión aprobada)
- **EN REVISIÓN**: `task_status == "DONE"` pero sin revisión aprobada/rechazada
- **RECHAZADOS**: `revision_status == "REJECTED"`
- **PENDIENTES**: `task_status == "PENDING"`

### Lecciones y Ejercicios
- **COMPLETADOS**: `task_status == "DONE"`
- **PENDIENTES**: `task_status == "PENDING"`

## Mapeo Slug → Módulo
El mapeo se realiza mediante un diccionario manual de slugs conocidos con fallback por inferencia de palabras clave. Ver SKILL.md de `4geeks-pendientes` para la lista completa del diccionario.

## Códigos de estado manejados
| HTTP | Significado | Acción |
|------|-------------|--------|
| 200 | Éxito | Procesa y muestra el resumen completo |
| 401/403 | Token inválido | Mensaje de error |
| 000 | Sin conexión | Mensaje de error de conexión |
| Otros | Error inesperado | Muestra el código y respuesta |

## Archivos
- `scripts/get_progreso.sh` — Script principal ejecutable

## Interpretación del progreso
Los totales reflejan **ítems únicos por slug** a través de todas las cohortes activas y graduadas. Un mismo proyecto/lección/ejercicio puede aparecer en múltiples cohortes; el script toma el estado más avanzado.

**Ejemplo**: Si un proyecto aparece en la cohorte A como PENDING y en la cohorte B como DONE, se cuenta como completado porque en algún momento se hizo. La deduplicación global evita contar dos veces el mismo ítem.