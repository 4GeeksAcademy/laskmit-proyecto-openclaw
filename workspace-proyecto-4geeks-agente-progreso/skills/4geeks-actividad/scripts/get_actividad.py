#!/usr/bin/env python3
"""
get_actividad.py — Skill 4geeks-actividad
Muestra el contenido completo de la plataforma 4Geeks Academy,
agrupado por Certificado (cohort), detallando cada actividad
con su fecha de inicio y culminación.
"""
import json, subprocess, sys
from datetime import datetime
from collections import OrderedDict, defaultdict

# ── Token ──────────────────────────────────────────────────────
token = None
with open("/root/.openclaw/workspace/.env") as f:
    for line in f:
        if line.startswith("4GEEKS_ACCESS_TOKEN"):
            token = line.split("=", 1)[1].strip().strip("'\"")
            break
if not token:
    print("ERROR: No se encontró 4GEEKS_ACCESS_TOKEN en .env")
    sys.exit(1)

# ── API call ───────────────────────────────────────────────────
print("\n  Consultando actividades en la plataforma...\n")

def api_get(path):
    url = f"https://breathecode.herokuapp.com/{path}"
    r = subprocess.run(
        ["curl", "-s", "-H", f"Authorization: Token {token}", url, "--max-time", "30"],
        capture_output=True, text=True)
    return json.loads(r.stdout)

tasks = api_get("v1/assignment/user/me/task")
if not isinstance(tasks, list):
    print(f"  ERROR al consultar API: {tasks}")
    sys.exit(1)

# ── Orden de certificados (el mismo del PDF) ───────────────────
CERTIFICADOS = OrderedDict([
    ("web-ui-fundamentals-with-tailwind-css",       "01 - Web UI Fundamentals with Tailwind CSS"),
    ("command-line-git-github",                      "02 - Command line - Git & Github"),
    ("coding-fundamentals-with-typescript",          "03 - Coding fundamentals with Typescript"),
    ("latam-frontend-development-with-coding-agents","04 - Frontend with React"),
    ("personal-assitant-with-openclaw",              "05 - Personal assistants with Openclaw"),
    ("working-with-ai-coding-agents",                "06 - Working with AI coding agents"),
    ("advanced-personal-assitant-with-openclaw",     "07 - Advanced personal assistants with Openclaw"),
    ("latam-coding-fundamentals-with-python",        "08 - Coding Fundamentals with Python"),
    ("backend-development-with-coding-agents",      "09 - Backend development with Coding Agents"),
    ("authentication-web-applications",              "10 - Authentication in web applications"),
    ("error-handling-debugging-testing",             "11 - Error handling, debugging and testing"),
    ("latam-ai-engineering-introduction",            "00 - AI Engineering Introduction"),
])

# ── Parsear fechas ─────────────────────────────────────────────
def parse_dt(s):
    if not s:
        return None
    for fmt in ["%Y-%m-%dT%H:%M:%S.%f", "%Y-%m-%dT%H:%M:%S"]:
        try:
            return datetime.strptime(s.replace("Z","")[:26], fmt)
        except:
            continue
    return None

# ── Agrupar tareas por cohort (certificado) ────────────────────
# Estructura: cohort_slug -> dict de slugs -> lista de entradas
cohort_tasks = defaultdict(lambda: defaultdict(list))

for t in tasks:
    cohort = t.get("cohort", {})
    cs = cohort.get("slug", "") if cohort else ""
    if not cs:
        continue
    slug = t.get("associated_slug", "")
    if not slug:
        continue
    cohort_tasks[cs][slug].append(t)

# ── Variables de resumen ───────────────────────────────────────
total_items = 0
total_done = 0

# ── Función para mostrar una actividad individual ──────────────
def mostrar_actividad(slug, slug_set):
    """Muestra una línea con los datos de una actividad"""
    short_slug = slug[:28]
    entries = slug_set[slug]
    first = entries[0]
    title = first.get("title", "")
    short_title = title[:46] if title else ""

    is_done = any(e.get("task_status") == "DONE" for e in entries)

    created = parse_dt(first.get("created_at"))
    start_str = created.strftime("%Y-%m-%d") if created else "—"

    updated_done = [parse_dt(e.get("updated_at")) for e in entries if e.get("task_status") == "DONE"]
    end = max(updated_done) if updated_done else None
    end_str = end.strftime("%Y-%m-%d") if end else "—"

    status_icon = "✅" if is_done else "⬜"
    global total_items, total_done
    total_items += 1
    if is_done:
        total_done += 1

    print(f"  | {short_slug:<28} | {short_title:<46} | {start_str:<10} | {end_str:<20} | {status_icon:<4} |")

