---
name: "flujo-caja-personal"
description: "Con mensajes recibidos en Telegram que contienen Gasto, CxP, Ingreso, Pago CxP, Saldo o Flujo de Caja, gestiona el flujo de caja personal"
---

# Habilidad: Flujo de caja personal

## Descripción
Gestiona ingresos, gastos, cuentas por pagar y saldo personal a partir de comandos en Telegram, actualizando el tablero en Google Drive y generando recordatorios en Google Calendar.

## Cuándo Usar
Activar solo cuando llegue un mensaje de Telegram con alguno de estos disparadores:
- `Gasto` + texto, con o sin foto del recibo/factura.
- `CxP` + texto con estructura `CxP [Concepto] [Monto]`.
- `Pago CxP` + texto para marcar deuda como pagada.
- `Ingreso` + texto con monto recibido en Bs.
- `Saldo` para consultar estado actual del flujo.
- `Flujo de Caja` para consultar pagos estimados de los proximos 30 dias.

Tambien activar cuando se provea/actualice la Tabla Base de Gastos Fijos para sincronizar recordatorios en Calendar.

## Prerrequisitos
- Acceso a mensajes de la cuenta de Telegram objetivo.
- Conexion operativa via Composio para Google Docs/Sheets, Drive y Calendar.
- Permisos sobre la cuenta `yolanda.4geeks@gmail.com` en VPS.
- Carpeta de trabajo en Drive: `/Finanzas_Personales/`.
- Archivo matriz existente o permiso para crearlo (Doc o Sheet) con 3 tablas:
  - Tabla A: Registro de Gastos y Facturas.
  - Tabla B: Cuentas por Pagar (CxP).
  - Tabla C: Gastos Fijos Mensuales.

## Procedimiento
1. Detectar tipo de comando desde el mensaje (`Gasto`, `CxP`, `Pago CxP`, `Ingreso`, `Saldo`, `Flujo de Caja`).
2. Normalizar datos minimos: fecha de registro, concepto, monto, moneda, estado y evidencia (si hay imagen).
3. Si es `Gasto`:
	- Extraer texto de la imagen si existe (monto, comercio, fecha aproximada).
	- Guardar imagen en Drive y obtener enlace.
	- Registrar fila en Tabla A: Fecha | Concepto/Comercio | Monto | Enlace a Factura.
4. Si es `CxP`:
	- Registrar fila en Tabla B con Estado `Pendiente`.
	- Crear alerta opcional en Calendar si se detecta fecha objetivo.
5. Si es `Pago CxP`:
	- Ubicar la deuda activa correspondiente en Tabla B.
	- Cambiar Estado a `Pagado` y actualizar marca de alerta.
6. Si es `Ingreso`:
	- Registrar el ingreso en el tablero (seccion de control o hoja de movimientos).
	- Calcular sugerencia de proximo pago priorizando CxP pendientes y vencimientos proximos.
	- Enviar sugerencia por Telegram.
7. Si es `Saldo`:
	- Calcular saldo usando ingresos menos gastos y compromisos pendientes.
	- Responder por Telegram con resumen claro.
8. Si es `Flujo de Caja`:
	- Construir lista de pagos estimados de los proximos 30 dias a partir de Tabla C (gastos fijos) y CxP pendientes con fecha objetivo.
	- Ordenar la lista por fecha ascendente.
	- Responder por Telegram con: fecha estimada, detalle/concepto del pago y monto por cada item.
9. Al leer/actualizar Tabla C (gastos fijos):
	- Crear o actualizar eventos en Google Calendar 2 o 3 dias antes del dia aproximado de pago.
	- Marcar en la tabla que la alerta fue gestionada.
10. En todos los comandos operativos, enviar confirmacion en Telegram con Tipo, Concepto y Monto.

## Resultado Esperado
- El tablero en `/Finanzas_Personales/` queda actualizado en la tabla correcta sin duplicados indebidos.
- Las facturas de gastos quedan archivadas en Drive con enlace trazable.
- Las CxP reflejan estado real (`Pendiente` o `Pagado`).
- Los recordatorios de gastos fijos existen en Calendar con antelacion de 2 o 3 dias.
- Telegram recibe confirmacion de cada accion y respuesta para consultas de saldo.
- Al solicitar `Flujo de Caja`, Telegram devuelve el plan de pagos estimados de los proximos 30 dias, ordenado por fecha con detalle y monto.

## Casos Especiales
- Si falta monto o concepto en `CxP`/`Gasto`, solicitar aclaratoria antes de registrar.
- Si llega `Pago CxP` sin coincidencia unica, listar deudas pendientes y pedir seleccion.
- Si OCR de factura falla, registrar con datos del texto del usuario y marcar `pendiente de validar`.
- Si no existe tablero matriz, crearlo en `/Finanzas_Personales/` con las 3 tablas base.
- Si falla Calendar o Drive, confirmar error por Telegram y reintentar una vez antes de escalar.
- Si el mensaje no contiene un disparador valido, no ejecutar la skill.
- Si `Flujo de Caja` no tiene pagos estimados en ventana de 30 dias, responder explicitamente que no hay pagos proyectados en ese periodo.

## Archivos de soporte:
En caso de que haga falta, se podrán tener los siguientes archivos de soporte en la carpeta de la skill:
- `docs.md`: Reglas de interpretacion de comandos, ejemplos de mensajes, politicas de deduplicacion.
- `scripts/`: Utilidades para parseo de montos, OCR de facturas y sincronizacion Calendar.
- `references/`: Plantillas de tabla matriz, catalogo de categorias de gasto, checklist de cierre mensual.
