# Estructura del Login - Diseño Trevo

## Archivos Creados

```
lib/features/screens/auth/
├── login_auth_screen.dart            # Wrapper principal
├── login_responsive_screen.dart      # Pantalla responsiva (desktop/mobile)
├── login_form_components.dart        # Componentes del formulario (lado izq)
├── login_right_panel.dart            # Panel derecho con gradiente
└── login_screen_provider.dart        # Provider para estado de visibilidad password
```

## Componentes Creados

### Login Responsive Screen (`login_responsive_screen.dart`)
- **Desktop (tablet+)**: Dos columnas lado a lado
  - Izquierda: Formulario
  - Derecha: Panel de datos
- **Mobile**: Scroll vertical
  - Banner degradado arriba
  - Formulario abajo

### Form Components (`login_form_components.dart`)
| Componente | Función |
|-----------|---------|
| `LoginFormHeader` | Título "PANEL DE CRECIMIENTO" + descripción |
| `GoogleSignInButton` | Botón "Continuar con Google" |
| `OrDivider` | Divisor "o con tu correo" |
| `EmailInputField` | Campo de email |
| `PasswordInputField` | Campo de contraseña con toggle |
| `RememberMeCheckbox` | Checkbox + link "¿Olvidaste?" |
| `LoginButtonWidget` | Botón "Iniciar sesión" |
| `SignUpPrompt` | "¿No tienes acceso? Solicita..." |
| `LoginFormFooter` | Copyright y links |

### Right Panel (`login_right_panel.dart`)
| Componente | Función |
|-----------|---------|
| `LoginRightPanel` | Contenedor con gradiente + contenido |
| `LiveBadge` | Badge "EN VIVO" con punto animado |
| `PanelCards` | Stack de 3 tarjetas con datos |
| `_DashCard` | Tarjeta "Suscriptores" |
| `_MetricCard` | Tarjeta "MRR" con icono |
| `_ConversionCard` | Tarjeta "Embudo de conversión" con barras |
| `PanelFooter` | "Conectado con" + partners |

## Diseño Visual

### Lado Izquierdo
```
Logo "trevo" (rosa)
├── PANEL DE CRECIMIENTO (etiqueta)
├── Bienvenido de nuevo (h1)
├── Descripción
├── [Botón Google]
├── o con tu correo
├── [Campo Email]
├── [Campo Contraseña]
├── [✓ Recuérdame] [¿Olvidaste?]
├── [Botón Iniciar sesión]
├── ¿No tienes acceso? Solicita invitación
└── © 2026 Trevo · Términos · Privacidad
```

### Lado Derecho (Gradiente)
```
Gradiente rosa claro → rosa → rojo oscuro (157°)
├── [EN VIVO]
├── Cada peso y cada usuario, en tiempo real.
├── Descripción...
├── [Tarjetas flotantes con datos]
│   ├── Suscriptores: 11 (↑ 3 nuevos)
│   ├── MRR $142 (↑ $31 esta semana)
│   └── Embudo de conversión (7.2%) [con gráfico]
└── Conectado con RevenueCat · Mixpanel · Firebase
```

## Responsividad

| Tamaño | Breakpoint | Layout |
|--------|-----------|--------|
| Mobile | < 900px | Vertical (banner + form) |
| Tablet | 900px - 1024px | Vertical (banner + form) |
| Desktop | > 1024px | Horizontal (50/50) |

## State Management

### LoginScreenProvider
```dart
class LoginScreenProvider extends ChangeNotifier {
  bool _obscurePassword = true;
  
  bool get obscurePassword => _obscurePassword;
  void togglePasswordVisibility() { ... }
}
```

Se proporciona en `LoginResponsiveScreen` con `ChangeNotifierProvider`.

## Colores Usados

| Elemento | Color |
|----------|-------|
| Primario | `AppColors.pink` (#fd386f) |
| Gradiente | `AppColors.brandGradient` (5 stops) |
| Texto | `AppColors.ink` (#1a1a1a) |
| Campos | `AppColors.fieldBg` (#faf9f8) |
| Líneas | `AppColors.line` / `line2` |
| Success | `AppColors.success` / `liveGreen` |

## Tipografía

- **DM Sans** (Google Fonts, ya configurada en app_theme.dart)
- **H1** (displaySmall): "Bienvenido de nuevo"
- **Label**: "PANEL DE CRECIMIENTO"
- **Body**: Descripciones
- **Small**: Footer

## Sin Errores de Análisis

```
✅ No issues found!
✅ Imports correctos
✅ Providers bien tipados
✅ Responsive funcionando
✅ Componentes modularizados
```

## Cómo Usar

```dart
// En rutas
case AppRoutes.login:
  return MaterialPageRoute(
    builder: (_) => const AuthLoginScreen(),
  );
```

El componente ya está conectado en `lib/core/routes/app_routes.dart` como `/login`.

## Próximos Pasos

1. Agregar asset `assets/google_logo.png` (actualmente usa fallback Icon)
2. Conectar funcionalidad de Google Sign-In
3. Implementar validación de emails
4. Conectar con API de autenticación
5. Agregar animaciones de transición

## Estructura Mantenida

✅ No se tocó:
- `main.dart`
- `app.dart`
- `app_routes.dart`
- `app_theme.dart`
- `app_colors.dart`
- `app_constants.dart`
- Ningún archivo del `core/`
- El archivo original `login_auth_screen.dart` fue reemplazado (estaba vacío)

Solo se agregaron archivos nuevos en `lib/features/screens/auth/`.
