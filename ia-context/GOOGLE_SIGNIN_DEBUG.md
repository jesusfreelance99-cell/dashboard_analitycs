# Debugging Google Sign-In

Si el botón de "Continuar con Google" no funciona en web, sigue esta guía.

## 📋 Checklist Rápido

- [ ] Firebase inicializado en main.dart
- [ ] google_sign_in agregado en pubspec.yaml
- [ ] OAuth configurado en Google Cloud Console
- [ ] Orígenes autorizados incluyen localhost
- [ ] Usuario existe en Firestore con rol = "admin"
- [ ] DevTools abierto viendo Console

## 🔍 Paso 1: Ver Logs en Consola

1. Abre Chrome DevTools: **F12**
2. Ve a la pestaña **Console**
3. Presiona el botón "Continuar con Google"
4. Busca mensajes con emojis:
   - 🔵 = Paso en progreso
   - ✅ = Paso completado
   - ❌ = Error encontrado
   - 🟡 = Usuario canceló

**Ejemplo de logs exitosos:**
```
🔵 Iniciando Google Sign-In...
✅ Usuario de Google obtenido: user@gmail.com
✅ Credenciales de Google obtenidas
🔵 Autenticando con Firebase...
✅ Usuario autenticado en Firebase: user@gmail.com
🔵 Verificando rol en Firestore...
✅ Usuario encontrado en Firestore con rol: admin
✅ Acceso permitido. Login exitoso.
```

## 🔴 Errores Comunes

### Error: "No se pudo obtener las credenciales de autenticación de Google"

**Causa:** OAuth no está configurado en Google Cloud Console

