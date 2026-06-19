# Contexto de diseño: Módulo Embudo de Onboarding

> Referencia estricta: `remixed-5f6b3dec.html` · Sección `#page-fn`  
> Usar este archivo como guía visual y funcional para la implementación en Flutter.

---

## 1. Layout general del módulo Embudo (`#page-fn`)

### Filtros en la parte superior
```
[ 7D ] [ 30D ] [ 90D ]   [input fecha inicio] → [input fecha fin]   [Aplicar]
```
- Pills de rango: background `var(--bg)`, padding 4px, border-radius 12px
- Botón activo: `background: var(--accent)` (#fd386f), color blanco
- Input fecha: font-size 12px, padding 7px 10px, border-radius 10px, background `var(--bg)`

### Cards KPI — primera fila (3 columnas)
| Label | Value | Subtext |
|---|---|---|
| Descargas | `fn-base` | período: 30 días |
| Abrieron la app | `fn-opened` | llegaron a bienvenida |
| Iniciaron onboarding | `fn-onb` | % relativo |

### Cards KPI — segunda fila (3 columnas)
| Label | Value | Subtext |
|---|---|---|
| Llegaron a la paywall | 49% | 267 usuarios |
| Iniciaron free trial | 18% | 98 usuarios |
| Conversión directa mensual | 8 | sin trial · plan mensual |

### Card destacada (full width, `accent-card`)
- Background: `var(--accent-tint)` (#fdebf0 en light / #2c1a20 en dark)
- Label: "% de conversión del free trial"
- Valor grande: `fn-trial-conv` (e.g., 40%)
- Subtext: "39 suscriptores · de 98 trials iniciados"

---

## 2. Componente Embudo Detallado — `.card` con pasos

### Cabecera de la card
```
Embudo completo · eventos [Badge morado "Mixpanel" o "Firebase"]
```

### Estructura de cada paso (`.fstep`)
```
[num] [event_code]  [label_es]      [count]  [unique]     [pct%]
      ████████████████████████████████████████  ← barra de progreso (14px altura)
      (−18%) abandono respecto al paso anterior  ← fdrop, color danger, debajo de barra
```

#### CSS/Flutter equivalencias:
- `.fstepnum` → `Text('${step.num}', color: AppColors.ink3, fontSize: 12)`, width fijo 16px
- `.fname code` → `Text(eventCode, fontFamily: 'monospace', fontWeight: w700, fontSize: 12)`
- `.fname-es` → `Text(labelEs, color: AppColors.ink2, fontSize: 13)`
- `.fcount` → `Text('$count', fontWeight: w700, fontSize: 15)`, minWidth 50, right-aligned
- `.funiq` → `Text('$unique únicos', color: AppColors.ink3, fontSize: 12)`, minWidth 90, right
- `.fpct` → `Text('$pct%', color: AppColors.ink3, fontSize: 12)`, minWidth 46, right
- `.fbarwrap` → `LinearProgressIndicator` height 14, background AppColors.progressBg, radius 7
- `.fbar` → color varía por paso (ver paleta abajo)
- `.fdrop` → `Text('(−X%) abandono', color: AppColors.danger, fontSize: 12)`, aparece debajo de barra

#### Paleta de colores por paso (basada en el HTML):
```
Paso 1 (Descarga):       #0d1b2a  → AppColors.ink (baseline oscuro)
Paso 2 (App abierta):    #3b8ee8  → AppColors.chartBlue
Paso 3 (Onboarding):     #1aa974  → AppColors.chartGreen
Paso 4 (Login):          #e0507f  → AppColors.pink
Paso 5 (Paywall):        #f5a524  → AppColors.chartAmber
Paso 6 (Trial):          #e8503e  → AppColors.danger
Paso 7 (Suscripción):    #6aa83f  → AppColors.success
```
Para 15 pasos de quiz: rotar entre chartBlue, chartGreen, chartPurple, pink, chartAmber.

### Sub-detalle colapsable (onboarding steps / respuestas)
```
▾ Detalle por step_name   ← toggle, onTap colapsa/expande
  [substep_name]    ████████░░░░░░░░  [count]
  ...
```
- `.fsub` → `Padding(left: 20, child: Column(...))` con borde izquierdo 2px solid AppColors.border
- `.fsublabel` → `Text('Detalle por step_name', color: AppColors.ink3, fontSize: 11)`
- `.substep` → `Row(children: [name(flex:1), barraProgreso(width:140), count(min:40, right)])`
- `.ssbar` → color #3b8ee8 → AppColors.chartBlue, height 6, radius 4

---

## 3. Módulo Onboarding Quiz (BigQuery) — DISEÑO NUEVO

### Fuente de datos
- **Tabla BigQuery**: `trevo-ia.{BIGQUERY_DATASET_ID}.events_*`
- **Evento de llegada**: cada paso dispara su propio event_name (`onboarding_step_1` … `onboarding_step_15`)
  - Sin parámetros adicionales de paso — el número de paso está en el nombre del evento
- **Evento de respuesta**: `event_name = 'onboarding_answer'`
  - params: `question_key` (STRING), `answer_selected` (STRING)
  - Multi-select (Q9, Q12): `answer_selected` llega como `"Opción A|Opción B"` — separar por `|`
  - Info steps: `answer_selected = 'info_continued'`, `'voice_demo_completed'` o `'completed'` — excluir
- **Evento de completado**: `onboarding_completed` (señal de fin del quiz, sin params relevantes)

### Los 15 pasos del quiz

| # | event_name Firebase | question_key | Pregunta en español | Tipo |
|---|---|---|---|---|
| 1 | onboarding_step_1 | spending_concern | ¿Con qué frecuencia sientes que tu dinero desaparece? | slider |
| 2 | onboarding_step_2 | money_relationship | ¿Cómo describes tu relación con el dinero? | selección |
| 3 | onboarding_step_3 | main_difficulty | ¿Cómo llegas normalmente a fin de mes? | slider |
| 4 | onboarding_step_4 | trevo_impact | Pantalla de impacto Trevo (informativa) | **info** |
| 5 | onboarding_step_5 | currency_selection | ¿Alguna vez has intentado controlar tus gastos? | selección |
| 6 | onboarding_step_6 | banking_status | ¿Qué pasó con ese intento? | selección |
| 7 | onboarding_step_7 | voice_intro | Demo de registro por voz | **info** |
| 8 | onboarding_step_8 | budget_interest | Pantalla "Así de simple registra Trevo" (informativa) | **info** |
| 9 | onboarding_step_9 | debt_status | ¿En qué se va normalmente tu plata? | **multi-select** |
| 10 | onboarding_step_10 | investment_interest | ¿Tienes suscripciones que no usas mucho? | selección |
| 11 | onboarding_step_11 | subscriptions_tracker | Pantalla de suscripciones invisibles (informativa) | **info** |
| 12 | onboarding_step_12 | plan_selection | ¿Qué te gustaría lograr con Trevo? | **multi-select** |
| 13 | onboarding_step_13 | account_setup | ¿Qué tan listo estás para tomar el control? | slider |
| 14 | onboarding_step_14 | user_reviews | Pantalla de reseñas de usuarios (informativa) | **info** |
| 15 | onboarding_step_15 | personalization | Pantalla de personalización — animación final (informativa) | **info** |

Pasos **info** (4, 7, 8, 11, 14, 15): no mostrar distribución de respuestas.
Multi-select (9, 12): separar por `|` para contar cada opción individualmente.

### KPI Cards superiores (4 cards)
| Label | Valor | Subtext |
|---|---|---|
| Iniciaron quiz | totalStarted | paso 1 · onboarding_step |
| Completaron quiz | totalCompleted | paso 15 · personalization |
| % completación | completionRate% | completados / iniciados |
| Mayor abandono | "Paso N: step_name" | −X% drop-off |

### Funnel de 15 pasos
- Igual al embudo HTML pero con 15 filas
- Baseline = usuarios paso 1
- `pct%` = unique_users_step_N / unique_users_step_1
- `drop_pct` = (unique_step_N − unique_step_{N+1}) / unique_step_N (se muestra entre pasos)
- El paso con mayor `drop_pct` se resalta en rojo (badge o color distinto)
- Pasos con respuestas: expandibles para mostrar distribución

### Distribución de respuestas (expandible por paso)
```
[Respuesta A]  ████████████████░░░░░░  45%  (N usuarios)
[Respuesta B]  ████████░░░░░░░░░░░░░░  30%  (N usuarios)
[Respuesta C]  ████░░░░░░░░░░░░░░░░░░  15%  (N usuarios)
[Otra]         ██░░░░░░░░░░░░░░░░░░░░  10%  (N usuarios)
```

---

## 4. Patrones visuales del HTML a respetar en Flutter

### Colores del tema (mapeados a AppColors)
```
var(--bg)       → Theme.of(context).colorScheme.surface / AppColors.white
var(--bg2)      → AppColors.fieldBg
var(--bg3)      → AppColors.background
var(--text)     → AppColors.ink
var(--text2)    → AppColors.ink2
var(--text3)    → AppColors.ink3
var(--border)   → AppColors.border / Color(0x16140C10)
var(--accent)   → AppColors.pink (#fd386f)
var(--accent-tint) → AppColors.pinkLight
var(--success)  → AppColors.success (#1a9e58)
var(--danger)   → AppColors.danger (#d6395c)
```

### Tipografía
```
Font: Plus Jakarta Sans (HTML) → fuente principal del dashboard Flutter
Tamaños clave: 28px (h1), 15px (fcount), 13px (fname-es), 12px (fstepnum/fpct)
Pesos: 400, 500, 600, 700, 800
```

### Componentes Flutter equivalentes
```
.card         → Panel widget (padding: 1.5rem, borderRadius: 18-22px)
.mgrid        → ResponsiveGrid(minTileWidth: 150..220)
.metric       → MetricCard widget
.fstep        → _FunnelStepRow widget
.fbarwrap/.fbar → LinearProgressIndicator (height 14, borderRadius 7)
.fdrop        → Text en danger color, fontSize 12, debajo del bar
.fsub         → expansión con border-left
.substep      → Row con barra de progreso thin (height 6)
SectionHeader → slabel del HTML (mayúsculas, opacidad 55%)
```

### Comportamiento interactivo
- Clic en `.metric-clickable` → modal/dialog con detalle + gráfico
- Clic en step del embudo → expandir sub-detalle
- Toggle dark: `toggleDark()` → Theme.of(context).brightness

### Animaciones
- `transition: height .4s` en barras de funnel → usar `AnimatedContainer` o implícita
- `transition:all .15s` en botones pill → `InkWell` con splash

---

## 5. Estructura Firestore para onboarding metrics

```
dashboard_metrics/onboarding:
  status: "ok"
  updated_at_label: "17 jun. 2026, 8:00 a. m."
  ranges:
    d7:
      total_started: 120
      total_completed: 45
      completion_rate: 0.375
      max_dropoff_step: 7
      steps:
        - { step_number: 1, step_name: "spending_concern", question_es: "...", unique_users: 120, drop_pct: 0.05 }
        - { step_number: 2, ... }
        ...15 items
      answers:
        - step_number: 1
          question_key: "spending_concern"
          options:
            - { answer: "Siempre", unique_users: 30, pct: 0.25 }
            - { answer: "Casi siempre", unique_users: 54, pct: 0.45 }
            ...
        ...
    d30: { ... }
    d90: { ... }
```

---

## 6. Queries BigQuery de referencia

### Llegadas por paso (onboarding_step_1 … onboarding_step_15)
```sql
-- Cada paso es su propio event_name — no hay parámetro step_number
SELECT
  event_name,
  COUNT(DISTINCT user_pseudo_id) AS unique_users,
  COUNT(*) AS event_count
FROM `trevo-ia.{DATASET}.events_*`
WHERE event_name IN (
  'onboarding_step_1','onboarding_step_2','onboarding_step_3','onboarding_step_4','onboarding_step_5',
  'onboarding_step_6','onboarding_step_7','onboarding_step_8','onboarding_step_9','onboarding_step_10',
  'onboarding_step_11','onboarding_step_12','onboarding_step_13','onboarding_step_14','onboarding_step_15'
)
  AND _TABLE_SUFFIX BETWEEN @start AND @end
GROUP BY 1
ORDER BY 1
-- Extraer número de paso: CAST(REGEXP_EXTRACT(event_name, r'onboarding_step_(\d+)') AS INT64)
```

### Distribución de respuestas (onboarding_answer)
```sql
-- question_key identifica el paso; sin step_number param
SELECT
  COALESCE((SELECT value.string_value FROM UNNEST(event_params) WHERE key = 'question_key'),    '') AS question_key,
  COALESCE((SELECT value.string_value FROM UNNEST(event_params) WHERE key = 'answer_selected'), '') AS answer_selected,
  COUNT(DISTINCT user_pseudo_id) AS unique_users
FROM `trevo-ia.{DATASET}.events_*`
WHERE event_name = 'onboarding_answer'
  AND _TABLE_SUFFIX BETWEEN @start AND @end
  AND (SELECT value.string_value FROM UNNEST(event_params) WHERE key = 'answer_selected')
      NOT IN ('info_continued', 'voice_demo_completed', 'completed', '')
GROUP BY 1, 2
ORDER BY 1, 3 DESC
-- Multi-select (debt_status, plan_selection): answer_selected = "A|B" → split por '|' en el cliente
```

---

## 7. Notas de implementación

- **BigQuery param**: `BIGQUERY_DATASET_ID` → string param de Firebase Functions (e.g., `analytics_123456789`)
- **Autenticación**: Application Default Credentials (ADC) del Cloud Function — sin service account JSON explícito
- **Location BigQuery**: US (default de Firebase Analytics export)
- **Actualización**: diaria (cron 8:15 AM UTC) + refresco manual desde dashboard
- **Trigger refresh**: `dashboard_metrics/onboarding/refresh_requests/{docId}` (mismo patrón que otros módulos)
- **Plataforma filter**: parámetro opcional `platform` (ios/android/all) filtrado por `device.operating_system`
