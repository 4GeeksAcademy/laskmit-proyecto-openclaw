---
name: "guardar-notas-telegram-googledocs"
description: "Clasifica y registra notas de WhatsApp/Telegram en Google Docs por categoría con URLs clickables y adjuntos multimedia"
---

# Habilidad: Guardar notas de Telegram en Google Docs

## Descripción
Organiza notas, enlaces y multimedia recibidos por WhatsApp exportado o Telegram en documentos de Google Docs por categoría, ordenados por fecha de recepción.

## Cuándo Usar
Activar en dos flujos exclusivos:
- Carga inicial histórica: cuando se entrega un `.zip` exportado desde WhatsApp con chat y adjuntos.
- Flujo diario: cuando llegan mensajes directos en Telegram con enlaces (Instagram, YouTube, TikTok, etc.), fotos, texto o notas de voz.

No activar para mensajes de Telegram que pertenezcan al flujo de caja personal.

## Prerrequisitos
- Conexión operativa vía Composio para Google Docs y Google Drive.
- API Key de Composio: se encuentra en `/root/.openclaw/openclaw.json` bajo `mcp.servers.composio.headers` como `x-consumer-api-key`.
- La conexión MCP usa `COMPOSIO_MULTI_EXECUTE_TOOL` como tool único; dentro de él se pasa `tool_slug` y `arguments`.
- Para operaciones secuenciales complejas, usar `COMPOSIO_REMOTE_WORKBENCH` con `run_composio_tool()`.
- Acceso a la cuenta `yolanda.4geeks@gmail.com`.
- Carpeta destino en Drive: `Notas_preferencias/` (id: `1yfcFSY2tc5g9Ys5Bwtv84uWWJNL1eJdt`).
- Subdirectorio `Notas_preferencias/multimedia/` para archivos adjuntos copiados (id: `1Np-hgEXF7PenohoEsJ4WhPBckBAWa5s1`).
- Carpeta de exportación WhatsApp: `WhatsApp_Export/` (id: `1l5uSqZlZ-6CxvzuU82aZ3xWks9Mn9hwi`).
- Acceso a mensajes de Telegram de Yolanda para lectura y envío de notificaciones.
- En flujo inicial: archivo `.zip` de WhatsApp disponible para extracción.

## Procedimiento para crear/actualizar documentos en Google Docs vía Composio

### Regla CRÍTICA para URLs clickables
**En Google Docs, las URLs SOLO son clickables si están en formato `[texto_visible](url)` (markdown link).**
Las URLs escritas como texto plano (ej: `https://...`) NO se convierten en hipervínculos automáticamente cuando el documento se crea vía API.
Toda URL debe ir envuelta en `[url](url)` para que Google Docs la renderice como link azul clickable.

### Formato correcto de cada fila en la tabla
Para adjuntos multimedia:
```
| fecha | título | texto descriptivo, [Adjunto: nombrearchivo.ext](https://drive.google.com/file/d/FILE_ID/view) |
```

Para URLs externas:
```
| fecha | título | texto descriptivo [https://www.instagram.com/...](https://www.instagram.com/...) |
```

### Método probado para crear documento con contenido (CREATE + UPDATE)
1. Crear un doc con contenido mínimo:
   ```python
   r, e = run_composio_tool("GOOGLEDOCS_CREATE_DOCUMENT_MARKDOWN", {
       "title": "NombreCategoria",
       "markdown": "# NombreCategoria"
   })
   doc_id = r.get("data",{}).get("documentId","")
   ```

2. Actualizar con el markdown completo (tablas, enlaces, etc.):
   ```python
   r2, e2 = run_composio_tool("GOOGLEDOCS_UPDATE_DOCUMENT_MARKDOWN", {
       "id": doc_id,  # campo se llama "id", NO "document_id"
       "markdown": markdown_completo
   })
   # Verificar: r2["data"]["replies"] debe tener muchas entradas
   ```

3. Mover a la carpeta Notas_preferencias/:
   ```python
   r3, e3 = run_composio_tool("GOOGLEDRIVE_MOVE_FILE", {
       "file_id": doc_id,
       "add_parents": "1yfcFSY2tc5g9Ys5Bwtv84uWWJNL1eJdt"
       # add_parents es STRING, no lista
   })
   ```

### ⚠️ Limitaciones conocidas con archivos multimedia en Drive

