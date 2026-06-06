# Arquitectura del Módulo de Notificaciones

## 🏗️ Principios SOLID Aplicados

### 1. **Single Responsibility Principle (SRP)**
Cada componente tiene una única responsabilidad:

```
NotificationScreen         → Orquestación principal
├── NotificationFormWidget → Gestión del formulario
├── NotificationRecipientsWidget → Selección de destinatarios
├── NotificationSendButtonWidget → Lógica de envío
└── NotificationPreviewWidget → Vista previa del teléfono
```

### 2. **Open/Closed Principle (OCP)**
- Los widgets son abiertos para extensión (props)
- Cerrados para modificación (no necesitan cambios internos)

### 3. **Liskov Substitution Principle (LSP)**
- Todos los widgets extienden `StatelessWidget` o `StatefulWidget`
- Pueden reemplazarse sin romper la funcionalidad

### 4. **Interface Segregation Principle (ISP)**
- `NotificationProvider` expone solo métodos necesarios
- Cada widget recibe solo las props que usa

### 5. **Dependency Inversion Principle (DIP)**
- Los widgets dependen de abstracciones (Provider, Services)
- No dependen de implementaciones concretas

---

## 📁 Estructura de Archivos

```
lib/features/screens/dashboard/
├── screens/
│   └── notification_screen.dart          # Main orchestrator
├── widgets/
│   ├── notification_form_widget.dart     # Form container
│   ├── notification_recipients_widget.dart   # Recipients selection
│   ├── notification_send_button_widget.dart  # Send button with logic
│   └── notification_preview_widget.dart  # Phone preview
├── providers/
│   └── notification_provider.dart        # State management
└── (resto de dashboard)
```

---

## 🔒 Robustez y Manejo de Errores

### Try-Catch en Todos los Niveles

#### **Screen Level** (notification_screen.dart)
```dart
Future<void> _initializeNotifications() async {
  try {
    final provider = context.read<NotificationProvider>();
    await provider.initialize();
  } catch (e) {
    if (mounted) {
      _showErrorSnackBar('Error inicializando: $e');
    }
  }
}
```

#### **Form Level** (notification_form_widget.dart)
```dart
void _attachListeners() {
  try {
    widget.titleController.addListener(_onTitleChanged);
  } catch (e) {
    debugPrint('❌ Error attaching listeners: $e');
  }
}
```

#### **Button Level** (notification_send_button_widget.dart)
```dart
Future<void> _handleSendNotification() async {
  try {
    if (!_validateForm()) return;
    // Lógica de envío
  } catch (e) {
    _showErrorSnackBar('Error inesperado: ${e.toString()}');
  } finally {
    setState(() => _isSending = false);
  }
}
```

#### **Provider Level** (notification_provider.dart)
```dart
Future<void> initialize() async {
  _isLoading = true;
  try {
    _allUsers = await _userSyncService.getAllUsersLocal();
  } catch (e) {
    _errorMessage = 'Error: $e';
  } finally {
    _isLoading = false;
    notifyListeners();
  }
}
```

---

## 💪 Características de Robustez

### 1. **Validación Exhaustiva**
```dart
bool _validateForm() {
  final provider = context.read<NotificationProvider>();
  
  if (!provider.isNotificationValid()) {
    _showErrorSnackBar('Completa todos los campos');
    return false;
  }
  return true;
}
```

### 2. **Estado Consistente**
```dart
// Si el widget se destruye durante async, no actualizar
if (!mounted) return;

// Siempre reset en finally
finally {
  if (mounted) {
    setState(() => _isSending = false);
  }
}
```

### 3. **Feedback al Usuario**
- SnackBars informativos
- Loading indicators durante procesos
- Validación antes de envío
- Mensajes de error específicos

---

## 🔄 Flujo de Datos

```
1. INICIALIZACIÓN
   NotificationScreen → NotificationProvider.initialize()
   ↓
   UserSyncService.getAllUsersLocal()
   ↓
   Cargar usuarios en Provider

2. INPUT DEL USUARIO
   NotificationFormWidget.titleController → Provider.setNotificationTitle()
   NotificationRecipientsWidget → Provider.toggleSendToAll()

3. VALIDACIÓN
   NotificationSendButtonWidget._validateForm()
   → Verifica título, mensaje, destinatarios

4. ENVÍO
   NotificationProvider.getFcmTokens()
   ↓
   FcmSendService.sendNotification()
   ↓
   Guarda en Firestore para Cloud Function

5. FEEDBACK
   SnackBar de éxito o error
   Provider.clearForm() si es exitoso
```

---

## 🎯 Variables y Estados

### **NotificationProvider State**
```dart
// Usuarios
List<UserModel> _allUsers         // Todos los usuarios
List<UserModel> _filteredUsers    // Usuarios filtrados por búsqueda

// Selección
List<String> _selectedUserIds     // IDs de usuarios seleccionados
bool _sendToAll                   // Flag: enviar a todos

// Notificación
String _notificationTitle         // Título del mensaje
String _notificationMessage       // Cuerpo del mensaje

// UI
bool _isLoading                   // Estado de carga
String? _errorMessage             // Error actual
String _searchQuery               // Término de búsqueda
```

### **Widget State**
```dart
// NotificationSendButtonWidget
bool _isSending = false           // Loading state del botón

// NotificationFormWidget
TextEditingController titleController
TextEditingController messageController
```

---

## 🧪 Testing

### Unit Tests (Próximos)
```dart
// Test: NotificationProvider
test('should validate notification', () {
  final provider = NotificationProvider();
  expect(provider.isNotificationValid(), false);
  
  provider.setNotificationTitle('Title');
  provider.setNotificationMessage('Message');
  provider.toggleSendToAll(true);
  
  expect(provider.isNotificationValid(), true);
});
```

### Widget Tests (Próximos)
```dart
testWidgets('NotificationSendButton should show loading', (tester) async {
  await tester.pumpWidget(NotificationSendButtonWidget());
  expect(find.byType(CircularProgressIndicator), findsNothing);
  
  await tester.tap(find.byType(FilledButton));
  await tester.pump();
  
  expect(find.byType(CircularProgressIndicator), findsOne);
});
```

---

## 📊 Ventajas de esta Arquitectura

✅ **Modular**: Cada componente es independiente  
✅ **Testeable**: Fácil de unit test cada parte  
✅ **Mantenible**: Cambios aislados sin efectos colaterales  
✅ **Escalable**: Agregar features sin reescribir  
✅ **Robusto**: Manejo completo de errores  
✅ **Senior Level**: Sigue best practices profesionales  

---

## 🚀 Próximos Pasos

1. ✅ Completar NotificationScreen
2. ⏳ Conectar en dashboard_resume_screen.dart
3. ⏳ Agregar unit tests
4. ⏳ Agregar widget tests
5. ⏳ Documentar API de Cloud Functions

---

## 📚 Referencia Rápida

### Uso en Dashboard
```dart
// En dashboard_resume_screen.dart
return NotificationScreen();  // Reemplazar _NotificationsPage

// Envolver con Provider si es necesario
ChangeNotifierProvider(
  create: (_) => NotificationProvider(),
  child: NotificationScreen(),
)
```

### Debugging
```dart
// En cualquier widget
context.read<NotificationProvider>().recipientCount  // Usuarios seleccionados
context.read<NotificationProvider>().errorMessage    // Último error
```

---

**Arquitectura diseñada para producción con estándares profesionales.**