# ── Función para mostrar un certificado completo ───────────────
def mostrar_certificado(cohort_slug, cohort_name_pretty):
    if cohort_slug not in cohort_tasks:
        return

    slug_set = cohort_tasks[cohort_slug]
    all_slugs = sorted(slug_set.keys(),
        key=lambda s: slug_set[s][0].get("created_at", "") if slug_set[s] else "")

    if not all_slugs:
        return

    print(f"\n{'='*100}")
    print(f"  {cohort_name_pretty}")
    print(f"{'='*100}")
    print(f"  +{'─'*28}+{'─'*46}+{'─'*10}+{'─'*20}+{'─'*6}+")
    print(f"  | {'ACTIVIDAD':<28} | {'TITULO':<46} | {'INICIO':<10} | {'CULMINACION':<20} | {'EST':<4} |")
    print(f"  +{'─'*28}+{'─'*46}+{'─'*10}+{'─'*20}+{'─'*6}+")

    for slug in all_slugs:
        mostrar_actividad(slug, slug_set)

    print(f"  +{'─'*28}+{'─'*46}+{'─'*10}+{'─'*20}+{'─'*6}+")

# ── Mostrar certificados en orden ──────────────────────────────
for cs, cname in CERTIFICADOS.items():
    mostrar_certificado(cs, cname)

# Cohort general: actividades sin certificado específico
if "latam-aie-pt-1" in cohort_tasks:
    specific_slugs = set()
    for cs in CERTIFICADOS:
        if cs in cohort_tasks:
            specific_slugs.update(cohort_tasks[cs].keys())

    general_slugs = cohort_tasks["latam-aie-pt-1"]
    solo_slugs = {k: v for k, v in general_slugs.items() if k not in specific_slugs}

    cohort_tasks["latam-aie-pt-1_extra"] = solo_slugs

    if solo_slugs:
        print(f"\n{'='*100}")
        print(f"  * OTRAS ACTIVIDADES (no asignadas a certificados específicos)")
        print(f"{'='*100}")
        print(f"  +{'─'*28}+{'─'*46}+{'─'*10}+{'─'*20}+{'─'*6}+")
        print(f"  | {'ACTIVIDAD':<28} | {'TITULO':<46} | {'INICIO':<10} | {'CULMINACION':<20} | {'EST':<4} |")
        print(f"  +{'─'*28}+{'─'*46}+{'─'*10}+{'─'*20}+{'─'*6}+")

        for slug in sorted(solo_slugs.keys()):
            mostrar_actividad(slug, solo_slugs)

        print(f"  +{'─'*28}+{'─'*46}+{'─'*10}+{'─'*20}+{'─'*6}+")

# ── Resumen final ─────────────────────────────────────────────
print(f"\n{'='*100}")
print(f"  RESUMEN GLOBAL: {total_items} actividades | {total_done} completadas ✅ | {total_items - total_done} pendientes ⬜")
print(f"{'='*100}")
print()

# ── Estadísticas por certificado ──────────────────────────────
print("  RESUMEN POR CERTIFICADO:")
print(f"  +{'─'*48}+{'─'*10}+{'─'*14}+{'─'*14}+{'─'*10}+")
print(f"  | {'CERTIFICADO':<48} | {'TOTAL':<10} | {'COMPLETADAS':<14} | {'PENDIENTES':<14} | {'AVANCE':<10} |")
print(f"  +{'─'*48}+{'─'*10}+{'─'*14}+{'─'*14}+{'─'*10}+")

for cs, cname in CERTIFICADOS.items():
    if cs not in cohort_tasks:
        continue
    slugs = cohort_tasks[cs]
    total = len(slugs)
    done = sum(1 for slug, entries in slugs.items()
               if any(e.get("task_status") == "DONE" for e in entries))
    pct = f"{done*100//total}%" if total > 0 else "—"
    print(f"  | {cname:<48} | {total:<10} | {done:<14} | {total-done:<14} | {pct:<10} |")

if "latam-aie-pt-1_extra" in cohort_tasks:
    slugs = cohort_tasks["latam-aie-pt-1_extra"]
    total = len(slugs)
    done = sum(1 for slug, entries in slugs.items()
               if any(e.get("task_status") == "DONE" for e in entries))
    pct = f"{done*100//total}%" if total > 0 else "—"
    print(f"  | {'Otras (sin certificado)':<48} | {total:<10} | {done:<14} | {total-done:<14} | {pct:<10} |")

print(f"  +{'─'*48}+{'─'*10}+{'─'*14}+{'─'*14}+{'─'*10}+")
print()