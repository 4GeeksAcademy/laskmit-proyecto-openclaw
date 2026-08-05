#!/usr/bin/env python3
"""
Script: get_tecnologias.py
Propósito: Genera un reporte de TODAS las tecnologías aprendidas
           por el alumno en 4Geeks Academy, basado en las actividades
           completadas (DONE) de la API.
Regla de oro: Solo incluir actividades con task_status == "DONE".
              NO incluir pendientes (no se ha aprendido aún).
"""

import json
import os
import sys
import urllib.request
import urllib.error
from datetime import datetime

# ─── Configuración ─────────────────────────────────────────────────

API_URL = "https://breathecode.herokuapp.com/v1/assignment/user/me/task"
TOKEN_FILE = os.path.expanduser("/root/.openclaw/workspace/.env")
OUTPUT_DIR = os.path.expanduser("/root/.openclaw/workspace/archivos_resultados")

# ─── Categorización de tecnologías ─────────────────────────────────
# Las funciones detectoras se evalúan en orden.
# Cada tarea se asigna a la PRIMERA tecnología que detecte.
# Reglas: usar slugs completos cuando sea posible, poner casos
#         específicos ANTES que casos genéricos.

TECNOLOGIAS = [
    # ── 4GEEKS / METODOLOGÍA ──
    {
        "nombre": "Metodología 4Geeks",
        "icono": "🏫",
        "descripcion": "Método 4Geeks, plataforma, entregas de proyectos",
        "detectar": lambda s, t, tt: any(x in s for x in [
            "4geeks-method", "introduction-to-4geeks", "how-to-submit-your",
        ]),
    },
    # ── INTERNET ──
    {
        "nombre": "Fundamentos de Internet",
        "icono": "🌍",
        "descripcion": "Cómo funciona internet, protocolos, navegación",
        "detectar": lambda s, t, tt: any(x in s for x in [
            "how-the-internet", "what-is-the-internet",
        ]),
    },
    # ── PROGRAMACIÓN (fundamentos transversales) ──
    {
        "nombre": "Fundamentos de Programación",
        "icono": "💡",
        "descripcion": "Lógica, flujo de control, qué es programar/codificar",
        "detectar": lambda s, t, tt: any(x in s for x in [
            "what-is-coding", "introduction-to-programming",
            "programming-fundamentals", "programming-flow",
            "conditionals-in-programing-coding",
        ]),
    },
    # ── WEB UI ──
    {
        "nombre": "HTML",
        "icono": "🌐",
        "descripcion": "Estructura de páginas web, etiquetas semánticas, debugging HTML",
        "detectar": lambda s, t, tt: any(x in s for x in [
            "html-fundamentals", "html-exercises", "html-css-artist",
            "what-is-html", "html-fundamentals-for-beginners",
            "postcard", "debugging-html-code",
        ]),
    },
    {
        "nombre": "CSS",
        "icono": "🎨",
        "descripcion": "Estilos visuales, selectores, maquetación, debugging CSS",
        "detectar": lambda s, t, tt: any(x in s for x in [
            "css-mastery", "css-exercises", "css-fundamentals",
            "what-is-css", "debugging-css-code",
        ]) and "tailwind" not in s,
    },
    {
        "nombre": "Tailwind CSS",
        "icono": "💨",
        "descripcion": "Framework CSS utility-first, componentes con clases atómicas",
        "detectar": lambda s, t, tt: "tailwind" in s or "first-collaborative" in s,
    },
    {
        "nombre": "Diseño Web / Layout",
        "icono": "📐",
        "descripcion": "Maquetación web, layouts, componentes, responsive design",
        "detectar": lambda s, t, tt: any(x in s for x in [
            "mastering-web-layout", "web-component-recognition",
            "responsive-web-design",
        ]),
    },
    {
        "nombre": "Formularios Web",
        "icono": "📝",
        "descripcion": "Formularios HTML, validación, formularios dinámicos con JS",
        "detectar": lambda s, t, tt: any(x in s for x in [
            "building-professional-web-forms", "building-effective-forms",
            "dynamic-forms",
        ]),
    },
    {
        "nombre": "SEO / GEO",
        "icono": "🔍",
        "descripcion": "Optimización para buscadores, discoverabilidad web",
        "detectar": lambda s, t, tt: "seo" in s or "geo" in s,
    },
    {
        "nombre": "Accesibilidad Web",
        "icono": "♿",
        "descripcion": "Web Accessibility (a11y), estándares WCAG",
        "detectar": lambda s, t, tt: "accessibility" in s,
    },
    # ── JAVASCRIPT ──
    {
        "nombre": "JavaScript",
        "icono": "🟨",
        "descripcion": "Lenguaje del navegador, manipulación del DOM, ejercicios JS",
        "detectar": lambda s, t, tt: any(x in s for x in [
            "what-is-javascript", "javascript-beginner",
            "javascript-functions", "javascript-array-loops",
            "dom-manipulation", "the-dom-exercises",
            "excuses-generator",
        ]),
    },
    {
        "nombre": "TypeScript",
        "icono": "🔷",
        "descripcion": "Superset tipado de JavaScript, tipos, interfaces",
        "detectar": lambda s, t, tt: any(x in s for x in [
            "typescript", "javascript-and-typescript",
            "master-typescript", "mastering-arrays-in-typescript",
            "mastering-control-flow-in-typ",
            "data-types-and-basic-operators-in-typescript",
            "object-representation-in-typescript",
            "understanding-mutability-in-typescript",
            "typescript-cinema",
        ]),
    },
    {
        "nombre": "Funciones JS/TS",
        "icono": "⚡",
        "descripcion": "Funciones en JavaScript y TypeScript",
        "detectar": lambda s, t, tt: any(x in s for x in [
            "functions-in-javascript", "working-with-functions",
        ]) and "python" not in s,
    },
    {
        "nombre": "Objetos y Estructuras de Datos",
        "icono": "📊",
        "descripcion": "Objetos, arrays, mutabilidad, modelado de datos",
        "detectar": lambda s, t, tt: any(x in s for x in [
            "understanding-objects-models",
            "what-is-an-array", "array-define",
        ]),
    },
    {
        "nombre": "Modelado con Diagramas de Clases",
        "icono": "📐",
        "descripcion": "Diagramas de clases UML, modelado orientado a objetos",
        "detectar": lambda s, t, tt: any(x in s for x in [
            "object-modeling-through-class-diagrams",
            "data-modeling-and-class-diagrams",
            "music-playlist-player-modeling",
        ]),
    },
    {
        "nombre": "Promesas / Async",
        "icono": "⏳",
        "descripcion": "Promesas, async/await, operaciones asíncronas",
        "detectar": lambda s, t, tt: "promise" in s,
    },
    # ── FRONTEND FRAMEWORKS ──
    {
        "nombre": "React",
        "icono": "⚛️",
        "descripcion": "Biblioteca de componentes, JSX, estado global (Context API)",
        "detectar": lambda s, t, tt: any(x in s for x in [
            "introduction-to-react", "react-next-js",
            "context-api", "data-flow-in-react",
        ]),
    },
    {
        "nombre": "Next.js",
        "icono": "▲",
        "descripcion": "Framework React con SSR, routing, building de apps",
        "detectar": lambda s, t, tt: any(x in s for x in [
            "nextjs-", "next-js-fundamentals",
        ]),
    },
    {
        "nombre": "SPA / Bundling / Organización",
        "icono": "🏗️",
        "descripcion": "Single Page Applications, bundling, organización del frontend",
        "detectar": lambda s, t, tt: any(x in s for x in [
            "spa-architecture", "organizing-my-frontend",
        ]),
    },
    # ── GIT / LÍNEA DE COMANDOS ──
    {
        "nombre": "Línea de Comandos",
        "icono": "💻",
        "descripcion": "Terminal UNIX, sistema de archivos, shell, comandos básicos",
        "detectar": lambda s, t, tt: any(x in s for x in [
            "command-line-fundamentals", "file-system-hierarchy",
            "exercise-terminal",
        ]),
    },
    {
        "nombre": "Git",
        "icono": "📦",
        "descripcion": "Control de versiones, commits, repositorios locales",
        "detectar": lambda s, t, tt: "git-for-developers" in s or "git-version" in s,
    },
    {
        "nombre": "GitHub",
        "icono": "🐙",
        "descripcion": "Colaboración en equipo, pull requests, trabajo colaborativo",
        "detectar": lambda s, t, tt: any(x in s for x in [
            "github-for", "first-collaborative",
        ]),
    },
    # ── PYTHON ──
    {
        "nombre": "Python (Sintaxis Básica)",
        "icono": "🐍",
        "descripcion": "Sintaxis, variables, condicionales, listas, diccionarios, funciones",
        "detectar": lambda s, t, tt: any(x in s for x in [
            "learning-to-code-with-python", "conditionals-in-programing-python",
            "what-is-a-python-list", "what-are-python-dictionaries",
            "working-with-functions-python", "python-beginner-exercises",
        ]),
    },
    {
        "nombre": "Python (Buenas Prácticas y Algoritmos)",
        "icono": "🐍✨",
        "descripcion": "Módulos, buenas prácticas, algoritmos de ordenamiento/búsqueda",
        "detectar": lambda s, t, tt: any(x in s for x in [
            "sorting-and-search", "python-best-practices",
            "learn-python-best", "python-function-exercises",
            "python-loops-lists",
        ]),
    },
    {
        "nombre": "Python CLI",
        "icono": "📟",
        "descripcion": "Aplicaciones de línea de comandos en Python",
        "detectar": lambda s, t, tt: "todo-list-cli-python" in s,
    },
    # ── BACKEND ──
    {
        "nombre": "Arquitectura Backend",
        "icono": "🏛️",
        "descripcion": "Patrones de backend, separación por dominios, propuesta arquitectónica",
        "detectar": lambda s, t, tt: any(x in s for x in [
            "common-backend-architectures",
            "separation-by-domains-and-responsibilities",
            "ai-eng-architectural-proposal",
            "storing-information",
        ]),
    },
    {
        "nombre": "FastAPI",
        "icono": "🚀",
        "descripcion": "Framework web Python para construir APIs REST rápidas",
        "detectar": lambda s, t, tt: "fastapi" in s,
    },
    {
        "nombre": "Pydantic / Validación de Datos",
        "icono": "✅",
        "descripcion": "Validación y serialización de datos con Pydantic",
        "detectar": lambda s, t, tt: any(x in s for x in [
            "validating-and-serializing", "pydant",
        ]),
    },
    {
        "nombre": "Documentación de APIs",
        "icono": "📖",
        "descripcion": "Documentación automática de APIs REST (OpenAPI/Swagger)",
        "detectar": lambda s, t, tt: "api-documentation" in s,
    },
    {
        "nombre": "Manejo de Archivos (Python)",
        "icono": "📁",
        "descripcion": "Lectura y escritura de archivos en Python",
        "detectar": lambda s, t, tt: "working-with-files-in-python" in s,
    },
    {
        "nombre": "Entornos Virtuales Python",
        "icono": "🔮",
        "descripcion": "Virtual environments, pip, gestión de dependencias",
        "detectar": lambda s, t, tt: "virtual-environment" in s,
    },
    # ── APIs / CONSUMO ──
    {
        "nombre": "Consumo de APIs desde Frontend",
        "icono": "🔌",
        "descripcion": "Fetch, GET/POST desde JS, integración con APIs externas",
        "detectar": lambda s, t, tt: any(x in s for x in [
            "getting-data-from-apis", "chat-interface-real-ai",
        ]),
    },
    {
        "nombre": "Construcción de APIs en Python",
        "icono": "🔧",
        "descripcion": "Construir una API Python para servir al frontend",
        "detectar": lambda s, t, tt: any(x in s for x in [
            "building-a-python-api-to-serve",
            "voice-to-do-list",
        ]),
    },
    # ── AUTENTICACIÓN ──
    {
        "nombre": "Autenticación Web",
        "icono": "🔐",
        "descripcion": "Fundamentos de auth, JWT, sesiones, passwords seguros",
        "detectar": lambda s, t, tt: any(x in s for x in [
            "authentication-fundamentals", "secure-passwords",
            "sessions-in-web",
        ]),
    },
    # ── VPS / SSH ──
    {
        "nombre": "VPS",
        "icono": "🖥️",
        "descripcion": "Servidores virtuales privados, despliegue, gestión remota",
        "detectar": lambda s, t, tt: "vps" in s,
    },
    {
        "nombre": "SSH",
        "icono": "🔑",
        "descripcion": "Conexión segura remota por SSH",
        "detectar": lambda s, t, tt: "ssh" in s and "vps" not in s,
    },
    # ── AI / AGENTS ──
    {
        "nombre": "Fundamentos de IA Generativa",
        "icono": "🤖",
        "descripcion": "Introducción a IA, AI-assisted development",
        "detectar": lambda s, t, tt: any(x in s for x in [
            "introduction-to-generative-ai",
            "ai-engineering-fundamentals",
        ]),
    },
    {
        "nombre": "Prompt Engineering",
        "icono": "💬",
        "descripcion": "Ingeniería de prompts, comunicación efectiva con IA",
        "detectar": lambda s, t, tt: any(x in s for x in [
            "prompting-engineering",
            "ai-communication-strategies",
            "token-efficiency-with-coding-agents",
        ]),
    },
    {
        "nombre": "Coding Agents",
        "icono": "🧑‍💻🤖",
        "descripcion": "Uso de agentes de IA para programar, reglas, contexto, memoria",
        "detectar": lambda s, t, tt: any(x in s for x in [
            "using-coding-agents",
            "ai-coding-rules-and-context",
            "ai-context-engineering",
            "agent-skills-teaching",
            "agent-skill-creation",
            "speaking-ais-language",
        ]),
    },
    {
        "nombre": "Spec-Driven Development",
        "icono": "📋",
        "descripcion": "Desarrollo guiado por especificaciones con agentes de IA",
        "detectar": lambda s, t, tt: any(x in s for x in [
            "spec-driven-development",
            "company-financial-dashboard-specs",
        ]),
    },
    {
        "nombre": "AI Agents en Python",
        "icono": "🐍🤖",
        "descripcion": "Construcción de agentes de IA en Python",
        "detectar": lambda s, t, tt: any(x in s for x in [
            "introduction-to-ai-agents",
            "building-a-basic-ai-agent-in-python",
        ]),
    },
    {
        "nombre": "Proyectos Integradores (Milestones)",
        "icono": "🏆",
        "descripcion": "Proyectos milestone del programa AI Engineering",
        "detectar": lambda s, t, tt: any(x in s for x in [
            "ai-eng-milestone", "ai-eng-ai-driven",
            "ai-eng-company-incidents",
            "agent-hub-ui-specs", "company-financial-dashboard-context",
            "company-financial-dashboard-skills",
        ]),
    },
    # ── OPENCLAW ──
    {
        "nombre": "OpenClaw (Fundamentos)",
        "icono": "🦀",
        "descripcion": "Setup, configuración, tareas básicas con OpenClaw",
        "detectar": lambda s, t, tt: any(x in s for x in [
            "introduction-to-openclaw",
            "setting-up-your-personal-ai-assistant",
            "openclaw-setup",
            "assigning-simple-tasks-to-openclaw",
        ]),
    },
    {
        "nombre": "OpenClaw (Seguridad)",
        "icono": "🛡️",
        "descripcion": "Riesgos de seguridad, vulnerabilidades, manejo de secretos en OpenClaw",
        "detectar": lambda s, t, tt: any(x in s for x in [
            "security-risks", "managing-secrets",
        ]),
    },
    {
        "nombre": "OpenClaw (Integraciones)",
        "icono": "🔗",
        "descripcion": "Conexión con Telegram, Google Drive, Calendar, MCP, Zapier",
        "detectar": lambda s, t, tt: any(x in s for x in [
            "connecting-composio", "connecting-openclaw-with-telegram",
            "openclaw-connection",
        ]),
    },
    {
        "nombre": "OpenClaw (Avanzado)",
        "icono": "🦀⚡",
        "descripcion": "Skills personalizadas, memoria, interacción con sistemas",
        "detectar": lambda s, t, tt: any(x in s for x in [
            "openclaw-advanced", "teaching-openclaw-new-skills",
            "openclaw-skills", "how-to-make-your-agent-interact",
        ]),
    },
    # ── DEBUGGING ──
    {
        "nombre": "Debugging",
        "icono": "🐛",
        "descripcion": "Debugging de aplicaciones web, evidencia sobre suposición",
        "detectar": lambda s, t, tt: any(x in s for x in [
            "debugging-evidence",
        ]),
    },
    # ── FRONTEND AVANZADO ──
    {
        "nombre": "Desarrollo Frontend Iterativo con IA",
        "icono": "🔄",
        "descripcion": "Proceso constructivo iterativo, traducción de diseños a especificaciones",
        "detectar": lambda s, t, tt: any(x in s for x in [
            "the-constructive-process", "visual-to-spec",
        ]),
    },
]


