#!/usr/bin/env bash
#
# get_progreso.sh — Obtener resumen de progreso en 4Geeks Academy
#
# Endpoint: GET /v1/assignment/user/me/task (TODAS las cohortes)
# Deduplica por slug, toma el mejor estado
# Muestra: progreso general, por tipo, por modulo, y detalle de pendientes
#
# Uso: ./get_progreso.sh
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

# Extraer token del .env
TOKEN=$(grep -m1 '^4GEEKS_ACCESS_TOKEN' "$ENV_FILE" | cut -d= -f2- | tr -d "'\" \t\r\n") || true

if [ -z "$TOKEN" ]; then
    echo -e "${RED}ERROR: 4GEEKS_ACCESS_TOKEN no encontrado en .env${NC}"
    exit 1
fi

echo -e "${CYAN}${BOLD}Consultando progreso academico...${NC}"
echo ""

# ----- Obtener datos del usuario -----
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

# ----- Obtener TODAS las tareas (sin filtro de cohorte) -----
TMPFILE=$(mktemp /tmp/4geeks_tasks.XXXXXX)
trap 'rm -f "$TMPFILE"' EXIT

HTTP_CODE=$(curl -s -w "%{http_code}" \
  -H "Authorization: Token $TOKEN" \
  "${BASE_URL}/v1/assignment/user/me/task" \
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
echo -e "  Procesando datos de progreso..."

# ----- Procesar y mostrar con Python -----
python3 -c "
import json, sys

with open('$TMPFILE') as f:
    tasks = json.load(f)

with open('$USERFILE') as f:
    user_data = json.load(f)

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
    '4geeks-method-the-assignments':                 'Web UI / Tailwind',
    'conditionals-in-programing-coding':             'TypeScript / Coding Fundamentals',
    'context-api':                                   'Frontend / React',
    'debugging-css-code':                            'Web UI / Tailwind',
    'debugging-html-code':                           'Web UI / Tailwind',
    'what-is-an-array-define-array':                 'TypeScript / Coding Fundamentals',
    'what-is-coding-learn-to-code':                  'TypeScript / Coding Fundamentals',
    'what-is-css-learn-css':                         'Web UI / Tailwind',
    'what-is-html-learn-html':                       'Web UI / Tailwind',
    'what-is-javascript-learn-to-code-in-javascript': 'TypeScript / Coding Fundamentals',
    'what-is-the-internet':                          'TypeScript / Coding Fundamentals',
    'working-with-functions':                        'TypeScript / Coding Fundamentals',
    # Ejercicios
    'understanding-objects-models-properties-and-dat-en': 'TypeScript / Coding Fundamentals',
    'html-fundamentals-building-web-structure-en':   'Web UI / Tailwind',
    'css-mastery-from-scratch-en':                   'Web UI / Tailwind',
    'command-line-fundamentals-for-developers-en':   'Command Line, Git y Github',
    'introduction-to-4geeks-academy-and-bootcamp-en': 'General',
    'how-to-submit-your-projects-on-4geeks-en':       'General',
}

def inferir_modulo(slug, title):
    s = (slug + ' ' + title).lower()
    if any(x in s for x in ['python', 'numpy', 'pandas', 'best-practices',
                            'third-party', 'conditionals', 'dictionaries',
                            'loops', 'functions', 'lists', 'modules']):
        return 'Python'
    if any(x in s for x in ['html', 'css', 'tailwind', 'responsive',
                            'seo', 'accessibility', 'layout', 'form',
                            'web', 'landing', 'debugging-css',
                            'debugging-html', '4geeks-method']):
        return 'Web UI / Tailwind'
    if any(x in s for x in ['typescript', 'javascript', 'data-types',
                            'arrays', 'object', 'class-diagram', 'mastering',
                            'control-flow', 'json', 'dom', 'internet',
                            'coding', 'programming', 'spa', 'bundling',
                            'spec-driven', 'token-efficiency', 'the-constructive',
                            'visual-to-spec', 'speaking', 'prompting',
                            'generative', 'introduction-to-programming',
                            'what-is-coding', 'what-is-an-array',
                            'what-is-javascript', 'what-is-the-internet',
                            'working-with-functions', 'js',
                            'mutability']):
        return 'TypeScript / Coding Fundamentals'
    if any(x in s for x in ['git', 'github', 'command-line', 'terminal',
                            'file-system', 'hierarchy', 'ssh', 'vps',
                            'managing-a-vps']):
        return 'Command Line, Git y Github'
    if any(x in s for x in ['api', 'fastapi', 'http', 'jwt',
                            'authentication', 'backend', 'common-backend',
                            'separation-by-domains', 'stateless',
                            'secure-pass', 'complex-json', 'sessions',
                            'communicating-with-external', 'auth',
                            'secure-passwords']):
        return 'Backend / APIs'
    # 'rest' solo si no es 'restructuring' ni 'rest-apis'
    if 'rest' in s and 'restructur' not in s and 'rest apis' not in s:
        return 'Backend / APIs'
    if any(x in s for x in ['openclaw', 'memory', 'agent', 'skill',
                            'secret', 'composio', 'teaching',
                            'introduction-to-openclaw', 'openclaw-advanced',
                            'setting-up-your', 'restructuring',
                            'security-risks', 'connecting-openclaw',
                            'how-to-make-your-agent', 'introduction-to-ssh',
                            'introduction-to-vps', 'assigning-simple',
                            'managing-secrets']):
        return 'AI Engineering / OpenClaw'
    if any(x in s for x in ['react', 'nextjs', 'frontend', 'wanderlust',
                            'airbnb', 'chat-interface', 'agent-hub',
                            'talent-pipeline', 'context-api', 'data-flow',
                            'organizing-my-frontend', 'the-constructive']):
        return 'Frontend / React'
    if any(x in s for x in ['coding agents', 'ai-coding', 'ai-communication',
                            'ai-context', 'ai-engineering-fundamentals',
                            'spec-driven', 'skill-creation',
                            'token-efficiency', 'using-coding',
                            'debugging-evidence', 'agent-skills']):
        return 'AI Coding Agents'
    if any(x in s for x in ['docker', 'container', 'pipeline',
                            'data-pipeline', 'asynchronous',
                            'telemetry', 'architecture']):
        return 'DevOps / Data'
    return 'Otro'


