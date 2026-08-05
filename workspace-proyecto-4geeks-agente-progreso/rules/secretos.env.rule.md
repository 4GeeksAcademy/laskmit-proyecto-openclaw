# Regla: Manejo de Secretos y Credenciales

## Propósito

Proteger todas las claves de API, tokens, contraseñas y datos sensibles evitando que queden en texto plano dentro del workspace.

## Regla Obligatoria

**Todos los secretos** (API keys, tokens, access tokens, contraseñas, claves de autenticación, etc.) **deben almacenarse exclusivamente en el archivo `workspace/.env`**.

### ✅ Correcto

```bash
# .env
4GEEKS_ACCESS_TOKEN=dbb83d...57c8
COMPOSIO_API_KEY=ck_abc123...
```

```python
# script.py
import os
API_KEY = os.environ.get('COMPOSIO_API_KEY')
TOKEN = os.environ.get('4GEEKS_ACCESS_TOKEN')
```

### ❌ Prohibido

- ❌ Valores de secretos escritos directamente en código (`api_key = "abc123"`)
- ❌ Variables con el valor inline en archivos `.py`, `.json`, `.yaml`, `.sh`, `.md`, etc.
- ❌ Tokens hardcodeados en URLs o headers de autenticación
- ❌ `.env` con permisos 644 (debe ser 600)

### Archivos excluidos (no aplica regla)

- `node_modules/`, `.git/`, `.openclaw/`, `__pycache__/`
- Archivos de terceros que no controlamos

## Cómo Usar Secretos Correctamente

1. Agregar la variable al archivo `workspace/.env`
2. Cargar la variable con `os.environ.get('VARIABLE')` o `os.getenv('VARIABLE')`
3. Nunca escribir el valor real del secreto en ningún otro archivo

## Permisos del .env

```bash
chmod 600 workspace/.env
```

Esto asegura que solo el dueño del archivo pueda leerlo.

## Reporte de Archivos Afectados

A continuación, los archivos en el workspace que referencian variables de secretos y deben ser revisados para asegurar que los valores no estén hardcodeados:

| Archivo | Variable Referenciada | Estado |
|---|---|---|
| upload_v4.py | `API_KEY` | Referencia variable (OK si no hardcodea) |
| upload_v6.py | `API_KEY` | Referencia variable (OK si no hardcodea) |
| upload_v2.py | `API_KEY` | Referencia variable (OK si no hardcodea) |
| upload_video.py | `API_KEY` | Referencia variable (OK si no hardcodea) |
| upload_complete.py | `API_KEY` | Referencia variable (OK si no hardcodea) |
| upload_v5.py | `API_KEY` | Referencia variable (OK si no hardcodea) |
| upload_v3.py | `API_KEY` | Referencia variable (OK si no hardcodea) |
| mcp_test.py | `API_KEY` | Referencia variable (OK si no hardcodea) |
| process_chat.py | `API_KEY` | Referencia variable (OK si no hardcodea) |
| real_download_upload.py | `API_KEY`, `token` | REVISAR: contiene `ck_U1uWKVXwqAtCuClGEaE6` hardcodeado |
| `.env` | `4GEEKS_ACCESS_TOKEN` | ✅ OK — archivo de secretos |

> **Nota:** La mayoría de los archivos `.py` usan `API_KEY` como nombre de variable (cargada desde entorno). El único archivo que **sí tiene un valor hardcodeado** es `real_download_upload.py` con la línea `"x-consumer-api-key": "ck_U1uWKVXwqAtCuClGEaE6"`. Ese valor debe moverse al `.env`.

## Cómo Verificar

```bash
# Escanear secretos hardcodeados (excluyendo node_modules, .git, etc.)
grep -rns -E '(api[_-]?key|token|secret|password)\s*[=:]\s*["'"'"'][A-Za-z0-9_\-]{8,}' workspace/ \
  --include='*.py' --include='*.js' --include='*.json' --include='*.yaml' --include='*.sh' \
  | grep -v node_modules | grep -v '.git'
```
