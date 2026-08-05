---
name: 4geeks-auth
description: "Verificar que el token de 4Geeks Academy es válido y la sesión está activa. Si falla, solicitar nuevo token en .env."
---

# 4Geeks Auth — Verificación de autenticación

Skill para verificar que el token de acceso a la API de 4Geeks Academy (`breathecode.herokuapp.com`) es válido y la sesión está activa.

## Cuándo usarlo

- Al iniciar cualquier interacción con 4Geeks Academy API
- Cuando una llamada a la API devuelve 401/403 (token expirado o inválido)
- Para verificar que la configuración de autenticación está correcta

## Flujo de verificación

1. **Leer token** del archivo `.env` en el workspace (`4GEEKS_ACCESS_TOKEN`)
2. **Llamar al endpoint** `GET https://breathecode.herokuapp.com/v1/auth/user/me` con header `Authorization: Token <token>`
3. **Evaluar respuesta:**
   - **HTTP 200** → Token válido ✅. Mostrar datos del usuario (nombre, email, rol) y reportar sesión activa.
   - **HTTP 401 / 403** → Token inválido o expirado ❌. Mostrar mensaje: *"Token inválido o expirado. Por favor obtén un nuevo token desde 4Geeks.com y actualízalo en .env como 4GEEKS_ACCESS_TOKEN"*
   - **HTTP 000 / timeout / error de red** → Problema de conexión. Mostrar: *"No se pudo conectar con la API de 4Geeks. Verifica la conexión a Internet y que el servicio esté disponible."*
   - **Otro código** → Error inesperado. Mostrar el código HTTP para diagnóstico.

## Script de verificación

Ejecutar el script `scripts/verify_token.sh` que automatiza todo el flujo.

## Token en .env

El token debe estar en el archivo:
```
/root/.openclaw/workspace/.env
```

Con el formato:
```
4GEEKS_ACCESS_TOKEN=tu_token_aqui
```

## Endpoints de referencia

| Endpoint | Método | Descripción |
|----------|--------|-------------|
| `/v1/auth/user/me` | GET | Datos del usuario autenticado |
| `/v1/auth/login/` | POST | Login (no usado aquí, solo autenticación por token) |

## Notas

- El token es de tipo **Token** (no Bearer), se envía como `Authorization: Token <valor>`
- El endpoint funciona **sin** trailing slash (`/v1/auth/user/me`, no `/v1/auth/user/me/`)
- Un token puede expirar. Si el usuario cambia el token en 4Geeks.com, debe actualizarlo en `.env`