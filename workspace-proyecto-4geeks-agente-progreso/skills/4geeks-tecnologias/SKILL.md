# 4geeks-tecnologias

## Propósito

Generar un reporte completo de **todas las tecnologías aprendidas** en el programa AI Engineering de 4Geeks Academy. Analiza las actividades completadas (`DONE`) de la API y las clasifica automáticamente en categorías tecnológicas (HTML, CSS, Tailwind, JavaScript, TypeScript, React, Next.js, Python, FastAPI, Git, GitHub, VPS/SSH, OpenClaw, IA/Coding Agents, etc.).

**Solo incluye actividades completadas.** Las pendientes no cuentan como "aprendidas".

## Requisitos

- Token de acceso a la API de 4Geeks Academy (en `/root/.openclaw/workspace/.env` como `4GEEKS_ACCESS_TOKEN`)
- Python 3
- `curl`

## Ubicación del script

```
/root/.openclaw/workspace/skills/4geeks-tecnologias/scripts/get_tecnologias.py
```

## Cómo ejecutar

```bash
cd /root/.openclaw/workspace/skills/4geeks-tecnologias/scripts && python3 get_tecnologias.py
```

Para guardar el resultado:

```bash
cd /root/.openclaw/workspace/skills/4geeks-tecnologias/scripts && python3 get_tecnologias.py | tee /root/.openclaw/workspace/archivos_resultados/$(date +%y-%m-%d)-resultado-skill-tecnologias.md
```

## Procedimiento detallado (reglas)

### 1. Obtener el token

El token se lee de la variable `4GEEKS_ACCESS_TOKEN` en `/root/.openclaw/workspace/.env`.
**Nunca hardcodeado en el script.** Se extrae con:

```python
with open(TOKEN_FILE) as f:
    for line in f:
        if line.startswith("4GEEKS_ACCESS_TOKEN"):
            token = line.split("=", 1)[1].strip().strip("'\"").strip()
```

### 2. Consultar la API

**Endpoint:** `https://breathecode.herokuapp.com/v1/assignment/user/me/task`
**Header:** `Authorization: Token <token>` (formato Token, NO Bearer)
**Timeout:** 30 segundos

### 3. Deduplicación

Se construye un diccionario `slug → tarea`, priorizando `DONE` sobre `PENDING` cuando hay duplicados del mismo slug (porque el usuario puede estar en múltiples cohorts).

### 4. Clasificación tecnológica

Cada actividad completada se evalúa contra **48 categorías de tecnología** en orden específico. Una actividad se asigna a la **PRIMERA** categoría que coincida.

**Reglas de clasificación:**
- Usar slugs completos cuando sea posible (evita falsos positivos)
- Poner casos específicos ANTES que genéricos
- Cada actividad va a UNA sola tecnología
- Si no hay match, se reporta como "sin clasificar" para depuración

**Categorías cubiertas:**

