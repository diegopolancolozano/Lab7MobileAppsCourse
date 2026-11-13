# Laboratorio 7 · Fotos en el muro

Aplicación Flutter con autenticación, muro, likes, foto de perfil y posts con imagen.

## Proyecto configurado

La app y la CLI usan **lab-7**, identificador `zwlzratjsphupqqjwywp`. `lib/main.dart` contiene su URL y clave pública. No se guarda ninguna clave administrativa en la app.

El proyecto remoto contiene `profiles`, `posts` y `likes`, además de:

- `avatars`: público, máximo 2 MiB, JPEG/PNG/WebP.
- `post-images`: privado, máximo 2 MiB, JPEG/PNG/WebP; las URLs se firman por una hora.

Las cinco migraciones de `supabase/migrations/` se descargaron del historial remoto. Las dos migraciones originales de noviembre 9 se conservan en `docs/migraciones-originales/`: sus cambios ya están en el historial remoto y no deben volver a aplicarse.

## Ejecutar

```powershell
flutter pub get
flutter run
```

Registrarse con correo y contraseña, iniciar sesión y abrir el perfil. El botón de cámara cambia el avatar. En Nuevo post, Agregar foto abre la galería, se muestra la vista previa y Quitar foto elimina el adjunto antes de publicar. Se permiten publicaciones con texto, imagen o ambos.

Para el registro inmediato del laboratorio, desactivar Confirm email en Authentication → Sign In / Providers del proyecto remoto. El `config.toml` local no cambia por sí solo esa configuración remota.

## Verificar

```powershell
flutter analyze --no-pub
flutter test --no-pub
npx supabase migration list --remote
```

Las pruebas de interfaz usan Bloc en memoria. Comprueban navegación, eventos, adjuntar/quitar/volver a adjuntar una foto, estados y likes.

La prueba real se ejecuta por separado:

```powershell
./tools/test-supabase.ps1
```

Requiere Supabase CLI autenticada y acceso administrativo al proyecto. El script crea una cuenta temporal confirmada sin enviar correos y pasa sus credenciales solo mediante variables de entorno. La prueba usa la clave pública para login, perfil, reemplazo del avatar, publicación de texto con imagen y solo imagen, lectura del muro, URLs firmadas, privacidad del bucket, likes y cierre de sesión. Al terminar elimina los archivos y la cuenta temporal; las filas dependientes se eliminan por cascada.

La prueba real no comprueba el registro por correo, el selector nativo de galería ni espera una hora para comprobar la expiración. Esos pasos se verifican manualmente en un dispositivo.

## Alcance de seguridad del laboratorio

El esquema remoto sigue la consigna mínima: las tablas públicas no tienen RLS y las políticas de Storage permiten operaciones a cualquier usuario autenticado en cada bucket. La restricción por carpeta de usuario aparece como reto opcional en el enunciado. Esta configuración requiere reforzarse antes de usar la app fuera del laboratorio.
