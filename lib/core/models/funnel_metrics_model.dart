import 'package:dashboard_analitycs/features/screens/dashboard/dashboard_provider.dart';

class FunnelMetrics {
  final String status;
  final String updatedAtLabel;
  final Map<DateRange, FunnelRangeData> ranges;
  final List<FunnelEvent> allEvents;
  final List<DeviceEntry> devices;

  const FunnelMetrics({
    required this.status,
    required this.updatedAtLabel,
    required this.ranges,
    required this.allEvents,
    required this.devices,
  });

  static const empty = FunnelMetrics(
    status: 'idle',
    updatedAtLabel: '',
    ranges: {},
    allEvents: [],
    devices: [],
  );

  FunnelRangeData? range(DateRange r) => ranges[r];

  factory FunnelMetrics.fromMap(Map<String, dynamic> map) {
    final raw = map['ranges'] as Map<String, dynamic>? ?? {};
    final eventsRaw = (map['all_events'] as List<dynamic>? ?? [])
        .whereType<Map<String, dynamic>>();
    final devicesRaw = (map['devices'] as List<dynamic>? ?? [])
        .whereType<Map<String, dynamic>>();

    return FunnelMetrics(
      status: map['status'] as String? ?? 'idle',
      updatedAtLabel: map['updated_at_label'] as String? ?? '',
      ranges: {
        DateRange.d7:  FunnelRangeData.fromMap(raw['d7']  as Map<String, dynamic>? ?? {}),
        DateRange.d30: FunnelRangeData.fromMap(raw['d30'] as Map<String, dynamic>? ?? {}),
        DateRange.d90: FunnelRangeData.fromMap(raw['d90'] as Map<String, dynamic>? ?? {}),
        DateRange.all: FunnelRangeData.fromMap(raw['all'] as Map<String, dynamic>? ?? {}),
      },
      allEvents: eventsRaw.map(FunnelEvent.fromMap).toList(),
      devices: devicesRaw.map(DeviceEntry.fromMap).toList(),
    );
  }
}

class OnboardingStep {
  final String name;
  final int count;
  final int uniqueUsers;

  const OnboardingStep({
    required this.name,
    required this.count,
    required this.uniqueUsers,
  });

  factory OnboardingStep.fromMap(Map<String, dynamic> m) => OnboardingStep(
    name:        m['step_name']    as String? ?? '',
    count:       (m['count']        as num?)?.toInt() ?? 0,
    uniqueUsers: (m['unique_users'] as num?)?.toInt() ?? 0,
  );
}

class FunnelRangeData {
  final int paywallViewed;
  final int trialStarted;
  final int uniquePaywall;
  final int uniqueTrial;
  final int appOpenCount;
  final int appOpenUnique;
  final int tutorialBeginCount;
  final int tutorialBeginUnique;
  final List<FunnelEvent> events;
  final List<OnboardingStep> onboardingSteps;

  const FunnelRangeData({
    this.paywallViewed = 0,
    this.trialStarted = 0,
    this.uniquePaywall = 0,
    this.uniqueTrial = 0,
    this.appOpenCount = 0,
    this.appOpenUnique = 0,
    this.tutorialBeginCount = 0,
    this.tutorialBeginUnique = 0,
    this.events = const [],
    this.onboardingSteps = const [],
  });

