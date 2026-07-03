# SKILL: `guardar_notas_telegram_Googledocs.md`

## ¿Qué hace esta skill?
Identifica y organiza enlaces, notas y archivos multimedia desde dos fuentes posibles:
1. Chat histórico exportado desde WhatsApp 
2. Mensajes directos enviados a Telegram desde instagram, youtube, u otro.
Los organiza en documentos, uno por cada categoria, en google docs, clasificandolos en el doumento por fecha (en el orden de recepción).  

## ¿Qué input necesita el agente?
El agente procesará la información a través de dos flujos exclusivos de entrada:
1. **Notas históricas para la Carga Inicial:** Archivo `.zip` exportado desde WhatsApp (con archivos multimedia adjuntos) para extraer y estructurar el pasado de varios años.
2. **Notas varias hacia Telegram:** Mensajes entrantes en tiempo real en la cuenta de Telegram de Yolanda (enlaces compartidos desde Instagram, YouTube, TikTok, fotos directas, notas de texto o notas de voz).

## ¿Qué sabe ya el agente?
- Conoce y ya ha utilizado la conexión a través de Composio que está en TOOLS.md para google docs.
- Sabe que estamos en un servidor VPS con acceso a la cuenta yolanda.4geeks@gmail.com para el uso de las herramientas de google.
- Tiene una regla en la que debe preguntarme si puede modificar un archivo a menos que yo se lo solicite previamente (Nota: esto debo ver como funciona porque me va a preguntar a cada rato) 

## ¿Cómo es un buen output?

### 1. Archivo de Salida en Google Drive:

* **Ubicación:** Carpeta en el directorio raíz del Drive de Yolanda.4geeks: 
 `/Notas-preferencias/` .
* **Organización:** Un solo documento de Google Docs por cada categoría deducida dinámicamente por la IA a partir de la nota recibida o el contenido del enlace (ej. *Ejercicios Asiáticos*, *Limpieza de Ollas*, *Quilling*). Si el documento ya existe, la nueva nota se agrega al final del mismo.
* **Estructura interno de los documentos por Categoria:** Formato Tabla, con textos concisos según el siguiente formato:

| Elemento | Especificación del Contenido |
| :--- | :--- |
| **Título del Elemento** | Nombre corto descriptivo deducido de la nota recibida (ej. *"Técnica de filigrana para marcos"*). |
| **Multimedia** | Archivo visual (foto/video) incrustado directamente en el documento. |
| **Enlace de Origen** | URL (hipervinculo que pueda darse click para ir directo a la aplicación (Instagram, YouTube, etc). |
| **Categoría** | La categoria deducida (debe ser la misma para todos los elementos del mismo documento). |
| **Fecha Recepción** | La fecha en que se recibió la nota y se agreguó al documento. |

### 2. ¿Cómo se sabe que funcionó?
- Para la historia de carga inicial, solo se hará un conteo de cuantas notas se ingresaron por cada categoria y se podrá ver el resultado en google drive.
- Para las notas varias del dia a dia, cada vez que procese una nota debe enviar a telegram de Yolada una notificación indicando nota recibida, titulo y categoria 
