# ✅ Arreglar Google Sign-In - Guía Rápida

El botón no funciona porque **OAuth no está configurado**. Sigue estos 5 pasos:

## 🔧 Paso 1: Instalar dependencias

```bash
flutter pub get
```

## 🔗 Paso 2: Configurar OAuth en Google Cloud

**IMPORTANTE:** Este es el paso crítico.

1. Ve a [Google Cloud Console](https://console.cloud.google.com/)
2. Selecciona proyecto **trevo-ia** (887325226758)
3. En el menú izquierdo: **APIs y servicios** → **Credenciales**
4. Click en **+ Crear credenciales**
5. Selecciona **OAuth 2.0 Client ID**
6. Tipo: **Aplicación web**
7. Nombre: `Web Client`
8. En **Orígenes autorizados (JavaScript)** agrega:
   ```
   http://localhost:5000
   http://localhost:5173
   http://127.0.0.1:5173
   ```
9. En **URIs de redirección autorizados** agrega:
   ```
   http://localhost:5000/
   http://localhost:5173/
   http://127.0.0.1:5173/
   ```
10. Click en **Crear**

## 👤 Paso 3: Crear usuario admin en Firestore

1. Ve a [Firebase Console](https://console.firebase.google.com/)
2. Selecciona proyecto **trevo-ia**
3. **Firestore Database**
4. Crea nueva colección: `users_dashboard`
5. Crea nuevo documento con ID = tu email (ej: `tu-email@gmail.com`)
6. Agrega estos campos:
   ```
   email: "tu-email@gmail.com"
   displayName: "Tu Nombre"
   rol: "admin"
   createdAt: timestamp
   lastLogin: timestamp
   ```

## 🚀 Paso 4: Ejecutar la app

```bash
flutter run -d chrome
```

## 🧪 Paso 5: Probar

1. Abre DevTools: **F12**
2. Ve a **Console**
3. Presiona "Continuar con Google"
4. Verifica los logs:
   ```
   🔵 Iniciando Google Sign-In...
   ✅ Usuario de Google obtenido: tu-email@gmail.com
   ✅ Credenciales de Google obtenidas
   🔵 Autenticando con Firebase...
   ✅ Usuario autenticado en Firebase: tu-email@gmail.com
   🔵 Verificando rol en Firestore...
   ✅ Usuario encontrado en Firestore con rol: admin
   ✅ Acceso permitido. Login exitoso.
   ```

Si ves todos los logs ✅, ¡funcionó! 🎉

---

## 🐛 Si no funciona

### Problema: No aparece popup de Google

**Causa:** OAuth no configurado  
**Solución:** Vuelve al Paso 2 y verifica que los orígenes autorizados estén guardados

### Problema: "Usuario no registrado en el sistema"

**Causa:** Email de Gmail no existe en Firestore  
**Solución:** Vuelve al Paso 3 y crea el documento con tu email exacto

### Problema: "Acceso denegado: rol no es admin"

**Causa:** Campo `rol` no es "admin"  
**Solución:** En Firestore, edita el documento y cambia `rol` a `admin` (exactamente así)

### Problema: "OAuth no está configurado"

**Causa:** No completaste el Paso 2  
**Solución:** Ve a Google Cloud Console y crea el OAuth Client ID

---

## 📱 Verificación Final

Antes de empezar, verifica:

- [ ] Estás en `http://localhost:5173` (o similar)
- [ ] DevTools abierto (F12)
- [ ] Console visible
- [ ] Email de Google anotado (ej: tu-email@gmail.com)

Cuando presiones "Continuar con Google", deberías ver:
- [ ] Popup emergente de Google
- [ ] Logs en Console (emojis 🔵 ✅ ❌)
- [ ] Redirección a `/dashboard` si tiene rol admin

---

**¿Listo? Sigue los 5 pasos arriba.** Si algo no funciona, abre DevTools y revisa los logs en la Console. 🚀
