#!/bin/bash
# ============================================================
# 4Geeks Auth — Verify Token
# Verifica que el token de 4Geeks Academy es válido y la sesión
# está activa. Lee el token desde .env y llama a la API.
# ============================================================

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# --- 1. Locate .env ---
ENV_FILE="/root/.openclaw/workspace/.env"
if [ ! -f "$ENV_FILE" ]; then
    echo -e "${RED}❌ ERROR: No se encuentra .env${NC}"
    echo "   Buscado en: $ENV_FILE"
    echo "   Crea el archivo con: 4GEEKS_ACCESS_TOKEN=tu_token"
    exit 1
fi

# --- 2. Read token ---
TOKEN=$(grep -oP '^4GEEKS_ACCESS_TOKEN=\K.*' "$ENV_FILE" | tr -d '"' | tr -d "'" | xargs)

if [ -z "$TOKEN" ]; then
    echo -e "${RED}❌ ERROR: No se encontró 4GEEKS_ACCESS_TOKEN en .env${NC}"
    echo "   El archivo .env debe contener: 4GEEKS_ACCESS_TOKEN=tu_token_de_4geeks"
    exit 1
fi

echo -e "${BLUE}🔐 Verificando autenticación con 4Geeks Academy...${NC}"
echo "   Token: ${TOKEN:0:8}...${TOKEN: -4}"
echo "   Endpoint: GET https://breathecode.herokuapp.com/v1/auth/user/me"
echo ""

# --- 3. Call API ---
API_RESPONSE=$(curl -s -w "\n%{http_code}" \
    -H "Authorization: Token $TOKEN" \
    -H "Accept: application/json" \
    --max-time 15 \
    https://breathecode.herokuapp.com/v1/auth/user/me 2>&1)

HTTP_CODE=$(echo "$API_RESPONSE" | tail -1)
BODY=$(echo "$API_RESPONSE" | sed '$d')

echo -e "   HTTP Status: $HTTP_CODE"
echo ""

# --- 4. Evaluate response ---
case "$HTTP_CODE" in
    200)
        echo -e "${GREEN}✅ TOKEN VÁLIDO — Sesión activa${NC}"
        echo ""

        # Extract user info from JSON response
        USER_ID=$(echo "$BODY" | grep -oP '"id":\K[0-9]+' | head -1)
        EMAIL=$(echo "$BODY" | grep -oP '"email":"\K[^"]+' | head -1)
        FIRST_NAME=$(echo "$BODY" | grep -oP '"first_name":"\K[^"]+' | head -1)
        LAST_NAME=$(echo "$BODY" | grep -oP '"last_name":"\K[^"]+' | head -1)
        ROLE=$(echo "$BODY" | grep -oP '"role":"\K[^"]+' | head -1)
        ACADEMY=$(echo "$BODY" | grep -oP '"academy":\{[^}]*"name":"\K[^"]+' | head -1)
        USERNAME=$(echo "$BODY" | grep -oP '"username":"\K[^"]+' | head -1)

        echo -e "   👤 Usuario:  ${FIRST_NAME:-N/A} ${LAST_NAME:-N/A}"
        echo -e "   📧 Email:    ${EMAIL:-N/A}"
        echo -e "   🆔 User:     ${USERNAME:-N/A}"
        echo -e "   🆔 ID:       ${USER_ID:-N/A}"
        echo -e "   🎯 Rol:      ${ROLE:-N/A}"
        echo -e "   🏫 Academia: ${ACADEMY:-N/A}"
        echo ""
        echo -e "${GREEN}✅ Autenticación completada exitosamente.${NC}"
        exit 0
        ;;

    401|403)
        echo -e "${RED}❌ TOKEN INVÁLIDO O EXPIRADO${NC}"
        echo ""
        echo -e "   ${YELLOW}El token actual no es válido.${NC}"
        echo ""
        echo "   Para obtener un nuevo token:"
        echo "     1. Inicia sesión en https://4geeks.com"
        echo "     2. Ve a tu perfil / configuración"
        echo "     3. Copia tu token de acceso"
        echo "     4. Actualiza el archivo .env:"
        echo ""
        echo "       4GEEKS_ACCESS_TOKEN=nuevo_token_aqui"
        echo ""
        exit 1
        ;;

    000|"")
        echo -e "${RED}❌ ERROR DE CONEXIÓN${NC}"
        echo ""
        echo -e "   ${YELLOW}No se pudo conectar con la API de 4Geeks.${NC}"
        echo ""
        echo "   Posibles causas:"
        echo "     • Sin conexión a Internet"
        echo "     • El servicio de 4Geeks no está disponible"
        echo "     • Firewall bloqueando la conexión"
        echo ""
        echo "   URL: https://breathecode.herokuapp.com/v1/auth/user/me"
        exit 1
        ;;

    *)
        echo -e "${YELLOW}⚠️  RESPUESTA INESPERADA (HTTP $HTTP_CODE)${NC}"
        echo ""
        echo "   La API respondió con un código no esperado."
        echo ""
        echo "   Diagnóstico:"
        echo "   ------------"
        echo "$BODY" | head -5
        echo ""
        exit 1
        ;;
esac