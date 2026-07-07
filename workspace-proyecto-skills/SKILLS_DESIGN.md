# DISEÑO (ESPECIFICACIONES) DE DOS SKILLS

## SKILL 01: `guardar-notas-telegram-Googledocs.md`

### ¿Qué hace esta skill?
Identifica y organiza enlaces, notas y archivos multimedia desde dos fuentes posibles:
1. Chat histórico exportado desde WhatsApp 
2. Mensajes directos enviados a Telegram desde instagram, youtube, u otro.
Los organiza en documentos, uno por cada categoria, en google docs, clasificandolos en el doumento por fecha (en el orden de recepción).  

### ¿Qué input necesita el agente?
El agente procesará la información a través de dos flujos exclusivos de entrada:
1. **Notas históricas para la Carga Inicial:** Archivo `.zip` exportado desde WhatsApp (con archivos multimedia adjuntos) para extraer y estructurar el pasado de varios años.
2. **Notas varias hacia Telegram:** Mensajes entrantes en tiempo real en la cuenta de Telegram de Yolanda (enlaces compartidos desde Instagram, YouTube, TikTok, fotos directas, notas de texto o notas de voz).

### ¿Qué sabe ya el agente?
- Conoce y ya ha utilizado la conexión a través de Composio que está en TOOLS.md para google docs.
- Sabe que estamos en un servidor VPS con acceso a la cuenta yolanda.4geeks@gmail.com para el uso de las herramientas de google.
- Tiene una regla en la que debe preguntarme si puede modificar un archivo a menos que yo se lo solicite previamente (Nota: esto debo ver como funciona porque me va a preguntar a cada rato) 

### ¿Cómo es un buen output?

#### 1. Archivo de Salida en Google Drive:

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
| **Fecha Recepción** | La fecha en que se recibió la nota y se agregó al documento. |

#### 2. ¿Cómo se sabe que funcionó?
- Para la historia de carga inicial, solo se hará un conteo de cuantas notas se ingresaron por cada categoria y se podrá ver el resultado en google drive.
- Para las notas varias del dia a dia, cada vez que procese una nota debe enviar a telegram de Yolada una notificación indicando nota recibida, titulo y categoria 


## SKILL 02: `flujo-caja-personal.md`

### ¿Qué hace esta skill?
Administra el flujo de caja personal (ingresos, gastos, cuentas por pagar y gastos con vencimientos fijos) a través de comandos específicos de Telegram, actualizando matrices de control en Google Docs/Sheets y programando recordatorios automáticos en Google Calendar. Tambien responde un panorama de pagos estimados a 30 dias con el comando "Flujo de Caja".

### ¿Qué input necesita el agente?
El agente procesará el flujo de caja mediante 5 disparadores (comandos) en el chat de Telegram:
1. **Comando "Gasto" + texto + Foto:** Una imagen de la factura o recibo acompañada de la palabra "Gasto" en alguna parte del texto. Puede ser que se omita la foto
2. **Comando "CxP" o "Pago CxP" + Texto:** Un mensaje de texto con la estructura: `CxP [Concepto] [Monto]`.  Esto sería una promesa eventual de pago.
3. **Comando "Ingreso" + Texto:** Un mensaje con el monto recibido en Bolívares (Bs) para activar el motor de sugerencias.
4. **Tabla Base de Gastos Fijos:** Un documento inicial que se define con los gastos mensuales recurrentes y sus días y montos aproximados de pago.
5. **Comando "Flujo de Caja":** Solicita por Telegram el listado de pagos estimados de los proximos 30 dias, ordenados por fecha, con detalle y monto.

### ¿Qué sabe ya el agente?
- Conoce y ya ha utilizado la conexión a través de Composio que está en TOOLS.md para las herramientas de google, bajo la cuenta yolanda.4geeks@gmail.com.
- Sabe que estamos en un servidor VPS con acceso a la cuenta yolanda.4geeks@gmail.com para el uso de las herramientas de google.
- Tiene una regla en la que debe preguntarme si puede modificar un archivo a menos que yo se lo solicite previamente (Nota: esto debo ver como funciona porque me va a preguntar a cada rato) 
- Sabe naturalmente, extraer datos de imágenes (montos, comercios, fechas).
- Tiene acceso de escritura a mi Google Drive y Google Calendar.

### ¿Cómo es un buen output?

#### 1. Estructura y Destino en Google Drive (El Tablero de Control)
El agente mantendrá un archivo matriz (puede ser un Google Doc estructurado o una Hoja de Cálculo) en la carpeta `/Finanzas_Personales/` con tres tablas de proceso bien definidas:

* **Tabla A: Registro de Ingresos, Gastos y Facturas (Histórico)**
  * *Columnas:* Fecha | Concepto/Comercio | Monto | Enlace a la Factura (archivada automáticamente en Drive).
* **Tabla B: Cuentas por Pagar (Deudas Activas - CxP)**
  * *Columnas:* Fecha de Registro | Fecha Compromiso de pago | Concepto | Monto | Estado (Pendiente / Pagado) | Alerta en Calendar (Sí/No).
* **Tabla C: Planificador de Gastos Fijos Mensuales**
  * *Columnas:* Día Aprox. | Descripción | Monto Estimado | Alerta en Calendar (Sí/No).

#### 2. Automatización en Google Calendar (Recordatorios)
Al leer la "Tabla Base de Gastos Fijos", el agente creará automáticamente eventos de recordatorio en Google Calendar 2 o 3 días antes de la fecha aproximada. 
* *Ejemplo de evento:* `⏰ Recordatorio: Pago de Condominio (Aprox. Día 10)`.

### ¿Cómo se sabe que funcionó?

- Notificaciones en Telegram

* **Al recibir un Gasto o CxP o Pago de CxP:** El agente procesa el flujo y confirma con un mensaje en telegram:

  ✅ Registro Exitoso:
  * Tipo: Gasto (Factura Archivada) / Cuenta por Pagar / Pago de una CxP
  * Concepto: Repuestos Oficina / Deuda con proveedor
  * Monto: [Monto detectado]

* **Al recibir un Ingreso:** El agente procesa el flujo y sugiere la proxima cuenta a pagar por Telegram:

* **Solicitud de Saldo:** En cualquier momento se puede solicitar el saldo al agente y éste lo responde en Telegram

* **Solicitud de Flujo de Caja:** En cualquier momento se puede solicitar "Flujo de Caja" y el agente responde en Telegram con pagos estimados de los proximos 30 dias, ordenados por fecha, indicando detalle de cada pago y monto.

