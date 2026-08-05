#!/usr/bin/env python3
"""
Script de Actividad por Módulo (Certificado)
=============================================
Agrupa todas las tareas por cohort (certificado) usando el campo 'cohort'
que viene directamente de la API.

- Se deduplican tareas repetidas por associated_slug, priorizando:
  1. Status DONE sobre PENDING
  2. Cohort específico sobre el cohort genérico 'latam-aie-pt-1'
- El cohort genérico 'latam-aie-pt-1' NO se muestra como certificado.
  Las actividades que SOLO existen en él se muestran al final agrupadas
  por módulo estimado.
- Dentro de cada certificado se listan todas las actividades individuales.
"""

import json
import subprocess
import sys
from datetime import datetime
from collections import defaultdict

# ─── Configuración ────────────────────────────────────────────────────────────

API_URL = "https://breathecode.herokuapp.com/v1/assignment/user/me/task"
TOKEN_FILE = "/root/.openclaw/workspace/.env"

# Cohort genérico que NO debe mostrarse como certificado independiente
COHORTE_GENERICO = "latam-aie-pt-1"

# Orden personalizado para mostrar los certificados
ORDEN_CERTIFICADOS = [
    "web-ui-fundamentals-with-tailwind-css",
    "command-line-git-github",
    "coding-fundamentals-with-typescript",
    "latam-frontend-development-with-coding-agents",
    "personal-assitant-with-openclaw",
    "working-with-ai-coding-agents",
    "advanced-personal-assitant-with-openclaw",
    "latam-coding-fundamentals-with-python",
    "backend-development-with-coding-agents",
    "authentication-web-applications",
    "error-handling-debugging-testing",
    "latam-ai-engineering-introduction",
]

NOMBRES_CERTIFICADOS = {
    "web-ui-fundamentals-with-tailwind-css": "01 — Web UI Fundamentals with Tailwind CSS",
    "command-line-git-github": "02 — Command line - Git & Github",
    "coding-fundamentals-with-typescript": "03 — Coding fundamentals with Typescript",
    "latam-frontend-development-with-coding-agents": "04 — Frontend development with Coding Agents",
    "personal-assitant-with-openclaw": "05 — Personal assistants with Openclaw",
    "working-with-ai-coding-agents": "06 — Working with AI coding agents",
    "advanced-personal-assitant-with-openclaw": "07 — Advanced personal assistants with Openclaw",
    "latam-coding-fundamentals-with-python": "08 — Coding Fundamentals with Python",
    "backend-development-with-coding-agents": "09 — Backend development with Coding Agents",
    "authentication-web-applications": "10 — Authentication in web applications",
    "error-handling-debugging-testing": "11 — Error handling, debugging and testing",
    "latam-ai-engineering-introduction": "00 — AI Engineering Introduction",
}

# ─── Clasificador para actividades sin certificado ───────────────────────────

def inferir_modulo(slug, titulo=""):
    """
    Intenta adivinar a qué módulo pertenece un slug que solo está
    en el cohort genérico. Usa palabras clave en slug y título.
    """
    s = (slug + " " + titulo).lower()

    if "openclaw" in s:
        return "AI Engineering / OpenClaw"
    if "python" in s or "numpy" in s or "pandas" in s:
        return "Python"
    if "react" in s or "nextjs" in s or "context-api" in s:
        return "Frontend / React"
    if "api" in s or "rest" in s or "fastapi" in s:
        return "Backend / APIs"
    if "tailwind" in s or "css" in s or "html" in s or "web" in s or "seo" in s or "responsive" in s or "form" in s:
        return "Web UI / Tailwind"
    if "git" in s or "github" in s or "command" in s or "terminal" in s or "vps" in s or "ssh" in s:
        return "Command Line / Git"
    if "typescript" in s or "javascript" in s or "coding" in s or "program" in s or "function" in s or "array" in s or "object" in s or "class" in s or "data" in s:
        return "Coding Fundamentals"
    if "test" in s or "debug" in s or "error" in s:
        return "Error Handling / Testing"
    if "auth" in s or "session" in s or "token" in s or "login" in s or "password" in s:
        return "Authentication"
    if "agent" in s or "ai" in s:
        return "AI / Coding Agents"

    return "Otros"

