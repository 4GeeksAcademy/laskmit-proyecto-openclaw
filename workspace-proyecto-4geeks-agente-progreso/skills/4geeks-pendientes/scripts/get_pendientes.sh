#!/usr/bin/env bash
#
# get_pendientes.sh — Obtener trabajo pendiente de 4Geeks Academy
#
# Endpoint: GET /v1/assignment/user/me/task
# Filtra por cohorte latam-aie-pt-1
# Muestra 3 tablas INDIVIDUALES con bordes:
#   - PROYECTOS: detalle proyecto por proyecto (MODULO | PROYECTO)
#   - LECCIONES: detalle leccion por leccion (MODULO | LECCION)
#   - EJERCICIOS: detalle ejercicio por ejercicio (MODULO | EJERCICIO)
#
# Uso: ./get_pendientes.sh
#
# Requiere: variable 4GEEKS_ACCESS_TOKEN en .env

set -euo pipefail

# ----- Colores -----
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

BASE_URL="https://breathecode.herokuapp.com"

# ----- Cargar token desde .env -----
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SKILL_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
WORKSPACE_DIR="$(cd "$SKILL_DIR/../.." && pwd)"
ENV_FILE="$WORKSPACE_DIR/.env"

if [ ! -f "$ENV_FILE" ]; then
    echo -e "${RED}ERROR: No se encuentra $ENV_FILE${NC}"
    exit 1
fi

TOKEN=$(grep '^4GEEKS_ACCESS_TOKEN' "$ENV_FILE" | cut -d= -f2- | tr -d "'\" \t\r\n") || true

if [ -z "$TOKEN" ]; then
    echo -e "${RED}ERROR: 4GEEKS_ACCESS_TOKEN no encontrado en .env${NC}"
    exit 1
fi

echo -e "${CYAN}${BOLD}Consultando trabajo pendiente en 4Geeks Academy...${NC}"
echo ""

# ----- Obtener cohort_id de latam-aie-pt-1 -----
USERFILE=$(mktemp /tmp/4geeks_user.XXXXXX)
trap 'rm -f "$USERFILE"' EXIT

HTTP_USER=$(curl -s -w "%{http_code}" \
  -H "Authorization: Token $TOKEN" \
  "${BASE_URL}/v1/admissions/user/me" \
  --max-time 30 \
  -o "$USERFILE")

if [ "$HTTP_USER" != "200" ]; then
    echo -e "${RED}${BOLD}ERROR al obtener datos del usuario (HTTP $HTTP_USER)${NC}"
    exit 1
fi

