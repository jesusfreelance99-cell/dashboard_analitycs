# Google Analytics 4 - Trevo Analytics

## Información de tu Proyecto

```
Property ID (GA4): 534492843
Cuenta GA: Default Account for Firebase
App: Trevo IA (web)
Stream ID (web): 14591716390
```

## Configuración Completada ✅

### 1. Dependencia Instalada
- `firebase_analytics: ^11.5.0` en pubspec.yaml

### 2. Servicio de Analytics Creado
Archivo: `lib/core/services/analytics_service.dart`

**Funcionalidades:**
- Eventos personalizados
- Tracking de login
- Tracking de logout
- Propiedades de usuario
- Page views
- Tracking de errores
- Búsquedas
- Acciones personalizadas

## Uso en tu Aplicación

### En main.dart

```dart
import 'package:firebase_analytics/firebase_analytics.dart';
import 'lib/core/services/analytics_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Firebase Analytics está listo automáticamente
  // Recolecta eventos automáticos (page_view, etc.)
  
  await EasyLocalization.ensureInitialized();
  
  runApp(/* ... */);
}
```

### En LoginScreenProvider

```dart
import 'package:lib/core/services/analytics_service.dart';

// Después de login exitoso
await AnalyticsService.logLogin(
  method: 'google', // o 'email'
  userId: user.uid,
);

// Establecer propiedades del usuario
await AnalyticsService.setUserProperties(
  email: user.email,
  displayName: user.displayName,
  role: userData['rol'],
);
```

### En componentes

```dart
// Registrar una página
await AnalyticsService.logPageView(
  pageName: 'Dashboard',
  pageClass: 'DashboardScreen',
);

// Registrar una acción
await AnalyticsService.logAction(
  action: 'view_report',
  details: {'report_type': 'revenue'},
);

// Registrar búsqueda
await AnalyticsService.logSearch(searchTerm: 'ingresos');

// Registrar error
await AnalyticsService.logError(
  description: 'Firebase login failed',
  fatal: 'false',
);
```

## Eventos Automáticos

Firebase Analytics recolecta automáticamente:

- `first_visit` - Primera vez que abre la app
- `session_start` - Inicio de sesión
- `user_engagement` - Interacción del usuario
- `page_view` - Vistas de página
- `scroll` - Scroll en la página
- `click` - Clics en elementos

## Eventos Personalizados Recomendados

### Autenticación
```dart
// Login
AnalyticsService.logLogin(
  method: 'google',
  userId: user.uid,
);

// Logout
AnalyticsService.logLogout();

// Intento fallido
AnalyticsService.logAction(
  action: 'login_failed',
  details: {'error': 'invalid_credentials'},
);
```

### Navegación
```dart
AnalyticsService.logPageView(
  pageName: 'Dashboard Resume',
  pageClass: 'DashboardResumeScreen',
);
```

### Acciones del Usuario
```dart
// Ver reporte
AnalyticsService.logAction(
  action: 'view_report',
  details: {
    'report_type': 'revenue',
    'date_range': 'monthly',
  },
);

// Exportar datos
AnalyticsService.logAction(
  action: 'export_data',
  details: {'format': 'csv'},
);

// Cambiar tema
AnalyticsService.logAction(
  action: 'theme_changed',
  details: {'theme': 'dark_mode'},
);
```

### Errores
```dart
AnalyticsService.logError(
  description: 'Firestore query failed',
  fatal: 'true',
);
```

## Ver datos en Google Analytics