- **`GOOGLEDRIVE_UPLOAD_FROM_URL` con URLs de Google Drive**: NO FUNCIONA. Descarga la página de advertencia HTML de Google en lugar de la imagen real. Solo funciona con URLs públicas de sitios externos.
- **`GOOGLEDRIVE_COPY_FILE`**: Preserva el contenido tal cual (incluyendo contenido corrupto). No acepta `name` ni `parents` aunque la API los soporte.
- **No existe `GOOGLEDRIVE_RENAME_FILE`**: No se puede renombrar un archivo vía Composio.
- **Archivos subidos desde WhatsApp Export**: Pueden tener metadata `image/jpeg` pero contenido real `text/html` (si se subieron vía `UPLOAD_FROM_URL` desde Drive). Verificar con `imageMediaMetadata` en `GOOGLEDRIVE_GET_FILE_V2` — si tiene dimensiones reales, el contenido es genuino.

### 📌 Flujo correcto para multimedia

1. **El usuario sube los archivos directo a la carpeta multimedia** desde su dispositivo (arrastrando desde galería/explorador de archivos). NO usar "Copy to" de Drive.
2. El usuario usa el **nombre categorizado como prefijo**: `Categoria_nombreoriginal.ext`.
   Ejemplos: `Quilling_IMG-20250821-WA0002.jpg`, `Limpieza_Detox_IMG-20260101-WA0000.jpg`
3. Desde aquí se leen los archivos de multimedia con `GOOGLEDRIVE_FIND_FILE` y se obtienen sus `webViewLink`.
4. Se reconstruyen los documentos Google Docs con los links correctos.

### 🔄 Nombres de archivos multimedia
Formato: `Categoria_nombreoriginal.ext` (sin consecutivo numérico, solo prefijo de categoría)
- `Quilling_IMG-20250821-WA0002.jpg`
- `Limpieza_Detox_IMG-20260101-WA0000.jpg`
- `Recetas_IMG-20220112-WA0001.jpg`
- `Resina_IMG-20230318-WA0003.jpg`
- `Por_clasificar_VID-20230902-WA0013.mp4`

### Manejo de markdown grande en COMPOSIO_REMOTE_WORKBENCH
Cuando el markdown tiene pipes (`|`), emojis, o caracteres especiales:
- Codificar en base64 antes de pasar por el shell
- Escribirlo a un archivo en el sandbox (`/mnt/files/...`)
- Leerlo desde el código ejecutado en el workbench

```bash
# Codificar
B64=$(base64 -w0 archivo.md)
# En el workbench:
code_to_execute='import json, base64
md = base64.b64decode("'${B64}'").decode("utf-8")
# usar md normalmente
'
```

### IDs de archivos en Google Drive
Los IDs de Drive pueden ser largos (hasta ~44 caracteres). Siempre usar el ID completo, nunca truncado. Para obtener IDs completos, buscar archivos por nombre en lugar de depender de IDs pre-capturados.

## Procedimiento general (parser + Docs)

1. Detectar fuente de entrada: `WhatsApp ZIP` (carga inicial) o `Telegram` (día a día).
2. Extraer elementos procesables por mensaje: texto, URL, imagen/video/audio y fecha de recepción.
   IMPORTANTE: En el chat exportado de WhatsApp, los URLs y archivos adjuntos suelen venir
   en mensajes separados de su texto descriptivo (misma fecha, mismo remitente). Ejemplos:
     - URL primero, texto después:
       "14:30 - Yolanda: https://www.instagram.com/reel/..."
       "14:31 - Yolanda: Ejercicios"
     - Texto primero, URL después (al revés):
       "14:30 - Yolanda: Ejercicios"
       "14:31 - Yolanda: https://www.instagram.com/reel/..."
     - Adjunto primero, texto después:
       "14:30 - Yolanda: IMG-20220110-WA0000.jpg (archivo adjunto)"
       "14:31 - Yolanda: Fotos de la cena de navidad"
     - Texto primero, adjunto después:
       "14:30 - Yolanda: Fotos de la cena de navidad"
       "14:31 - Yolanda: IMG-20220110-WA0000.jpg (archivo adjunto)"
   En todos estos casos los mensajes deben FUSIONARSE en una sola entrada:
     - "Ejercicios https://www.instagram.com/reel/..."
     - "Fotos de la cena de navidad, Adjunto: IMG-20220110-WA0000.jpg"
   La fusión aplica SOLO cuando un mensaje contiene URL o "(archivo adjunto)"
   y el otro contiene solo texto (sin URL ni adjunto). Si ambos tienen URL,
   ambos tienen adjunto, o ambos tienen texto, se dejan como entradas separadas.
   En algunos casos la nota escrita se envía luego de un enlace, en otros casos el
   enlace se envía luego de la nota. En ambos casos, se debe asociar correctamente
   el contenido con ese enlace. En la nota es muy probable que lo primero que se
   escriba sea la categoría. Si no puedes deducirla, générala en un nuevo documento
   temporal `Por clasificar` y notifica a Yolanda para que la revise y mueva a la
   categoría correcta.