COHORT_ID=$(python3 -c "
import json
with open('$USERFILE') as f:
    u = json.load(f)
for ca in u.get('cohorts', []):
    c = ca.get('cohort', {})
    if c.get('slug') == 'latam-aie-pt-1':
        print(c.get('id', ''))
        break
")

if [ -z "$COHORT_ID" ]; then
    echo -e "${RED}${BOLD}ERROR: No se encontro cohorte latam-aie-pt-1${NC}"
    echo "Cohortes disponibles:"
    python3 -c "
import json
with open('$USERFILE') as f:
    u = json.load(f)
for ca in u.get('cohorts', []):
    c = ca.get('cohort', {})
    print('  - %s (id=%s)' % (c.get('slug','?'), c.get('id','?')))
"
    exit 1
fi

echo -e "  Cohorte: latam-aie-pt-1 (id=$COHORT_ID)"

# ----- Obtener tareas de esta cohorte -----
TMPFILE=$(mktemp /tmp/4geeks_tasks.XXXXXX)
trap 'rm -f "$TMPFILE"' EXIT

HTTP_CODE=$(curl -s -w "%{http_code}" \
  -H "Authorization: Token $TOKEN" \
  "${BASE_URL}/v1/assignment/user/me/task?cohort=${COHORT_ID}" \
  --max-time 30 \
  -o "$TMPFILE")

if [ "$HTTP_CODE" = "000" ]; then
    echo -e "${RED}${BOLD}ERROR DE CONEXION${NC}"
    exit 1
fi

if [ "$HTTP_CODE" = "401" ] || [ "$HTTP_CODE" = "403" ]; then
    echo -e "${RED}${BOLD}ERROR DE AUTENTICACION (HTTP $HTTP_CODE)${NC}"
    exit 1
fi

if [ "$HTTP_CODE" != "200" ]; then
    echo -e "${RED}${BOLD}ERROR HTTP $HTTP_CODE${NC}"
    head -c 500 "$TMPFILE"
    exit 1
fi

echo ""
echo -e "  Tareas obtenidas. Procesando..."

# ----- Procesar y mostrar con Python -----
python3 -c "
import json, sys

with open('$TMPFILE') as f:
    tasks = json.load(f)

if not isinstance(tasks, list):
    print('ERROR: La respuesta de la API no es una lista')
    print(repr(tasks)[:500])
    sys.exit(1)

# ============================================================================
# MAPEO de associated_slug -> Modulo
# ============================================================================
SLUG_MODULO = {
    # Proyectos
    'postcard':                                      'AI Engineering',
    'excuses-generator-javascript':                  'AI Engineering',
    'ai-eng-milestone-choose-company':               'AI Engineering',
    'html-css-artist-landing-seo-access':            'Web UI / Tailwind',
    'simple-dashboard-tailwind-css':                 'Web UI / Tailwind',
    'ai-eng-milestone-web-fundamentals':             'Web UI / Tailwind',
    'exercise-terminal-challenge':                   'Command Line, Git y Github',
    'first-collaborative-project-tailwind-css':      'Command Line, Git y Github',
    'ai-eng-architectural-proposal':                 'Backend / APIs',
    'ai-eng-user-authentication-api':                'Backend / APIs',
    'agent-hub-ui-specs-and-prompts':                'Frontend / React',
    'data-modeling-and-class-diagrams':              'TypeScript / Coding Fundamentals',
    'music-playlist-player-modeling-and-class-diagrams': 'TypeScript / Coding Fundamentals',
    'typescript-cinema-seat-manager':                'TypeScript / Coding Fundamentals',
    'ai-eng-milestone-coding-fundamentals':          'TypeScript / Coding Fundamentals',
    'nextjs-airbnb-ui-clone':                        'Frontend / React',
    'nextjs-wanderlust-explorer':                    'Frontend / React',
    'chat-interface-real-ai-api':                    'Frontend / React',
    'ai-eng-milestone-talent-pipeline-tracker':      'Frontend / React',
    'openclaw-setup':                                'AI Engineering / OpenClaw',
    'openclaw-connection':                           'AI Engineering / OpenClaw',
    'openclaw-skills':                               'AI Engineering / OpenClaw',
    'openclaw-integration':                          'AI Engineering / OpenClaw',
    'openclaw-onboarding-agent':                     'AI Engineering / OpenClaw',
    'company-financial-dashboard-context-project':   'AI Coding Agents',
    'company-financial-dashboard-specs-project':     'AI Coding Agents',
    'company-financial-dashboard-skills-project':    'AI Coding Agents',
    'ai-eng-ai-driven-engineering':                  'AI Coding Agents',
    'todo-list-cli-python':                          'Python',
    # Lecciones
    'learning-to-code-with-python':                  'Python',
    'conditionals-in-programing-python':             'Python',
    'working-with-functions-python':                 'Python',
    'what-are-third-party-libraries':                'Python',
    'understanding-rest-apis':                       'Backend / APIs',
    'how-to-consume-an-api-in-python':               'Python',
    'how-to-read-a-file-in-python':                  'Python',
    'intro-to-numpy':                                'Python',
    'intro-to-python-pandas':                        'Python',
    'what-are-python-dictionaries':                  'Python',
    'sorting-and-search-algorithms-in-python':       'Python',
    'what-is-a-python-list':                         'Python',
    'python-modules-organizing-and-reusing-code-like-an-expert': 'Python',
    # Ejercicios
    'understanding-objects-models-properties-and-dat-en': 'TypeScript / Coding Fundamentals',
    'html-fundamentals-building-web-structure-en':   'Web UI / Tailwind',
    'css-mastery-from-scratch-en':                   'Web UI / Tailwind',
    'command-line-fundamentals-for-developers-en':   'Command Line, Git y Github',
}

def inferir_modulo(slug, title):
    s = (slug + ' ' + title).lower()
    if any(x in s for x in ['python', 'numpy', 'pandas', 'best-practices',
                            'third-party', 'conditionals', 'dictionaries',
                            'loops', 'functions', 'lists', 'modules']):
        return 'Python'
    if any(x in s for x in ['html', 'css', 'tailwind', 'responsive',
                            'seo', 'accessibility', 'layout', 'form',
                            'web', 'landing']):
        return 'Web UI / Tailwind'
    if any(x in s for x in ['typescript', 'javascript', 'data-types',
                            'arrays', 'object', 'class-diagram', 'mastering',
                            'control-flow', 'json']):
        return 'TypeScript / Coding Fundamentals'
    if any(x in s for x in ['git', 'github', 'command-line', 'terminal',
                            'file-system', 'hierarchy']):
        return 'Command Line, Git y Github'
    if any(x in s for x in ['api', 'fastapi', 'http', 'rest', 'jwt',
                            'authentication', 'backend', 'common-backend',
                            'separation-by-domains', 'stateless',
                            'secure-pass', 'complex-json']):
        return 'Backend / APIs'
    if any(x in s for x in ['openclaw', 'memory']):
        return 'AI Engineering / OpenClaw'
    if any(x in s for x in ['react', 'nextjs', 'frontend', 'wanderlust',
                            'airbnb', 'chat-interface', 'agent-hub',
                            'talent-pipeline']):
        return 'Frontend / React'
    if any(x in s for x in ['coding', 'ai eng', 'ai-eng', 'ai-driven']):
        return 'AI Coding Agents'
    return 'Otro'


def get_modulo(t):
    slug = t.get('associated_slug', '')
    title = t.get('title', '')
    if slug in SLUG_MODULO:
        return SLUG_MODULO[slug]
    return inferir_modulo(slug, title)


def dedup_mejor_estado(lista, es_proyecto=False):
    agrupados = {}
    for t in lista:
        slug = t.get('associated_slug', '')
        if not slug:
            continue
        if slug not in agrupados:
            agrupados[slug] = dict(t)
        else:
            e = agrupados[slug]
            if es_proyecto:
                orden_rev = {'APPROVED': 3, 'REJECTED': 2, 'PENDING': 1}
                orden_ts = {'DONE': 2, 'PENDING': 1}
                rev = t.get('revision_status', 'PENDING')
                ts = t.get('task_status', 'PENDING')
                rev_e = e.get('revision_status', 'PENDING')
                ts_e = e.get('task_status', 'PENDING')
                if orden_rev.get(rev, 1) > orden_rev.get(rev_e, 1):
                    e['revision_status'] = rev
                    e['task_status'] = ts
                elif (orden_rev.get(rev, 1) == orden_rev.get(rev_e, 1)
                      and orden_ts.get(ts, 1) > orden_ts.get(ts_e, 1)):
                    e['task_status'] = ts
            else:
                orden_ts = {'DONE': 2, 'PENDING': 1}
                ts = t.get('task_status', 'PENDING')
                ts_e = e.get('task_status', 'PENDING')
                if orden_ts.get(ts, 1) > orden_ts.get(ts_e, 1):
                    e['task_status'] = ts
    return list(agrupados.values())


def print_tabla_bordes(titulo, header1, header2, filas):
    if not filas:
        print()
        print('  ' + titulo)
        print('  (vacio)')
        print()
        return
    ancho1 = max(len(str(f[0])) for f in filas)
    ancho2 = max(len(str(f[1])) for f in filas)
    ancho1 = max(ancho1, len(header1))
    ancho2 = max(ancho2, len(header2))
    print()
    print('  ' + titulo)
    print()
    print('  +' + '-' * (ancho1 + 2) + '+' + '-' * (ancho2 + 2) + '+')
    print('  | {:<{}} | {:<{}} |'.format(header1, ancho1, header2, ancho2))
    print('  +' + '-' * (ancho1 + 2) + '+' + '-' * (ancho2 + 2) + '+')
    for i, f in enumerate(filas):
        print('  | {:<{}} | {:<{}} |'.format(str(f[0]), ancho1, str(f[1]), ancho2))
    print('  +' + '-' * (ancho1 + 2) + '+' + '-' * (ancho2 + 2) + '+')
    print()


# ============================================================================
# PROCESAR DATOS
# ============================================================================

# Separar por tipo y deduplicar
proyectos_dedup = dedup_mejor_estado(
    [t for t in tasks if t.get('task_type') == 'PROJECT'], True)
lecciones_dedup = dedup_mejor_estado(
    [t for t in tasks if t.get('task_type') == 'LESSON'], False)
ejercicios_dedup = dedup_mejor_estado(
    [t for t in tasks if t.get('task_type') == 'EXERCISE'], False)

# Filtrar solo pendientes
proyectos = [p for p in proyectos_dedup if p.get('task_status') == 'PENDING']
lecciones = [l for l in lecciones_dedup if l.get('task_status') == 'PENDING']
ejercicios = [e for e in ejercicios_dedup if e.get('task_status') == 'PENDING']

# Ordenar por modulo, luego titulo
proyectos.sort(key=lambda x: (get_modulo(x), x.get('title', '')))
lecciones.sort(key=lambda x: (get_modulo(x), x.get('title', '')))
ejercicios.sort(key=lambda x: (get_modulo(x), x.get('title', '')))

# Conteos
tp, tl, te = len(proyectos), len(lecciones), len(ejercicios)
tg = tp + tl + te

# ============================================================================
# PORTADA
# ============================================================================
print()
print('  ' + '=' * 72)
print('  TRABAJO PENDIENTE - 4GEEKS ACADEMY')
print('  ' + '=' * 72)
print()
print('  Total: %d pendientes' % tg)
print('  ' + '-' * 40)
print('    Proyectos:    %2d' % tp)
print('    Lecciones:    %2d' % tl)
print('    Ejercicios:   %2d' % te)
print()

# ============================================================================
# TABLA 1: PROYECTOS — detalle individual
# ============================================================================
filas_proyectos = [(get_modulo(p), p.get('title', '?')) for p in proyectos]
print_tabla_bordes(
    chr(128196) + ' PROYECTOS PENDIENTES (%d)' % tp,
    'MODULO', 'PROYECTO', filas_proyectos
)

# ============================================================================
# TABLA 2: LECCIONES — detalle individual
# ============================================================================
filas_lecciones = [(get_modulo(l), l.get('title', '?')) for l in lecciones]
print_tabla_bordes(
    chr(128218) + ' LECCIONES PENDIENTES (%d)' % tl,
    'MODULO', 'LECCION', filas_lecciones
)

# ============================================================================
# TABLA 3: EJERCICIOS — detalle individual
# ============================================================================
filas_ejercicios = [(get_modulo(e), e.get('title', '?')) for e in ejercicios]
print_tabla_bordes(
    chr(128187) + ' EJERCICIOS PENDIENTES (%d)' % te,
    'MODULO', 'EJERCICIO', filas_ejercicios
)

# ============================================================================
# CIERRE
# ============================================================================
print('  ' + '=' * 72)
print('  RESUMEN: %d pendientes (%d proyectos, %d lecciones, %d ejercicios)' % (tg, tp, tl, te))
print('  Cohorte: latam-aie-pt-1')
print('  ' + '=' * 72)
print()
" 2>&1