# ─── Obtener token ────────────────────────────────────────────────────────────

def obtener_token():
    """Lee el token del archivo .env de forma segura."""
    try:
        with open(TOKEN_FILE) as f:
            for line in f:
                line = line.strip()
                if line.startswith("4GEEKS_ACCESS_TOKEN"):
                    token = line.split("=", 1)[1].strip().strip("'\"").strip()
                    return token
    except FileNotFoundError:
        print(f"ERROR: No se encuentra {TOKEN_FILE}")
        sys.exit(1)
    print("ERROR: No se encontró 4GEEKS_ACCESS_TOKEN en .env")
    sys.exit(1)

# ─── Consultar API ────────────────────────────────────────────────────────────

def consultar_api():
    """Obtiene todas las tareas desde la API."""
    token = obtener_token()
    cmd = ["curl", "-s", "-H", f"Authorization: Token {token}", API_URL, "--max-time", "30"]
    r = subprocess.run(cmd, capture_output=True, text=True)
    if r.returncode != 0:
        print(f"ERROR: curl falló con código {r.returncode}")
        sys.exit(1)
    try:
        return json.loads(r.stdout)
    except json.JSONDecodeError:
        print(f"ERROR: No se pudo parsear la respuesta JSON")
        print(f"Respuesta cruda (primeros 500 chars): {r.stdout[:500]}")
        sys.exit(1)

# ─── Formateo ─────────────────────────────────────────────────────────────────

def formatear_fecha(iso_str):
    """Convierte ISO a YYYY-MM-DD o devuelve '—' si es None/vacío."""
    if not iso_str or not isinstance(iso_str, str) or len(iso_str) < 10:
        return "—"
    return iso_str[:10]  # Solo la fecha, sin hora

def resumir_slug(slug, max_len=30):
    """Trunca un slug para que entre en la tabla."""
    if len(slug) <= max_len:
        return slug.ljust(max_len)
    return slug[:max_len] + "…"

def resumir_titulo(titulo, max_len=48):
    """Trunca un título para que entre en la tabla."""
    if len(titulo) <= max_len:
        return titulo.ljust(max_len)
    return titulo[:max_len-1] + "…"

# ─── Mostrar tabla de actividades ─────────────────────────────────────────────

def mostrar_tabla_actividades(tareas, nombre_cohort):
    """Muestra una tabla con todas las actividades de un cohort."""
    if not tareas:
        return 0, 0

    tareas.sort(key=lambda t: t.get("created_at", ""))

    # Contar por tipo
    tipos = defaultdict(int)
    hechas = 0
    for t in tareas:
        tp = t.get("task_type", "UNKNOWN")
        tipos[tp] += 1
        if t.get("task_status") == "DONE":
            hechas += 1

    total = len(tareas)
    pendientes = total - hechas
    tipos_str = ", ".join(f"{v} {k.lower()}" for k, v in sorted(tipos.items()))

    print("=" * 110)
    print(f"  {nombre_cohort}  ({tipos_str})")
    print("=" * 110)
    print(f"  +{'─'*32}+{'─'*50}+{'─'*10}+{'─'*12}+{'─'*6}+")
    print(f"  | {'ACTIVIDAD':<30} | {'TITULO':<48} | {'INICIO':<8} | {'CULMINACION':<10} | {'EST':<4} |")
    print(f"  +{'─'*32}+{'─'*50}+{'─'*10}+{'─'*12}+{'─'*6}+")

    for t in tareas:
        slug = t.get("associated_slug", "")
        titulo = t.get("title", "")
        inicio = formatear_fecha(t.get("created_at"))
        culminacion = formatear_fecha(t.get("delivered_at") or t.get("updated_at"))
        status = t.get("task_status", "PENDING")
        est_simbolo = "✅" if status == "DONE" else "⬜"

        print(f"  | {resumir_slug(slug):<32} | {resumir_titulo(titulo):<50} | {inicio:<8} | {culminacion:<10} | {est_simbolo:<4} |")

    print(f"  +{'─'*32}+{'─'*50}+{'─'*10}+{'─'*12}+{'─'*6}+")

    pct = hechas * 100 // total if total else 0
    print(f"  → {hechas}/{total} completadas ({pct}%)")
    if pendientes > 0:
        pend_slugs = [t.get("associated_slug", "") for t in tareas if t.get("task_status") != "DONE"]
        print(f"    Pendientes ({pendientes}): {', '.join(pend_slugs[:5])}{'...' if len(pend_slugs) > 5 else ''}")
    print()

    return hechas, total