3. Generar un título corto descriptivo para cada elemento (máx 80 caracteres).
4. Deducir categoría dinámica usando contenido del texto y, si aplica, del enlace.
5. Buscar en `Notas_preferencias/` un Google Doc existente para esa categoría.
6. Si no existe, crear un documento nuevo con el nombre de la categoría en esa misma carpeta.
7. Agregar una nueva fila al final del documento (formato tabla) con los siguientes campos:

   **Título del elemento** (máx 80 caracteres).

   **Contenido / Enlace** — según el tipo de elemento:

   a) **Si es un enlace** (Instagram, YouTube, Facebook, Threads, etc.):
      - Envolver SIEMPRE en formato `[url_completa](url_completa)` para que sea clickable.
      - Ejemplo: `[https://www.instagram.com/p/abc123/](https://www.instagram.com/p/abc123/)`
      - Si hay texto descriptivo + enlace: `"Ejercicios [https://...](https://...)"`

   b) **Si es un archivo adjunto** (foto, video, documento, audio, ZIP):
      - El mensaje en el chat exportado contiene "(archivo adjunto)" después del nombre del archivo.
      - Los archivos deben estar en la carpeta `multimedia/` con el formato:
        `Categoria_nombrearchivo.ext` — ej: `Quilling_IMG-20250821-WA0002.jpg`, `Limpieza_Detox_IMG-20260101-WA0000.jpg`
        El usuario sube los archivos manualmente desde su dispositivo; desde aquí solo se reconstruyen los docs con los links.
      - En la celda: texto descriptivo + `[Adjunto: nombrearchivo.ext](link_drive)`.
      - Ejemplo: `Fotos de la cena de navidad, [Adjunto: IMG-20220110-WA0000.jpg](https://drive.google.com/file/d/xxx/view)`
      - Si no hay texto descriptivo: `[Adjunto: nombrearchivo.ext](link_drive)`.

   c) **Si es multimedia incrustable directamente** (imagen/video pequeño):
      incrustarlo en la celda.

   **Fecha de recepción.**

8. Mantener orden cronológico de inserción dentro de cada documento por fecha de recepción.
9. Si el flujo es carga inicial, acumular conteo por categoría y reportar resumen al finalizar.
10. Si el flujo es diario por Telegram, enviar confirmación inmediata a Telegram con:
    `nota recibida`, `título` y `categoría`.

## Resultado Esperado
- Cada nota queda clasificada en un único documento por categoría dentro de `Notas_preferencias/`.
- Cada documento mantiene su tabla con filas completas y ordenadas por fecha de recepción.
- TODAS las URLs (externas y adjuntos) son links clickables azules en formato `[url](url)`.
- Los archivos adjuntos se copian al subdirectorio multimedia con nombre categorizado y se referencian como enlace clickable.
- En carga inicial existe un conteo final de notas por categoría.
- En flujo diario, cada nota procesada dispara una notificación de confirmación en Telegram.

## Casos Especiales
- Si no se puede deducir categoría con confianza, usar categoría temporal `Por clasificar` y notificar.
- Si el enlace no es accesible, registrar igual con metadata disponible y marcar `enlace no verificable`.
- Si no hay multimedia (ni enlace ni imagen), dejar la columna en blanco.
- Si el ZIP de WhatsApp está corrupto o incompleto, reportar error y detener carga inicial.
- Si el mismo elemento llega repetido en corto intervalo, evitar duplicado exacto por hash/URL+fecha.
- Si falla escritura en Docs, reintentar una vez y, si persiste, reportar por Telegram.
- Cuando un mensaje contiene solo "(archivo adjunto)" sin texto adicional y sin formar par fusionable, se omite como entrada separada.
- Si `GOOGLEDOCS_CREATE_DOCUMENT_MARKDOWN` con markdown completo produce un doc vacío, hacer CREATE con contenido mínimo y UPDATE con el markdown completo.
- Para pasar markdown grande por shell, codificar en base64.

## Archivos de soporte:
En caso de que haga falta, se podrán tener los siguientes archivos de soporte en la carpeta de la skill:
- `docs.md`: Reglas de categorización, ejemplos de títulos cortos y formato de filas por tipo de contenido.
- `scripts/`: Extractor de ZIP de WhatsApp, parser de mensajes, deduplicador de notas y cargador a Docs.
- `references/`: Taxonomía inicial sugerida, mapeo de fuentes (Instagram/YouTube/TikTok) y checklist de validación.
