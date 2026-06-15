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

### ⏳ Pendiente
- [ ] **Distribución geográfica**: reutilizar el componente de la pestaña Usuarios (con donut + paginación + filtro América/Europa/Asia/Otros) en vez de la lista simple actual
- [ ] **Fix Colombia**: en Vista General aparece con ~16 usuarios, debería ser ~163 (69.1%) — revisar lógica de agrupación en CountryMetricsService
- [ ] **Sección "Tendencias"**: quitar las gráficas fijas de "Descargas por día" y "Revenue por día" (si aún existen) — reemplazar por modal al hacer click en las cards "Descargas únicas" y "MRR"

---

## EMBUDO

### ✅ Completado
- [x] Filtro 7D/30D/90D (ya existía, mantener)

### ⏳ Pendiente
- [ ] **Quitar del embudo** estas secciones que no corresponden aquí:
  - "Usuarios" (Pro 16% / Free 84%) — ya está en Vista General
  - "Conversión Pro 15.5%" — reemplazar por % de conversión del free trial
  - "Sesiones iOS/Android" — ya está en Vista General → Usuarios
  - "Trials activos: 23" — ya está en Vista General → Ingresos
  - "Flujo de conversión" de 4 cards (Registrados→Paywall→Trial→Pro) — sustituir por el embudo de 8 pasos
  - Tabla "Eventos" completa de 30 eventos — integrar solo los 7 relevantes en el embudo
  - "Dispositivos activos" (lista de modelos) — no es parte del embudo
  - Gráfica "Nuevos usuarios" (pertenece a Retención)
- [ ] **Fila de 6 cards** con números absolutos + % debajo:
  - Descargas (App Store Connect)
  - Abrieron la app (evento `first_open` o `app_open`)
  - Iniciaron onboarding
  - Llegaron a la paywall (%)
  - Iniciaron free trial (%)
  - Conversión directa mensual (sin trial, plan mensual)
- [ ] **Card destacada**: % de conversión del free trial = suscripciones vía trial ÷ trials iniciados
- [ ] **Embudo de 8 pasos detallado** (evento Firebase + nombre en español + ocurrencias + únicos + % vs paso anterior):
  - 1. Descarga (`app_downloaded` — dato App Store Connect)
  - 2. App abierta (`first_open` / `app_open`)
  - 3. Onboarding completado (`onboarding_step_completed`)
  - 4. Login (`login_completed` — confirmar cuál de los 2 eventos de Firebase)
  - 5. Paywall vista (`paywall_viewed` — ya existe: "Vio el paywall" 273/210)
  - 6. Free trial iniciado (`trial_started` — ya existe: "Inició período de prueba" 32/30)
  - 7. Suscripción comprada (`subscription_purchased` — ya existe: "Purchase" 93/45)
- [ ] **Sub-detalle colapsable** dentro del paso 3 (Onboarding): desglose por `step_name` con conteo real de cada pantalla — Jesús debe confirmar los step_name reales que manda la app

---

## RETENCIÓN

### ✅ Completado
- [x] Curva de retención (gráfica de línea vs benchmark)
- [x] "Usuarios nuevos" y "Recurrentes" (cards con sparkline)
- [x] "Duración de sesión" (gráfica de línea)

### ⏳ Pendiente
- [ ] **Header**: quitar el header duplicado (aparece "Retención" 2 veces) — dejar solo título + subtítulo "Cuántos usuarios vuelven a abrir la app"
- [ ] **Agregar filtro 7D/30D/90D** (actualmente esta pestaña no tiene ningún filtro de fechas)
- [ ] **4 cards de retención por cohorte** (D1 / D2 / D7 / D30) con benchmark de la industria junto a cada una:
  - D1: 100% (punto de partida)
  - D2: % que vuelve el día siguiente — benchmark ~40%
  - D7: % que vuelve a los 7 días — benchmark ~15%
  - D30: % que vuelve a los 30 días (destacada) — benchmark ~8%
  - Esto requiere **calcular cohortes** en Firestore — actualmente la card dice "Sin datos de cohorte"
- [ ] **Renombrar cards**: "Usuarios nuevos" → "Aperturas de usuarios nuevos" y "Recurrentes" → "Aperturas de usuarios recurrentes" + agregar texto explicativo: "Nuevos = primera vez que ese usuario abre Trevo. Recurrentes = usuarios que ya habían usado la app y volvieron a abrirla"
- [ ] **Quitar gráfica** "Nuevos vs Recurrentes" (área apilada con toggles) — dejar solo las 2 cards numéricas que ya existen; la gráfica duplica la misma info
- [ ] **Nota en "Duración de sesión"**: si el máximo > 15 min, advertir que es probable outlier (app en segundo plano) y filtrar sesiones anormales antes de mostrar el promedio

---

## USUARIOS

### ✅ Completado
- [x] Filtro 7D/30D/90D (ya existía)
- [x] Distribución geográfica con donut + filtro por región + paginación de 16 países

### ⏳ Pendiente
- [ ] **Header**: quitar header duplicado — dejar solo "Usuarios" + subtítulo "Todos los usuarios registrados en Trevo"
- [ ] **Reorganizar las cards** en sub-grupos:
  - (sola) Usuarios activos — total con actividad en el período
  - (sola) Usuarios gratuitos — total − Plan Pro
  - **Sub-grupo "Free trial"**:
    - Free trial total (histórico)
    - Free trial activo (actualmente en prueba)
    - Free trial cancelado (destacada en rojo)
  - **Sub-grupo "Plan activo"**:
    - Plan activo · Mensual
    - Plan activo · Anual
    - No renovarán el próximo mes (destacada) — cancelaron renovación futura, siguen con acceso hasta que venza
- [ ] **Cambiar columnas de la tabla** de usuarios:
  - Quitar: "Usuario" (avatar+nombre, casi siempre vacío), "Estado" (100% Activo, no aporta)
  - Agregar: País | Correo | Producto (Mensual/Anual/Free) | Comprado (hace cuánto) | Expira (fecha o "prueba") | Revenue ($) | Tipo (pill: NEW SUB/TRIAL/TRIAL CANCELADO/FREE) | Renovación (pill: CANCELÓ FUTURAS SUSCRIPCIONES si aplica)

---

## TRANSVERSAL / BUGS A RESOLVER

- [ ] **Unificar "suscripciones de pago activas"** — hay 3 números distintos para la misma métrica:
  - 12 → RevenueCat overview `active_subscriptions`
  - 34 → Embudo, "Conversión Pro" (Firebase, acumulado histórico)
  - 41 → Vista General "Plan Pro" (Firebase, total con plan='pro')
  - **Decisión**: usar RevenueCat como fuente de verdad en todas las pestañas
- [ ] **Fix MRR**: sale $80 pero con 28 mensuales × $4.99 + 13 anuales × ($19.99/12) debería ser ~$161 — confirmar si los precios en RevenueCat son distintos o si el split mensual/anual real es otro
- [ ] **Investigar / eliminar** "Nuevos clientes 566" y "Clientes activos 569" — no cuadran con ningún otro dato (solo hay 236 registrados y ~34 descargas recientes) — posiblemente data de sandbox de RevenueCat; no mostrar hasta confirmar fuente
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