# ─── Main ─────────────────────────────────────────────────────────────────────

def main():
    print("Consultando actividades en la plataforma...\n")

    tasks = consultar_api()

    if not tasks:
        print("No se encontraron actividades.")
        return

    # ---- PASO 1: Agrupar por slug y por cohort ----
    # Primero, mapeamos cada slug a la lista de cohorts en los que aparece
    slug_cohorts = defaultdict(set)  # slug -> conjuntos de cohort_slug
    slug_tasks = {}  # slug -> mejor tarea (priorizando DONE)
    slug_tasks_por_cohort = defaultdict(lambda: {})  # (slug,cohort) -> tarea

    for t in tasks:
        slug = t.get("associated_slug", "")
        if not slug:
            continue

        cohort_obj = t.get("cohort")
        cohort_slug = ""
        if isinstance(cohort_obj, dict):
            cohort_slug = cohort_obj.get("slug", "")

        slug_cohorts[slug].add(cohort_slug)
        key = (slug, cohort_slug)
        # Guardar la mejor versión de cada slug en cada cohort
        if key not in slug_tasks_por_cohort:
            slug_tasks_por_cohort[key] = t
        else:
            existente = slug_tasks_por_cohort[key]
            # Preferir DONE sobre PENDING
            if t.get("task_status") == "DONE" and existente.get("task_status") != "DONE":
                slug_tasks_por_cohort[key] = t

    # ---- PASO 2: Separar slugs que SOLO están en latam-aie-pt-1 ----
    slugs_solo_generico = set()
    slugs_con_especifico = set()

    for slug, cohorts in slug_cohorts.items():
        tiene_especifico = any(c != COHORTE_GENERICO and c != "" for c in cohorts)
        if tiene_especifico:
            slugs_con_especifico.add(slug)
        else:
            slugs_solo_generico.add(slug)

    # ---- PASO 3: Asignar cada slug a su mejor cohort ----
    # Para slugs con certificado específico, tomar el mejor cohort (priorizar orden)
    slug_cohort_asignado = {}  # slug -> cohort_slug
    for slug in slugs_con_especifico:
        cohorts = slug_cohorts[slug]
        # Elegir el cohort más específico (excluyendo genérico y vacío)
        candidatos = [c for c in cohorts if c != COHORTE_GENERICO and c != ""]
        if candidatos:
            # Priorizar el que aparece primero en ORDEN_CERTIFICADOS
            for orden in ORDEN_CERTIFICADOS:
                if orden in candidatos:
                    slug_cohort_asignado[slug] = orden
                    break
            else:
                # Si no está en el orden, tomar cualquiera
                slug_cohort_asignado[slug] = candidatos[0]

    # ---- PASO 4: Agrupar por cohort ----
    cohortes = defaultdict(list)
    for slug, cohort_slug in slug_cohort_asignado.items():
        key = (slug, cohort_slug)
        if key in slug_tasks_por_cohort:
            cohortes[cohort_slug].append(slug_tasks_por_cohort[key])

    # ---- PASO 5: Agrupar actividades "solo genéricas" por módulo inferido ----
    otras_actividades = []
    for slug in slugs_solo_generico:
        # Tomar la tarea del cohort genérico
        key = (slug, COHORTE_GENERICO)
        if key in slug_tasks_por_cohort:
            t = slug_tasks_por_cohort[key]
            modulo = inferir_modulo(t.get("associated_slug", ""), t.get("title", ""))
            otras_actividades.append((modulo, t))

    # ---- PASO 6: Mostrar certificados ----
    total_global = 0
    hechas_global = 0

    for cohort_slug in ORDEN_CERTIFICADOS:
        if cohort_slug not in cohortes:
            continue
        tareas = cohortes[cohort_slug]
        nombre = NOMBRES_CERTIFICADOS.get(cohort_slug, cohort_slug)
        h, t = mostrar_tabla_actividades(tareas, nombre)
        hechas_global += h
        total_global += t

    # ---- PASO 7: Mostrar actividades sin certificado ----
    if otras_actividades:
        # Agrupar por módulo inferido
        otras_por_modulo = defaultdict(list)
        for modulo, tarea in otras_actividades:
            otras_por_modulo[modulo].append(tarea)

        print("=" * 110)
        print(f"  📋 OTRAS ACTIVIDADES (sin certificado específico)")
        print("=" * 110)
        print(f"  Son actividades asignadas al curso general que aún no están")
        print(f"  vinculadas a un certificado específico. Clasificación estimada:\n")

        # Mostrar por módulo estimado
        for modulo in sorted(otras_por_modulo.keys()):
            tareas = otras_por_modulo[modulo]
            tareas.sort(key=lambda t: t.get("created_at", ""))
            h_mod, t_mod = 0, len(tareas)
            for ta in tareas:
                if ta.get("task_status") == "DONE":
                    h_mod += 1

            print(f"  [{modulo}] — {h_mod}/{t_mod} completadas")
            for ta in tareas:
                slug = ta.get("associated_slug", "")
                titulo = ta.get("title", "")
                status = ta.get("task_status", "PENDING")
                est = "✅" if status == "DONE" else "⬜"
                print(f"    {est} {slug[:50]}: {titulo[:60]}")
            print()

            for ta in tareas:
                hechas_global += 1 if ta.get("task_status") == "DONE" else 0
                total_global += 0  # ya se contó en t_mod
            hechas_global += h_mod - sum(1 for ta in tareas if ta.get("task_status") == "DONE")
            # Fix: count correctly
        # Recalcular correctamente
        hechas_global_real = 0
        total_global_real = 0
        for cohort_slug in ORDEN_CERTIFICADOS:
            if cohort_slug not in cohortes:
                continue
            tareas = cohortes[cohort_slug]
            for ta in tareas:
                total_global_real += 1
                if ta.get("task_status") == "DONE":
                    hechas_global_real += 1
        for modulo, tareas in otras_por_modulo.items():
            for ta in tareas:
                total_global_real += 1
                if ta.get("task_status") == "DONE":
                    hechas_global_real += 1

        print("=" * 110)
        print(f"  RESUMEN GLOBAL: {total_global_real} actividades | {hechas_global_real} completadas ✅ | {total_global_real - hechas_global_real} pendientes ⬜")
        print("=" * 110)

        # Tabla resumen por certificado
        print(f"\n  {'RESUMEN POR CERTIFICADO':^{90}}")
        print(f"  +{'─'*60}+{'─'*8}+{'─'*12}+{'─'*11}+{'─'*8}+")
        print(f"  | {'CERTIFICADO':<58} | {'TOTAL':<6} | {'COMPLETADAS':<10} | {'PENDIENTES':<9} | {'AVANCE':<6} |")
        print(f"  +{'─'*60}+{'─'*8}+{'─'*12}+{'─'*11}+{'─'*8}+")

        for cohort_slug in ORDEN_CERTIFICADOS:
            if cohort_slug not in cohortes:
                continue
            tareas = cohortes[cohort_slug]
            nombre = NOMBRES_CERTIFICADOS.get(cohort_slug, cohort_slug)
            total = len(tareas)
            hechas = sum(1 for t in tareas if t.get("task_status") == "DONE")
            pend = total - hechas
            pct = hechas * 100 // total if total else 0
            nombre_corto = nombre if len(nombre) <= 58 else nombre[:55] + "..."
            print(f"  | {nombre_corto:<58} | {total:<6} | {hechas:<10} | {pend:<9} | {pct:>3}%{'':>3} |")

        # Fila de "Otras actividades"
        otras_total = sum(len(v) for v in otras_por_modulo.values())
        otras_hechas = sum(sum(1 for ta in v if ta.get("task_status") == "DONE") for v in otras_por_modulo.values())
        otras_pend = otras_total - otras_hechas
        otras_pct = otras_hechas * 100 // otras_total if otras_total else 0
        print(f"  | {'(Otras — sin certificado)':<58} | {otras_total:<6} | {otras_hechas:<10} | {otras_pend:<9} | {otras_pct:>3}%{'':>3} |")

        print(f"  +{'─'*60}+{'─'*8}+{'─'*12}+{'─'*11}+{'─'*8}+")
        print(f"  | {'TOTAL':<58} | {total_global_real:<6} | {hechas_global_real:<10} | {total_global_real - hechas_global_real:<9} | {hechas_global_real * 100 // total_global_real if total_global_real else 0:>3}%{'':>3} |")
        print(f"  +{'─'*60}+{'─'*8}+{'─'*12}+{'─'*11}+{'─'*8}+")

    else:
        # Sin "otras", mostrar resumen simple
        pct_global = hechas_global * 100 // total_global if total_global else 0
        print("=" * 110)
        print(f"  RESUMEN GLOBAL: {total_global} actividades | {hechas_global} completadas ✅ | {total_global - hechas_global} pendientes ⬜")
        print("=" * 110)

        print(f"\n  {'RESUMEN POR CERTIFICADO':^{90}}")
        print(f"  +{'─'*60}+{'─'*8}+{'─'*12}+{'─'*11}+{'─'*8}+")
        print(f"  | {'CERTIFICADO':<58} | {'TOTAL':<6} | {'COMPLETADAS':<10} | {'PENDIENTES':<9} | {'AVANCE':<6} |")
        print(f"  +{'─'*60}+{'─'*8}+{'─'*12}+{'─'*11}+{'─'*8}+")

        for cohort_slug in ORDEN_CERTIFICADOS:
            if cohort_slug not in cohortes:
                continue
            tareas = cohortes[cohort_slug]
            nombre = NOMBRES_CERTIFICADOS.get(cohort_slug, cohort_slug)
            total = len(tareas)
            hechas = sum(1 for t in tareas if t.get("task_status") == "DONE")
            pend = total - hechas
            pct = hechas * 100 // total if total else 0
            nombre_corto = nombre if len(nombre) <= 58 else nombre[:55] + "..."
            print(f"  | {nombre_corto:<58} | {total:<6} | {hechas:<10} | {pend:<9} | {pct:>3}%{'':>3} |")

        print(f"  +{'─'*60}+{'─'*8}+{'─'*12}+{'─'*11}+{'─'*8}+")
        print(f"  | {'TOTAL':<58} | {total_global:<6} | {hechas_global:<10} | {total_global - hechas_global:<9} | {pct_global:>3}%{'':>3} |")
        print(f"  +{'─'*60}+{'─'*8}+{'─'*12}+{'─'*11}+{'─'*8}+")


if __name__ == "__main__":
    main()