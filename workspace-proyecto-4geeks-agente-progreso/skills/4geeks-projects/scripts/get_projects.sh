#!/usr/bin/env bash
#
# get_projects.sh — Obtener mis proyectos de 4Geeks Academy
#
# Endpoint: GET /v1/assignment/user/me/task
# Agrupa por associated_slug, toma el mejor status, y muestra 4 tablas:
#   - Aprobados | Rechazados | Esperando aprobacion | Pendientes
#
# Cada tabla tiene 2 columnas: MODULO | PROYECTO
#
# Uso: ./get_projects.sh
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
ENDPOINT="/v1/assignment/user/me/task"

# ----- Cargar token desde .env -----
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SKILL_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
WORKSPACE_DIR="$(cd "$SKILL_DIR/../.." && pwd)"
ENV_FILE="$WORKSPACE_DIR/.env"

if [ ! -f "$ENV_FILE" ]; then
    echo -e "${RED}ERROR: No se encuentra $ENV_FILE${NC}"
    exit 1
fi

# Extraer token del .env (formato: 4GEEKS_ACCESS_TOKEN='***')
TOKEN=$(grep '^4GEEKS_ACCESS_TOKEN' "$ENV_FILE" | cut -d= -f2- | tr -d "'\" \t\r\n") || true

if [ -z "$TOKEN" ]; then
    echo -e "${RED}ERROR: 4GEEKS_ACCESS_TOKEN no encontrado en .env${NC}"
    exit 1
fi

# ----- Llamada API -----
echo -e "${CYAN}${BOLD}Consultando proyectos en 4Geeks Academy...${NC}"
echo ""

TMPFILE=$(mktemp /tmp/4geeks_projects.XXXXXX)
trap 'rm -f "$TMPFILE"' EXIT

HTTP_CODE=$(curl -s -w "%{http_code}" \
  -H "Authorization: Token $TOKEN" \
  "${BASE_URL}${ENDPOINT}" \
  --max-time 30 \
  -o "$TMPFILE")

# ----- Manejo de errores -----
if [ "$HTTP_CODE" = "000" ]; then
    echo -e "${RED}${BOLD}ERROR DE CONEXION${NC}"
    echo "No se pudo conectar con $BASE_URL"
    exit 1
fi

if [ "$HTTP_CODE" = "401" ] || [ "$HTTP_CODE" = "403" ]; then
    echo -e "${RED}${BOLD}ERROR DE AUTENTICACION (HTTP $HTTP_CODE)${NC}"
    echo "El token no es valido o ha expirado."
    exit 1
fi

if [ "$HTTP_CODE" != "200" ]; then
    echo -e "${RED}${BOLD}ERROR HTTP $HTTP_CODE${NC}"
    head -c 500 "$TMPFILE"
    exit 1
fi

# ----- Analizar con Python -----
python3 -c "
import json, sys

with open('$TMPFILE') as f:
    tasks = json.load(f)

# Tomar solo proyectos
proyectos_raw = [t for t in tasks if t.get('task_type') == 'PROJECT']

# Mapeo de associated_slug -> Modulo
SLUG_MODULO = {
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
}

# Agrupar por slug, tomar el mejor estado
agrupados = {}
for p in proyectos_raw:
    slug = p.get('associated_slug', '')
    title = p['title']
    status = p.get('task_status', 'PENDING')
    rev = p.get('revision_status', 'PENDING')

    if slug not in agrupados:
        mod = SLUG_MODULO.get(slug, 'Otro')
        agrupados[slug] = {
            'title': title,
            'task_status': status,
            'revision_status': rev,
            'modulo': mod,
        }
    else:
        existente = agrupados[slug]
        orden_rev = {'APPROVED': 3, 'REJECTED': 2, 'PENDING': 1}
        orden_ts = {'DONE': 2, 'PENDING': 1}
        if orden_rev.get(rev, 1) > orden_rev.get(existente['revision_status'], 1):
            existente['revision_status'] = rev
            existente['task_status'] = status
        elif orden_rev.get(rev, 1) == orden_rev.get(existente['revision_status'], 1) and \
             orden_ts.get(status, 1) > orden_ts.get(existente['task_status'], 1):
            existente['task_status'] = status

# Convertir a lista y ordenar por modulo, luego titulo
proyectos = list(agrupados.values())
proyectos.sort(key=lambda x: (x['modulo'], x['title']))

# Clasificar en 4 categorias
aprobados = [p for p in proyectos if p.get('revision_status') == 'APPROVED']
rechazados = [p for p in proyectos if p.get('revision_status') == 'REJECTED']
esperando = [p for p in proyectos if p.get('task_status') == 'DONE' and p.get('revision_status') not in ('APPROVED','REJECTED')]
pendientes = [p for p in proyectos if p.get('task_status') == 'PENDING']

print('=' * 75)
print('  MIS PROYECTOS - 4GEEKS ACADEMY')
print('=' * 75)
print()

# ---- 1. NUMEROS (resumen) ----
total = len(proyectos)
print('  TOTAL PROYECTOS: %d' % total)
print('  ' + '-' * 50)
print('    Aprobados:               %2d' % len(aprobados))
print('    Rechazados:              %2d' % len(rechazados))
print('    Esperando aprobacion:   %2d' % len(esperando))
print('    Pendientes:              %2d' % len(pendientes))
print()

# ---- 2. TABLAS ----
HEADER = '  %-35s | %s' % ('MODULO', 'PROYECTO')
SEP = '  ' + '-' * 70

def print_tabla(titulo, lista, emoji):
    print('  ' + emoji + ' ' + titulo)
    print(SEP)
    if not lista:
        print('  (vacio)')
        print()
        return
    print(HEADER)
    print(SEP)
    for i, p in enumerate(lista, 1):
        title = p['title']
        mod = p['modulo']
        if len(mod) > 34:
            mod = mod[:32] + '..'
        if len(title) > 55:
            title = title[:52] + '...'
        print('  %-35s | %s' % (mod, title))
    print()

print_tabla('APROBADOS (%d)' % len(aprobados), aprobados, chr(9989))
print_tabla('RECHAZADOS (%d)' % len(rechazados), rechazados, chr(10060))
print_tabla('ESPERANDO APROBACION (%d)' % len(esperando), esperando, chr(9203))
print_tabla('PENDIENTES (%d)' % len(pendientes), pendientes, chr(128203))

print('=' * 75)
print('  RESUMEN: %d aprobados | %d rechazados | %d esperando revision | %d pendientes' % (len(aprobados), len(rechazados), len(esperando), len(pendientes)))
print('=' * 75)
"