| # | Tecnología | Detecta en slug |
|---|---|---|
| 1 | Metodología 4Geeks | `4geeks-method`, `introduction-to-4geeks`, `how-to-submit-your` |
| 2 | Fundamentos de Internet | `how-the-internet`, `what-is-the-internet` |
| 3 | Fundamentos de Programación | `what-is-coding`, `introduction-to-programming`, `programming-fundamentals`, `programming-flow`, `conditionals-in-programing-coding` |
| 4 | HTML | `html-fundamentals`, `html-exercises`, `html-css-artist`, `what-is-html`, `postcard`, `debugging-html-code` |
| 5 | CSS | `css-mastery`, `css-exercises`, `css-fundamentals`, `what-is-css`, `debugging-css-code` (excluye `tailwind`) |
| 6 | Tailwind CSS | `tailwind`, `first-collaborative` |
| 7 | Diseño Web / Layout | `mastering-web-layout`, `web-component-recognition`, `responsive-web-design` |
| 8 | Formularios Web | `building-professional-web-forms`, `building-effective-forms`, `dynamic-forms` |
| 9 | SEO / GEO | `seo`, `geo` |
| 10 | Accesibilidad Web | `accessibility` |
| 11 | JavaScript | `what-is-javascript`, `javascript-beginner`, `javascript-functions`, `javascript-array-loops`, `dom-manipulation`, `the-dom-exercises`, `excuses-generator` |
| 12 | TypeScript | `typescript`, `javascript-and-typescript`, `master-typescript`, `mastering-arrays-in-typescript`, `mastering-control-flow-in-typ`, `data-types-and-basic-operators-in-typescript`, `object-representation-in-typescript`, `understanding-mutability-in-typescript`, `typescript-cinema` |
| 13 | Funciones JS/TS | `functions-in-javascript`, `working-with-functions` (excluye `python`) |
| 14 | Objetos y Estructuras de Datos | `understanding-objects-models`, `what-is-an-array`, `array-define` |
| 15 | Modelado con Diagramas de Clases | `object-modeling-through-class-diagrams`, `data-modeling-and-class-diagrams`, `music-playlist-player-modeling` |
| 16 | Promesas / Async | `promise` |
| 17 | React | `introduction-to-react`, `react-next-js`, `context-api`, `data-flow-in-react` |
| 18 | Next.js | `nextjs-`, `next-js-fundamentals` |
| 19 | SPA / Bundling | `spa-architecture`, `organizing-my-frontend` |
| 20 | Línea de Comandos | `command-line-fundamentals`, `file-system-hierarchy`, `exercise-terminal` |
| 21 | Git | `git-for-developers`, `git-version` |
| 22 | GitHub | `github-for`, `first-collaborative` |
| 23 | Python (Sintaxis Básica) | `learning-to-code-with-python`, `conditionals-in-programing-python`, `what-is-a-python-list`, `what-are-python-dictionaries`, `working-with-functions-python`, `python-beginner-exercises` |
| 24 | Python (Buenas Prácticas) | `sorting-and-search`, `python-best-practices`, `learn-python-best`, `python-function-exercises`, `python-loops-lists` |
| 25 | Python CLI | `todo-list-cli-python` |
| 26 | Arquitectura Backend | `common-backend-architectures`, `separation-by-domains-and-responsibilities`, `ai-eng-architectural-proposal`, `storing-information` |
| 27 | FastAPI | `fastapi` |
| 28 | Pydantic / Validación | `validating-and-serializing`, `pydant` |
| 29 | Documentación de APIs | `api-documentation` |
| 30 | Manejo de Archivos (Python) | `working-with-files-in-python` |
| 31 | Entornos Virtuales Python | `virtual-environment` |
| 32 | Consumo de APIs (Frontend) | `getting-data-from-apis`, `chat-interface-real-ai` |
| 33 | Construcción de APIs (Python) | `building-a-python-api-to-serve`, `voice-to-do-list` |
| 34 | Autenticación Web | `authentication-fundamentals`, `secure-passwords`, `sessions-in-web` |
| 35 | VPS | `vps` |
| 36 | SSH | `ssh` (excluye `vps`) |
| 37 | IA Generativa (Fundamentos) | `introduction-to-generative-ai`, `ai-engineering-fundamentals` |
| 38 | Prompt Engineering | `prompting-engineering`, `ai-communication-strategies`, `token-efficiency-with-coding-agents` |
| 39 | Coding Agents | `using-coding-agents`, `ai-coding-rules-and-context`, `ai-context-engineering`, `agent-skills-teaching`, `agent-skill-creation`, `speaking-ais-language` |
| 40 | Spec-Driven Development | `spec-driven-development`, `company-financial-dashboard-specs` |
| 41 | AI Agents en Python | `introduction-to-ai-agents`, `building-a-basic-ai-agent-in-python` |
| 42 | Proyectos Integradores (Milestones) | `ai-eng-milestone`, `ai-eng-ai-driven`, `ai-eng-company-incidents`, `agent-hub-ui-specs`, `company-financial-dashboard-context`, `company-financial-dashboard-skills` |
| 43 | OpenClaw (Fundamentos) | `introduction-to-openclaw`, `setting-up-your-personal-ai-assistant`, `openclaw-setup`, `assigning-simple-tasks-to-openclaw` |
| 44 | OpenClaw (Seguridad) | `security-risks`, `managing-secrets` |
| 45 | OpenClaw (Integraciones) | `connecting-composio`, `connecting-openclaw-with-telegram`, `openclaw-connection` |
| 46 | OpenClaw (Avanzado) | `openclaw-advanced`, `teaching-openclaw-new-skills`, `openclaw-skills`, `how-to-make-your-agent-interact` |
| 47 | Debugging | `debugging-evidence` |
| 48 | Desarrollo Frontend Iterativo con IA | `the-constructive-process`, `visual-to-spec` |

### 5. Output

El reporte incluye:

1. **Encabezado** con totales de actividades completadas vs pendientes
2. **Sección por tecnología** con:
   - Icono, nombre y descripción de la tecnología
   - Número de actividades completadas
   - Lista de actividades (slug) con icono de tipo (📝 exercise, 📖 lesson, 🏗️ project)
3. **Lista compacta** de todas las tecnologías aprendidas con conteos
4. **Resumen de habilidades** al final

### 6. Archivo de resultados

Se guarda en `archivos_resultados/YY-MM-DD-resultado-skill-tecnologias.md`

## Mantenimiento

El script es automático. Cuando se completen nuevas actividades, aparecerán automáticamente en su categoría tecnológica al ejecutar el script.

**Si aparecen actividades "sin clasificar",** hay que:
1. Revisar el slug de la actividad
2. Añadir una nueva entrada en `TECNOLOGIAS` con el detector adecuado
3. O extender el detector de una categoría existente

## Archivos relacionados

- Script principal: `get_tecnologias.py`
- Outputs históricos: `archivos_resultados/*-resultado-skill-tecnologias.md`