def obtener_token():
    """Lee el token del archivo .env de forma segura."""
    if not os.path.exists(TOKEN_FILE):
        print("ERROR: No se encuentra el archivo .env en", TOKEN_FILE)
        sys.exit(1)
    with open(TOKEN_FILE) as f:
        for line in f:
            line = line.strip()
            if line.startswith("4GEEKS_ACCESS_TOKEN"):
                token = line.split("=", 1)[1].strip().strip("'\"").strip()
                return token
    print("ERROR: No se encontró 4GEEKS_ACCESS_TOKEN en", TOKEN_FILE)
    sys.exit(1)


def consultar_api(token):
    """Consulta la API y retorna lista de tareas."""
    req = urllib.request.Request(API_URL)
    req.add_header("Authorization", f"Token {token}")
    req.add_header("Content-Type", "application/json")
    try:
        with urllib.request.urlopen(req, timeout=30) as resp:
            return json.loads(resp.read().decode())
    except urllib.error.HTTPError as e:
        print(f"ERROR HTTP {e.code}: {e.reason}")
        sys.exit(1)
    except Exception as e:
        print(f"ERROR: {e}")
        sys.exit(1)


def deduplicar(data):
    """Construye dict slug → tarea, priorizando DONE sobre PENDING."""
    tasks = {}
    for t in data:
        slug = t.get("associated_slug", "")
        if not slug:
            continue
        if slug in tasks:
            old = tasks[slug]
            if t.get("task_status") == "DONE" and old.get("task_status") != "DONE":
                tasks[slug] = t
        else:
            tasks[slug] = t
    return tasks


