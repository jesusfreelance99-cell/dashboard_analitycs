# Estructura Actual del Proyecto - Trevo Analytics

## Árbol Completo de Archivos

```
lib/
├── main.dart                                    # Bootstrap principal
├── app.dart                                     # Configuración global
│
├── core/                                        # Funcionalidad compartida
│   ├── constants/
│   │   ├── app_colors.dart                     # Paleta de colores
│   │   ├── app_constants.dart                  # Constantes globales
│   │   └── constants_export.dart               # Export de constantes
│   │
│   ├── theme/
│   │   └── app_theme.dart                      # Sistema de temas (light/dark)
│   │
│   ├── providers/
│   │   ├── theme_provider.dart                 # Provider de temas
│   │   └── providers_export.dart               # Export de providers
│   │
│   ├── routes/
│   │   └── app_routes.dart                     # Configuración de rutas
│   │
│   ├── widgets/
│   │   ├── app_button.dart                     # Componente Button
│   │   ├── app_card.dart                       # Componente Card
│   │   ├── loading_state.dart                  # Estado Loading
│   │   ├── empty_state.dart                    # Estado Empty
│   │   ├── error_state.dart                    # Estado Error
│   │   └── widgets_export.dart                 # Export de widgets
│   │
│   └── exports/
│       ├── main_routes_export.dart             # Export de rutas
│       └── providers_export.dart               # Export de providers
│
└── features/                                    # Funcionalidades específicas
    └── screens/
        ├── auth/
        │   └── login_auth_screen.dart          # Pantalla de Login
        │
        └── dashboard/
            └── dashboard_resume_screen.dart     # Pantalla de Dashboard

assets/
├── translations/
│   ├── es.json                                 # Traducciones español
│   └── en.json                                 # Traducciones inglés
```

## Desglose por Carpeta

### `lib/core/`
Centro de funcionalidad compartida reutilizable en toda la app.

#### `constants/`
- **app_colors.dart**: Define paleta completa (colores primarios, secundarios, estados)
- **app_constants.dart**: Espacios, radios, breakpoints, duraciones
- **constants_export.dart**: Exporta ambos archivos

#### `theme/`
- **app_theme.dart**: Sistema de temas Material Design 3 con light/dark mode

#### `providers/`
- **theme_provider.dart**: ChangeNotifier para gestión de tema
- **providers_export.dart**: Exporta providers

#### `routes/`
- **app_routes.dart**: Configuración de rutas y navegación

#### `widgets/`
- **app_button.dart**: Botón reutilizable (4 tipos)
- **app_card.dart**: Tarjeta base y StatCard
- **loading_state.dart**: Estado de carga
- **empty_state.dart**: Estado vacío
- **error_state.dart**: Estado de error
- **widgets_export.dart**: Exporta todos los widgets

#### `exports/`
- **main_routes_export.dart**: Export de rutas
- **providers_export.dart**: Export de providers

### `lib/features/`
Funcionalidades específicas del negocio.

#### `screens/auth/`
- **login_auth_screen.dart**: Pantalla de Login

#### `screens/dashboard/`
- **dashboard_resume_screen.dart**: Pantalla de Dashboard

## Archivos Principales

| Archivo | Propósito |
|---------|-----------|
| main.dart | Entry point, configuración EasyLocalization, MultiProvider |
| app.dart | MaterialApp, temas, rutas iniciales |

## Estructura de Dependencias

```
main.dart
  ├── EasyLocalization (es, en)
  ├── MultiProvider
  │   ├── ThemeProvider
  │   └── AuthProvider (comentado)
  └── TrevoAnalyticsApp
        ├── AppTheme (light/dark)
        ├── AppRoutes
        └── Screens (Login, Dashboard)
```

## Traducciones Disponibles

- **es.json**: Español
- **en.json**: Inglés
- Idiomas soportados: español (fallback), inglés

## Sistema de Exports

### Exports en `core/`
```
core/
├── constants/constants_export.dart
├── providers/providers_export.dart
├── widgets/widgets_export.dart
└── exports/
    ├── main_routes_export.dart
    └── providers_export.dart
```

### Pantallas (Features)
```
features/screens/
├── auth/login_auth_screen.dart
└── dashboard/dashboard_resume_screen.dart
```

## Notas Importantes

1. **No hay carpeta `auth/` en features**: Las pantallas están directamente en `features/screens/`
2. **No hay estructura presentation/data/domain** en features: Solo pantallas por ahora
3. **Los exports** están en `core/exports/` 
4. **AuthProvider comentado** en main.dart
5. **Archivos de traducciones** en `assets/translations/`

## Resumen de Componentes

### Temas
- ✅ Light Mode
- ✅ Dark Mode
- ✅ Cambio en tiempo real

### Widgets Reutilizables
- ✅ AppButton (4 tipos)
- ✅ AppCard
- ✅ StatCard
- ✅ LoadingState
- ✅ EmptyState
- ✅ ErrorState

### Gestión de Estado
- ✅ ThemeProvider (activo)
- ⚠️ AuthProvider (comentado en main)

### Pantallas
- ✅ Login Screen (`login_auth_screen.dart`)
- ✅ Dashboard Screen (`dashboard_resume_screen.dart`)

### Rutas
- `/login` → AuthLoginScreen
- `/dashboard` → DashboardScreen
- `/` → Home (Dashboard)