def get_modulo(t):
    slug = t.get('associated_slug', '')
    title = t.get('title', '')
    if slug in SLUG_MODULO:
        return SLUG_MODULO[slug]
    return inferir_modulo(slug, title)


def dedup_mejor_estado(lista):
    agrupados = {}
    for t in lista:
        slug = t.get('associated_slug', '')
        if not slug:
            continue
        tt = t.get('task_type', '')
        if slug not in agrupados:
            agrupados[slug] = dict(t)
        else:
            e = agrupados[slug]
            if tt == 'PROJECT':
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


def barra_progreso(pct, ancho=20):
    llenos = int(round(pct / 100 * ancho))
    vacios = ancho - llenos
    return chr(9608) * llenos + chr(9617) * vacios


# ============================================================================
# PROCESAR DATOS
# ============================================================================
unicos = dedup_mejor_estado(tasks)

# Separar por tipo
proyectos = [u for u in unicos if u.get('task_type') == 'PROJECT']
lecciones = [u for u in unicos if u.get('task_type') == 'LESSON']
ejercicios = [u for u in unicos if u.get('task_type') == 'EXERCISE']

# Proyectos
tp_total = len(proyectos)
tp_aprobados = sum(1 for p in proyectos if p.get('revision_status') == 'APPROVED')
tp_rechazados = sum(1 for p in proyectos if p.get('revision_status') == 'REJECTED')
tp_revision = sum(1 for p in proyectos if p.get('task_status') == 'DONE' and p.get('revision_status') not in ('APPROVED','REJECTED'))
tp_pendientes = sum(1 for p in proyectos if p.get('task_status') == 'PENDING')
tp_completados = tp_aprobados + tp_revision

# Lecciones
tl_total = len(lecciones)
tl_completadas = sum(1 for l in lecciones if l.get('task_status') == 'DONE')
tl_pendientes = tl_total - tl_completadas

# Ejercicios
te_total = len(ejercicios)
te_completados = sum(1 for e in ejercicios if e.get('task_status') == 'DONE')
te_aprobados = sum(1 for e in ejercicios if e.get('revision_status') == 'APPROVED')
te_pendientes = te_total - te_completados

# Totales
total_items = tp_total + tl_total + te_total
total_completados = tp_completados + tl_completadas + te_completados
total_pendientes = total_items - total_completados
pct_general = round(total_completados / total_items * 100, 1) if total_items else 0

# ============================================================================
# RESUMEN POR MODULO
# ============================================================================
from collections import defaultdict
modulos_totales = defaultdict(lambda: {'proyectos': 0, 'lecciones': 0, 'ejercicios': 0,
                                        'proyectos_done': 0, 'lecciones_done': 0, 'ejercicios_done': 0})

for p in proyectos:
    mod = get_modulo(p)
    modulos_totales[mod]['proyectos'] += 1
    if p.get('task_status') == 'DONE' or p.get('revision_status') == 'APPROVED':
        modulos_totales[mod]['proyectos_done'] += 1

for l in lecciones:
    mod = get_modulo(l)
    modulos_totales[mod]['lecciones'] += 1
    if l.get('task_status') == 'DONE':
        modulos_totales[mod]['lecciones_done'] += 1

for e in ejercicios:
    mod = get_modulo(e)
    modulos_totales[mod]['ejercicios'] += 1
    if e.get('task_status') == 'DONE':
        modulos_totales[mod]['ejercicios_done'] += 1

# ============================================================================
# MOSTRAR RESUMEN
# ============================================================================
print()
print('  ' + '=' * 72)
print('  RESUMEN DE PROGRESO ACADEMICO - 4GEEKS ACADEMY')
print('  ' + '=' * 72)
print()
print('  Progreso general: %d de %d completados (%d pendientes)' % (total_completados, total_items, total_pendientes))
print()
print('  ' + barra_progreso(pct_general, 40) + '  %5.1f%%' % pct_general)
print()