def main():
    print("=" * 80)
    print("  📚 TECNOLOGÍAS APRENDIDAS EN 4GEEKS ACADEMY")
    print("  Solo se incluyen actividades COMPLETADAS (task_status = DONE)")
    print("=" * 80)
    print()

    # Obtener datos
    print("Consultando actividades en la plataforma...")
    token = obtener_token()
    data = consultar_api(token)
    tasks = deduplicar(data)
    print(f"  Total actividades únicas: {len(tasks)}")
    print()

    # Separar DONE vs PENDING
    done_tasks = {}
    pending_tasks = {}
    for slug, t in tasks.items():
        if t.get("task_status") == "DONE":
            done_tasks[slug] = t
        else:
            pending_tasks[slug] = t

    print(f"  ✅ Completadas (aprendidas): {len(done_tasks)}")
    print(f"  ⬜ Pendientes (por aprender): {len(pending_tasks)}")
    print()

    # Clasificar cada tarea DONE por tecnología
    tecnologia_tasks = {t["nombre"]: [] for t in TECNOLOGIAS}
    tecnologia_vistos = {t["nombre"]: set() for t in TECNOLOGIAS}
    no_clasificadas = []

    for slug, t in sorted(done_tasks.items()):
        title = t.get("title", "?")
        tt = t.get("task_type", "?")
        clasificada = False
        for tec in TECNOLOGIAS:
            if tec["detectar"](slug, title, tt):
                if slug not in tecnologia_vistos[tec["nombre"]]:
                    tecnologia_vistos[tec["nombre"]].add(slug)
                    tecnologia_tasks[tec["nombre"]].append((slug, title, tt))
                clasificada = True
                break  # Cada actividad va a UNA tecnología
        if not clasificada:
            no_clasificadas.append((slug, title, tt))

    # Mostrar tecnologías agrupadas
    total_tec_con_actividades = 0
    for i, tec in enumerate(TECNOLOGIAS, 1):
        items = tecnologia_tasks[tec["nombre"]]
        if not items:
            continue
        total_tec_con_actividades += 1
        print(f"  {tec['icono']}  {tec['nombre']}")
        print(f"      {tec['descripcion']}")
        print(f"      → {len(items)} actividad(es) completada(s)")
        # Listar las actividades con su tipo
        for slug, title, tt in items:
            icono_tt = {"EXERCISE": "📝", "LESSON": "📖", "PROJECT": "🏗️"}.get(tt, "📌")
            print(f"        {icono_tt} {slug}")
        print()

    # Mostrar no clasificadas (debug)
    if no_clasificadas:
        print(f"  ⚠️  {len(no_clasificadas)} actividad(es) sin clasificar — revisar:")
        for slug, title, tt in no_clasificadas:
            print(f"      · {slug}")
        print()

    # Resumen numérico
    print("=" * 80)
    print("  📊 RESUMEN")
    print("=" * 80)
    print()
    print(f"  Categorías de tecnología identificadas: {total_tec_con_actividades}")
    print(f"  Total actividades completadas analizadas: {len(done_tasks)}")
    print(f"  Actividades pendientes (no incluidas):   {len(pending_tasks)}")
    print()

    # Lista compacta de tecnologías aprendidas
    print("  🏷️  LISTA COMPACTA DE TECNOLOGÍAS APRENDIDAS:")
    print()
    for tec in TECNOLOGIAS:
        items = tecnologia_tasks[tec["nombre"]]
        if items:
            print(f"    {tec['icono']} {tec['nombre']} ({len(items)})")
    print()

    print("=" * 80)
    print("  🎯 Resumen de habilidades adquiridas:")
    print()
    print("      🌐 HTML / 🎨 CSS / 💨 Tailwind CSS / 📐 Responsive Design")
    print("      🟨 JavaScript / 🔷 TypeScript / ⚛️ React / ▲ Next.js")
    print("      🐍 Python (básico, avanzado, CLI) / 🚀 FastAPI")
    print("      💻 Terminal / 📦 Git / 🐙 GitHub / 🖥️ VPS / 🔑 SSH")
    print("      🏛️ Backend APIs / 🔌 Consumo APIs / 🔐 Autenticación")
    print("      🤖 AI Generativa / 💬 Prompt Engineering")
    print("      🧑‍💻🤖 Coding Agents / 📋 Spec-Driven Dev")
    print("      🦀 OpenClaw (básico, seguridad, integraciones, avanzado)")
    print("      🐛 Debugging / 🌍 Internet / 🏫 Metodología 4Geeks")
    print("=" * 80)


if __name__ == "__main__":
    import sys
    main()