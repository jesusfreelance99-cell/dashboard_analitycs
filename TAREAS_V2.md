# Dashboard v2 — Lista de tareas

## VISTA GENERAL

### ✅ Completado
- [x] Quitar saludo ("Buenos días, Daniel...")
- [x] Conectar DateToolbar al overview (filtro 7D/30D/90D)
- [x] Selector de plataforma: Ambas tiendas / iOS / Android
- [x] Tienda y descargas: dejar solo Impresiones + Descargas únicas + Rating (quitar "Descargas repetidas" y "Tasa de conversión")
- [x] Ingresos: dividir en 3 sub-grupos (Pruebas gratuitas / Suscripciones / Ingresos)
- [x] Plan Pro usa RevenueCat como fuente de verdad (no Firebase)
- [x] MRR con desglose mensual × $4.99 + anual × $1.67
- [x] Quitar "Nuevos clientes" y "Clientes activos" (posible data sandbox)
- [x] Usuarios: agregar cards iOS / Android
- [x] Embudo de conversión resumen (7 barras: Descarga→Suscripción)
- [x] Retención y cancelaciones (4 cards: Cancelaciones / % Churn / Day 3 / Week 1)
- [x] Distribución geográfica: solo lista de países (quitar "Distribución por plan")
- [x] Integración Play Store (Cloud Function + modelo + servicio)
- [x] Distribución geográfica con GeoDonutPanel (donut + filtro continente + paginación) compartido con pestaña Usuarios
- [x] Fix Colombia: overview usa UserModel.fromFirestore() — resuelve país por address → locale → currency
- [x] Sección "Tendencias": las gráficas de "Descargas por día" y "Revenue por día" no existen en el código actual

---

## EMBUDO

### ✅ Completado
- [x] Filtro 7D/30D/90D (ya existía, mantener)

### ✅ Completado
- [x] Quitar secciones irrelevantes (Usuarios Pro/Free, Conversión Pro, Sesiones iOS/Android, Tabla 30 eventos, Dispositivos, Gráfica Nuevos usuarios)
- [x] Fila de 6 cards: Descargas | Abrieron la app | Iniciaron onboarding | Llegaron a paywall | Free trial | Conversión directa
- [x] Card destacada: % de conversión del free trial (suscripciones ÷ trials iniciados)
- [x] Embudo de 6 pasos detallados: primera apertura → onboarding → registro → paywall → trial → suscripción
- [x] Sección "Estado de Trials" con 4 cards RevenueCat (total / activos / cancelados / % cancelados)

### ✅ Completado
- [x] Sub-detalle colapsable implementado: Cloud Function consulta GA4 por `customEvent:step_name`, modelo y UI listos — mostrará datos automáticamente cuando el parámetro esté registrado en GA4

---

## RETENCIÓN

### ✅ Completado
- [x] Curva de retención (gráfica de línea vs benchmark)
- [x] Cards "Aperturas de usuarios nuevos" y "Aperturas de usuarios recurrentes" con sparkline + texto explicativo
- [x] Duración de sesión (gráfica de línea)
- [x] Filtro 7D/30D/90D/Todo implementado
- [x] 4 cards D1/D2/D7/D30 con benchmark de la industria
- [x] Sin header duplicado
- [x] Gráfica "Nuevos vs Recurrentes" eliminada (solo quedan las 2 cards numéricas)
- [x] Nota de outlier en Duración de sesión cuando máximo > 15 min

---

## USUARIOS

### ✅ Completado
- [x] Filtro 7D/30D/90D (ya existía)
- [x] Distribución geográfica con donut + filtro por región + paginación de 16 países
- [x] Header duplicado eliminado
- [x] Cards reorganizadas en sub-grupos: Activos | Gratuitos | Free Trial (activo/cancelado) | Plan Activo (Mensual/Anual/No renovarán)
- [x] Columnas tabla: País(flag) | Correo | Producto | Comprado | Expira | Revenue | Tipo(pill) | Renovación(pill)

---

## TRANSVERSAL / BUGS A RESOLVER

- [ ] **Unificar "suscripciones de pago activas"** — hay 3 números distintos para la misma métrica:
  - 12 → RevenueCat overview `active_subscriptions`
  - 34 → Embudo, "Conversión Pro" (Firebase, acumulado histórico)
  - 41 → Vista General "Plan Pro" (Firebase, total con plan='pro')
  - **Decisión**: usar RevenueCat como fuente de verdad en todas las pestañas
- [x] **Fix MRR**: ahora muestra `computed_mrr` (mensual×$4.99 + anual×$1.67) cuando hay desglose disponible, en vez del MRR de la API RevenueCat
- [x] **"Nuevos clientes" y "Clientes activos"** de RevenueCat — ya no se muestran en ninguna pantalla
- [ ] **Calcular cohortes de retención** (D1/D2/D7/D30) — actualmente no existe esta lógica, hay que crearla en una Cloud Function o en el servicio de retención
- [ ] **Deploy de las Cloud Functions de Play Store** (`updatePlayStoreMetrics` + `refreshPlayStoreMetrics`) — después de `firebase deploy --only functions`, habilitar las APIs en Google Cloud:
  - Google Play Android Developer API
  - Google Play Developer Reporting API
- [ ] **Confirmar eventos Firebase del embudo** con Jesús:
  - Paso 2 (App abierta): ¿`first_open` o `app_open`? Hay 2 eventos similares
  - Paso 4 (Login): ¿`Sesión iniciada` (424/295) o `Inicio de sesión` (19/14)?
  - Paso 3 (Onboarding): confirmar los `step_name` reales que manda la app para el sub-detalle

---

## ORDEN SUGERIDO PARA IMPLEMENTAR LO PENDIENTE

1. Fix bugs transversales (MRR, fuente de verdad suscripciones)
2. Embudo — quitar secciones que no corresponden + fila de 6 cards + embudo 8 pasos
3. Retención — header + filtro 7D/30D/90D + cards cohorte D1/D2/D7/D30
4. Usuarios — header + reorganizar cards en sub-grupos + nuevas columnas de tabla
5. Vista General — distribución geográfica con donut + fix Colombia