# --- Tabla resumen por tipo ---
print('  ' + '-' * 72)
print('  %-15s | %s' % ('TIPO', 'COMPLETADOS  |  PENDIENTES'))
print('  ' + '-' * 72)

pct_p = round(tp_completados / tp_total * 100, 1) if tp_total else 0
print('  %-15s | %2d/%2d %s %5.1f%%  |  %2d' % ('Proyectos', tp_completados, tp_total, barra_progreso(pct_p, 12), pct_p, tp_pendientes))
if tp_aprobados > 0:
    print('  %-15s   Aprobados: %d, en revision: %d' % ('', tp_aprobados, tp_revision))
if tp_rechazados > 0:
    print('  %-15s   Rechazados: %d' % ('', tp_rechazados))

pct_l = round(tl_completadas / tl_total * 100, 1) if tl_total else 0
print('  %-15s | %2d/%2d %s %5.1f%%  |  %2d' % ('Lecciones', tl_completadas, tl_total, barra_progreso(pct_l, 12), pct_l, tl_pendientes))

pct_e = round(te_completados / te_total * 100, 1) if te_total else 0
print('  %-15s | %2d/%2d %s %5.1f%%  |  %2d' % ('Ejercicios', te_completados, te_total, barra_progreso(pct_e, 12), pct_e, te_pendientes))
if te_aprobados > 0:
    print('  %-15s   Aprobados: %d' % ('', te_aprobados))

print('  ' + '-' * 72)
print()

# --- Tabla por modulo ---
print('  ' + '=' * 72)
print('  PROGRESO POR MODULO')
print('  ' + '=' * 72)
print()
print('  %-35s | %s | %s | %s' % ('MODULO', 'PROY', 'LEC', 'EJER'))
print('  ' + '-' * 72)
print('  %-35s | %-5s | %-5s | %-5s' % ('', 'P/L', 'P/L', 'P/L'))
print('  ' + '-' * 72)

for mod in sorted(modulos_totales.keys()):
    d = modulos_totales[mod]
    p = '%d/%d' % (d['proyectos_done'], d['proyectos']) if d['proyectos'] else '-'
    l = '%d/%d' % (d['lecciones_done'], d['lecciones']) if d['lecciones'] else '-'
    e = '%d/%d' % (d['ejercicios_done'], d['ejercicios']) if d['ejercicios'] else '-'
    print('  %-35s | %5s | %5s | %5s' % (mod, p, l, e))

print('  ' + '-' * 72)
print()

# --- Lista de cohortes activas ---
print('  ' + '=' * 72)
print('  COHORTES ACTIVAS')
print('  ' + '=' * 72)
print()
cohorts_seen = set()
for ca in user_data.get('cohorts', []):
    c = ca.get('cohort', {})
    slug = c.get('slug', '')
    name = c.get('name', '')
    status = ca.get('educational_status', '')
    if status == 'ACTIVE' and slug not in cohorts_seen:
        cohorts_seen.add(slug)
        print('  - %s' % name)
print()

# --- Detalle de pendientes por modulo ---
print('  ' + '=' * 72)
print('  DETALLE DE PENDIENTES POR MODULO')
print('  ' + '=' * 72)
print()

pend_por_mod = defaultdict(lambda: {'proyectos': [], 'lecciones': [], 'ejercicios': []})
for p in proyectos:
    if p.get('task_status') == 'PENDING':
        mod = get_modulo(p)
        pend_por_mod[mod]['proyectos'].append(p.get('title', '?'))
for l in lecciones:
    if l.get('task_status') == 'PENDING':
        mod = get_modulo(l)
        pend_por_mod[mod]['lecciones'].append(l.get('title', '?'))
for e in ejercicios:
    if e.get('task_status') == 'PENDING':
        mod = get_modulo(e)
        pend_por_mod[mod]['ejercicios'].append(e.get('title', '?'))

for mod in sorted(pend_por_mod.keys()):
    d = pend_por_mod[mod]
    total_mod = len(d['proyectos']) + len(d['lecciones']) + len(d['ejercicios'])
    if total_mod == 0:
        continue
    print('  %s' % mod)
    if d['proyectos']:
        print('    Proyectos (%d):' % len(d['proyectos']))
        for t in d['proyectos']:
            print('      - %s' % t)
    if d['lecciones']:
        print('    Lecciones (%d):' % len(d['lecciones']))
        for t in d['lecciones']:
            print('      - %s' % t)
    if d['ejercicios']:
        print('    Ejercicios (%d):' % len(d['ejercicios']))
        for t in d['ejercicios']:
            print('      - %s' % t)
    print()

# --- Cierre ---
print('  ' + '=' * 72)
print('  TOTAL: %d items | %d completados (%5.1f%%) | %d pendientes' % (total_items, total_completados, pct_general, total_pendientes))
print('  ' + '=' * 72)
print()
" 2>&1