1. Ve a [Google Analytics 4](https://analytics.google.com/)
2. Selecciona la propiedad **trevo-ia**
3. En el menú izquierdo:
   - **Reportes** → Ver eventos, usuarios, conversiones
   - **Eventos** → Ver eventos personalizados
   - **Usuarios** → Información de usuarios únicos
   - **Configuración** → Propiedades del usuario

## Propiedades de Usuario Configuradas

| Propiedad | Descripción |
|-----------|------------|
| `email` | Email del usuario |
| `display_name` | Nombre mostrado |
| `user_role` | Rol del usuario (admin, etc) |

## Implementación en LoginScreenProvider

Ejemplo completo:

```dart
Future<bool> signInWithGoogle() async {
  _isLoading = true;
  _errorMessage = null;
  notifyListeners();

  try {
    final result = await GoogleAuthService.signInWithGoogle();

    if (result == null) {
      // Usuario canceló
      await AnalyticsService.logAction(
        action: 'google_signin_cancelled',
      );
      _isLoading = false;
      notifyListeners();
      return false;
    }

    // Login exitoso
    await AnalyticsService.logLogin(
      method: 'google',
      userId: result['uid'],
    );

    // Establecer propiedades del usuario
    await AnalyticsService.setUserProperties(
      email: result['email'],
      displayName: result['displayName'],
      role: result['userData']['rol'],
    );

    _isLoading = false;
    notifyListeners();
    return true;
  } catch (e) {
    _errorMessage = e.toString();
    
    // Registrar error
    await AnalyticsService.logError(
      description: 'Google Sign-In failed: $e',
      fatal: 'false',
    );
    
    _isLoading = false;
    notifyListeners();
    return false;
  }
}
```

## Dashboards Recomendados

### 1. User Acquisition
- Usuarios nuevos por día
- Fuente de login (Google, Email)
- Ubicación de usuarios

### 2. Engagement
- Usuarios activos
- Sesiones por usuario
- Duración promedio de sesión

### 3. Retention
- Usuarios que regresan
- Cohort analysis
- Churn rate

### 4. Conversions (Si aplica)
- Completar acciones
- Descargar reportes
- Usar funcionalidades premium

## Debugging en Desarrollo

Para ver eventos en tiempo real durante desarrollo:

1. Ve a Google Analytics 4
2. Abre **DebugView**
3. Ejecuta tu app: `flutter run -d chrome`
4. Verás los eventos en tiempo real

## Privacy & GDPR

- Asegúrate de que el consentimiento de cookies esté implementado
- No registres datos personales sensibles
- Google Analytics cumple con GDPR

## Próximas Integraciones

- [ ] Conversion tracking para acciones importantes
- [ ] Funnel analysis (login → dashboard → export)
- [ ] Custom dashboards
- [ ] Alertas de anomalías
- [ ] Integration con BigQuery

## Troubleshooting

### "No veo eventos en GA4"
- ✅ Verifica que Firebase esté inicializado en main.dart
- ✅ Ejecuta en Chrome (web)
- ✅ Abre DevTools y busca errores
- ✅ Espera 24-48 horas para que GA4 procese datos

### "Los eventos no aparecen en tiempo real"
- ✅ Usa DebugView en GA4
- ✅ Verifica que hayas instalado `flutter pub get`
- ✅ Reinicia la app después de cambios

### "Las propiedades del usuario no aparecen"
- ✅ Verifica que las propiedades estén registradas en GA4
- ✅ Usa letras minúsculas y guiones bajos (snake_case)
- ✅ Espera 24 horas para que GA4 procese

## Referencia de API

```dart
// Eventos personalizados
AnalyticsService.logEvent(
  name: 'custom_event_name',
  parameters: {'key': 'value'},
);

// Login/Logout
AnalyticsService.logLogin(method: 'email', userId: 'user123');
AnalyticsService.logLogout();

// Propiedades de usuario
AnalyticsService.setUserProperties(
  email: 'user@example.com',
  displayName: 'John Doe',
  role: 'admin',
);

// Page views
AnalyticsService.logPageView(
  pageName: 'Dashboard',
  pageClass: 'DashboardScreen',
);

// Búsquedas
AnalyticsService.logSearch(searchTerm: 'revenue');

// Errores
AnalyticsService.logError(
  description: 'Error message',
  fatal: 'false', // o 'true'
);

// Acciones personalizadas
AnalyticsService.logAction(
  action: 'button_click',
  details: {'button_name': 'export'},
);
```

## Recursos

- [Firebase Analytics Docs](https://firebase.google.com/docs/analytics)
- [GA4 Property: trevo-ia](https://analytics.google.com/analytics/web/#/p/534492843)
- [Stream ID: 14591716390](https://analytics.google.com/analytics/web/#/p/534492843/admin)