  factory FunnelRangeData.fromMap(Map<String, dynamic> m) => FunnelRangeData(
    paywallViewed:        (m['paywall_viewed']        as num?)?.toInt() ?? 0,
    trialStarted:         (m['trial_started']         as num?)?.toInt() ?? 0,
    uniquePaywall:        (m['unique_paywall']         as num?)?.toInt() ?? 0,
    uniqueTrial:          (m['unique_trial']           as num?)?.toInt() ?? 0,
    appOpenCount:         (m['app_open_count']         as num?)?.toInt() ?? 0,
    appOpenUnique:        (m['app_open_unique']        as num?)?.toInt() ?? 0,
    tutorialBeginCount:   (m['tutorial_begin_count']   as num?)?.toInt() ?? 0,
    tutorialBeginUnique:  (m['tutorial_begin_unique']  as num?)?.toInt() ?? 0,
    events: (m['events'] as List<dynamic>? ?? [])
        .whereType<Map<String, dynamic>>()
        .map(FunnelEvent.fromMap)
        .toList(),
    onboardingSteps: (m['onboarding_steps'] as List<dynamic>? ?? [])
        .whereType<Map<String, dynamic>>()
        .map(OnboardingStep.fromMap)
        .toList(),
  );
}

class FunnelEvent {
  final String name;
  final int count;
  final int uniqueUsers;

  const FunnelEvent({
    required this.name,
    required this.count,
    required this.uniqueUsers,
  });

  factory FunnelEvent.fromMap(Map<String, dynamic> m) => FunnelEvent(
    name:        m['name']         as String? ?? '',
    count:       (m['count']        as num?)?.toInt() ?? 0,
    uniqueUsers: (m['unique_users'] as num?)?.toInt() ?? 0,
  );

  String get displayName {
    const labels = <String, String>{
      // Ciclo de vida de sesión
      'session_start':              'Sesión iniciada',
      'app_open':                   'App abierta',
      'first_open':                 'Primera apertura',
      'user_engagement':            'Tiempo de interacción',
      'screen_view':                'Pantalla visitada',
      'os_update':                  'Actualización de sistema',
      'app_update':                 'Actualización de app',
      'app_remove':                 'App desinstalada',
      // Conversión (eventos clave)
      'paywall_viewed':             'Vio el paywall',
      'trial_started':              'Inició período de prueba',
      'subscription_purchased':     'Compró suscripción',
      'subscription_canceled':      'Canceló suscripción',
      'subscription_expired':       'Suscripción expirada',
      'ecommerce_purchase':          'Suscripción comprada',
      'in_app_purchase':            'Compra realizada',
      // Autenticación
      'login':                      'Inicio de sesión',
      'logout':                     'Cierre de sesión',
      'sign_up':                    'Registro completado',
      'registration_completed':     'Registro completado',
      // Onboarding
      'tutorial_begin':             'Tutorial iniciado',
      'tutorial_complete':          'Tutorial completado',
      // Acciones en app
      'budget_created':             'Presupuesto creado',
      'expense_added':              'Gasto registrado',
      'feature_used':               'Función utilizada',
      'search':                     'Búsqueda realizada',
      'share':                      'Contenido compartido',
      'select_content':             'Contenido seleccionado',
      'view_item':                  'Elemento visualizado',
      // Notificaciones
      'notification_open':          'Notificación abierta',
      'notification_receive':       'Notificación recibida',
      'notification_dismiss':       'Notificación descartada',
      // Publicidad
      'ad_impression':              'Anuncio visualizado',
      'ad_click':                   'Clic en anuncio',
      'ad_reward':                  'Anuncio completado',
    };
    return labels[name] ??
        name
            .split('_')
            .map((w) => w.isEmpty ? '' : '${w[0].toUpperCase()}${w.substring(1)}')
            .join(' ');
  }

  bool get isKeyEvent => const {
    'paywall_viewed',
    'trial_started',
    'ecommerce_purchase',
  }.contains(name);
}

class DeviceEntry {
  final String model;
  final String os;
  final int count;
  final double fraction;

  const DeviceEntry({
    required this.model,
    required this.os,
    required this.count,
    required this.fraction,
  });

  factory DeviceEntry.fromMap(Map<String, dynamic> m) => DeviceEntry(
    model:    m['model']    as String? ?? '',
    os:       m['os']       as String? ?? '',
    count:    (m['count']    as num?)?.toInt() ?? 0,
    fraction: (m['fraction'] as num?)?.toDouble() ?? 0,
  );
}
