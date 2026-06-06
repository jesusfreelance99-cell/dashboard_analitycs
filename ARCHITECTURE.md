# Arquitectura del Proyecto - Trevo Analytics

## Visión General

Trevo Analytics es una aplicación Flutter de dashboard con arquitectura **Feature-First** y separación clara entre `core` (funcionalidad compartida) y `features` (funcionalidad específica).

## Estructura de Carpetas

```
lib/
├── main.dart                     # Punto de entrada y bootstrap
├── app.dart                      # Configuración global de la app
├── core/                         # Funcionalidad compartida
│   ├── constants/               # Colores, espacios, constantes
│   ├── theme/                   # Sistema de temas (light/dark)
│   ├── providers/               # Proveedores de estado global
│   ├── routes/                  # Rutas y navegación
│   ├── widgets/                 # Componentes reutilizables
│   ├── services/                # Servicios y APIs
│   ├── models/                  # Modelos base
│   └── utils/                   # Utilidades y helpers
└── features/                    # Funcionalidades específicas
    ├── dashboard/              # Feature: Dashboard
    │   ├── data/
    │   │   ├── datasources/
    │   │   ├── models/
    │   │   └── repositories/
    │   ├── domain/
    │   │   ├── entities/
    │   │   ├── repositories/
    │   │   └── usecases/
    │   └── presentation/
    │       ├── providers/
    │       ├── screens/
    │       ├── widgets/
    │       └── state/
    └── [other_features]/
```

## Principios de Diseño

### 1. Separación de Responsabilidades
- **Core:** Componentes compartidos, tema, rutas, estado global
- **Features:** Lógica específica del dominio con data layer, domain layer, presentation layer

### 2. Gestión de Estado
- **Provider:** Se usa para estado global (`ThemeProvider`)
- **ChangeNotifier:** Para cambios de estado reactivos

### 3. Temas y Estilos
- Sistema de colores centralizado en `AppColors`
- Temas light/dark completamente configurados
- Tipografía con Google Fonts (DM Sans)
- Espacios y radios predefinidos en `AppConstants`

### 4. Componentes Reutilizables
- `AppButton` - Botones en diferentes tipos
- `AppCard` - Tarjetas base
- `StatCard` - Tarjetas de estadísticas
- `LoadingState` - Estado de carga
- `EmptyState` - Estado vacío
- `ErrorState` - Estado de error

### 5. Localización
- `easy_localization` para soporte multilenguaje
- Archivos JSON en `assets/translations/` (es.json, en.json)

### 6. Iconografía
- `fluentui_system_icons` para diseño consistente

## Flujo de Desarrollo

### Agregar una nueva pantalla
1. Crea una carpeta en `features/nueva_feature/presentation/screens/`
2. Crea el widget de la pantalla
3. Importa componentes de `core/widgets/` según sea necesario
4. Usa `AppColors` y `AppConstants` para estilos
5. Registra la ruta en `core/routes/app_routes.dart`

### Agregar estado global
1. Crea un `ChangeNotifier` en `core/providers/`
2. Decláralo en `main.dart` dentro de `MultiProvider`
3. Accede con `Provider.of<NuevoProvider>(context)`

### Agregar un nuevo componente reutilizable
1. Crea el archivo en `core/widgets/`
2. Documenta su uso con ejemplos
3. Reutilízalo en múltiples features

## Dependencias Principales

- **flutter:** Framework
- **provider:** Gestión de estado
- **google_fonts:** Tipografía personalizada (DM Sans)
- **easy_localization:** Soporte multilenguaje
- **fluentui_system_icons:** Iconografía

## Temas

### Colores Primarios (Paleta Personalizada)
- Magenta Vibrante: `#FF1493`
- Rosa Brillante: `#FF4081`
- Rosa Medio: `#E81E63`
- Rosa Claro: `#F48FB1`
- Borgoña Oscuro: `#880E4F`
- Rojo Oscuro: `#660033`

### Modos
- **Light Mode:** Fondo blanco, texto oscuro, primarios vibrantes
- **Dark Mode:** Fondo negro, texto claro, primarios en tonos claros

## Responsive Design

- **Mobile:** < 480px
- **Tablet:** 480px - 768px
- **Desktop:** > 768px

Use `MediaQuery` y `LayoutBuilder` para adaptarse a diferentes tamaños.

## Testing

La estructura soporta:
- Tests unitarios para providers y modelos
- Tests de widgets para componentes UI
- Tests de integración para flujos completos

Ubicar tests en la carpeta `test/` espejo de `lib/`.

## Próximos Pasos

1. Implementar servicios en `core/services/`
2. Agregar repositorios en `features/dashboard/data/repositories/`
3. Crear usecases en `features/dashboard/domain/usecases/`
4. Expandir con más features según requerimientos
5. Agregar temas adicionales (analytics, configuración, etc.)