**Solución:**
1. Ve a [Google Cloud Console](https://console.cloud.google.com/)
2. Selecciona proyecto **trevo-ia**
3. Ve a **APIs y servicios** → **Credenciales**
4. Busca **OAuth 2.0 Client IDs** (tipo Aplicación web)
5. Si no existe, crea uno:
   - Click en **+ Crear credenciales**
   - Selecciona **OAuth 2.0 Client ID**
   - Tipo: **Aplicación web**
   - Agrega orígenes autorizados:
     - `http://localhost:5000`
     - `http://localhost:5173`
     - `http://127.0.0.1:5173`

### Error: "Usuario no registrado en el sistema"

**Causa:** El usuario de Google existe pero no está en Firestore

**Solución:**
1. Ve a Firebase Console
2. Selecciona **Firestore Database**
3. Crea colección: `users_dashboard`
4. Crea documento con ID = `{uid_del_usuario}`
5. Agrega campos:
```json
{
  "email": "tu-email@gmail.com",
  "displayName": "Tu Nombre",
  "rol": "admin",
  "createdAt": "2024-06-06",
  "lastLogin": "2024-06-06"
}
```

### Error: "Acceso denegado: se requiere rol de administrador"

**Causa:** El usuario existe pero su rol NO es "admin"

**Solución:**
1. Ve a Firestore
2. Abre documento del usuario en `users_dashboard`
3. Edita el campo `rol`
4. Cambia a: **admin** (exactamente así, en minúsculas)

### Error: "Usuario canceló Google Sign-In" (🟡)

**Causa:** El usuario cerró la ventana emergente de Google

**Solución:** Presiona el botón nuevamente y completa el login

## 🌐 Problema: El botón no responde en absoluto

### 1. Verifica la consola del navegador

**Abre DevTools (F12)** y mira si hay errores rojos:
- Si ves error → búscalo en esta tabla
- Si no ves errores → continúa con paso 2

### 2. Verifica que Firebase esté inicializado

En DevTools Console, ejecuta:
```javascript
firebase.auth().currentUser
```

Si retorna `null`, Firebase está listo. Si retorna error, Firebase no inicializó correctamente.

### 3. Verifica que google_sign_in esté disponible

En DevTools Console, ejecuta:
```javascript
console.log(navigator.onLine)
```

Debe retornar `true`. Si retorna `false`, no hay conexión internet.

## 🧪 Test Manual Completo

### Setup:
1. `flutter pub get`
2. `flutter run -d chrome`
3. Abre DevTools (F12)
4. Ve a Console

### Test paso a paso:

**1. Verifica que no haya errores de Firebase:**
```
En Console: firebase.auth().currentUser → null ✅
```

**2. Presiona "Continuar con Google"**
- Deberías ver popup emergente
- Si no aparece → OAuth no configurado

**3. Selecciona tu cuenta Google**
- Si aparece error → revisa "Errores Comunes" arriba

**4. Verifica logs:**
```
🔵 Iniciando Google Sign-In...
✅ Usuario de Google obtenido: ...
... (más pasos)
✅ Acceso permitido. Login exitoso.
```

**5. Si login fue exitoso:**
- App redirige a `/dashboard`
- Deberías ver el dashboard

## 🛠️ Debug Avanzado

### Ver todas las variables de ambiente:

En Console:
```javascript
console.log(window.location.href)
```

Debe mostrar: `http://localhost:XXXX/login`

### Ver configuración de Firebase:

En Console:
```javascript
firebase.initializeApp
```

Debe estar disponible.

## 📱 Test en Diferentes Navegadores

- [ ] Chrome (principal)
- [ ] Firefox
- [ ] Safari (si tienes Mac)
- [ ] Edge

Google Sign-In funciona mejor en Chrome.

## 🔗 Configurar Orígenes en Google Cloud

**Paso crítico:**

1. [Google Cloud Console](https://console.cloud.google.com/)
2. Proyecto: **trevo-ia**
3. **APIs y servicios** → **Credenciales**
4. Click en OAuth Client ID (Aplicación web)
5. **Orígenes autorizados (JavaScript):**
   ```
   http://localhost:5000
   http://localhost:5173
   http://127.0.0.1:5173
   ```
6. **URIs de redirección autorizados:**
   ```
   http://localhost:5000/
   http://localhost:5173/
   http://127.0.0.1:5173/
   ```
7. **Guardar**

## 📲 Conectar Google Console con Firebase

1. Firebase Console → **Proyecto: trevo-ia**
2. **Autenticación** → **Método de inicio de sesión**
3. Habilita **Google**
4. En la sección "Apps autorizadas para utilizar esta credencial de OAuth":
   - Verifica que tu proyecto esté listado

## 🐛 Problema: Usuario autenticado pero sin datos en Firestore

**Síntomas:**
- Login con Google funciona
- Pero error: "Usuario no registrado en el sistema"

**Causa:** Usuario de Google existe pero no en tu Firestore

**Solución:**
1. Anota el email del usuario
2. Ve a Firestore
3. En `users_dashboard`, crea nuevo documento
4. USA el email como **ID del documento**
5. Agrega campos:
   - `email`: tu-email@gmail.com
   - `displayName`: Tu Nombre
   - `rol`: admin

## ✅ Verificar Configuración

### Firebase Console:
- [ ] Proyecto "trevo-ia" seleccionado
- [ ] Autenticación → Google habilitado
- [ ] Firestore Database existe
- [ ] Colección `users_dashboard` existe

### Google Cloud Console:
- [ ] Proyecto "trevo-ia" seleccionado
- [ ] OAuth Client ID (Aplicación web) existe
- [ ] Orígenes autorizados incluyen localhost
- [ ] URIs de redirección incluyen localhost

### Código:
- [ ] `firebase_options.dart` tiene apiKey correcto
- [ ] `main.dart` inicializa Firebase
- [ ] `google_sign_in` en pubspec.yaml
- [ ] `flutter pub get` ejecutado

## 🚀 Si todo falla

1. Copia todos los logs de Console (F12)
2. Ve a [Firebase Support](https://support.google.com/firebase/)
3. Abre un issue con:
   - Los logs
   - Tu proyecto ID
   - Los pasos que hiciste

O crea un issue en GitHub con los logs.

## 📚 Enlaces útiles

- [Google Cloud OAuth Setup](https://cloud.google.com/docs/authentication/application-default-credentials)
- [Firebase Authentication Web](https://firebase.google.com/docs/auth/web)
- [Google Sign-In for Flutter Web](https://pub.dev/packages/google_sign_in)
- [Firebase Console](https://console.firebase.google.com/)
- [Google Cloud Console](https://console.cloud.google.com/)

## Preguntas Frecuentes

**P: ¿Por qué aparece popup bloqueado?**
R: A veces el navegador bloquea popups. Click en el icono de bloqueo en la barra de direcciones.

**P: ¿Funciona sin OAuth configurado?**
R: No. OAuth es requerido para Google Sign-In en web.

**P: ¿Qué es un "origen autorizado"?**
R: Es la URL donde tu app está corriendo. localhost es importante para desarrollo.

**P: ¿Puedo usar otro puerto?**
R: Sí, agrega `http://localhost:TU_PUERTO` en Google Cloud Console.
