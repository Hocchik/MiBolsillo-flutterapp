# TuBolsillo

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.

## Apartado: Conexión al backend

Este proyecto incluye un servicio sencillo para comunicarse con un backend REST.

- Archivo principal del cliente HTTP: `lib/services/api_service.dart`.
- Para almacenar el token de autenticación (ej. JWT) se utiliza `SharedPreferences` con la clave `auth_token`.
- Dependencia añadida: `http` (declared en `pubspec.yaml`).

Cómo usarlo (resumen):

1. Instalar dependencias:

	flutter pub get

2. Configurar la URL base del backend. Por ejemplo, al crear la instancia:

	final api = ApiService(baseUrl: 'http://localhost:3000');

	Ajusta `http://localhost:3000` por la ubicación de tu backend. Si el backend está en otra carpeta del mismo repositorio, probablemente ejecutarás ese servidor en localhost y usarás la dirección local.

3. Flujo típico de login:

	- Llamar a `api.login(username, password)` — el backend debería devolver un token.
	- Guardar el token con `AuthService().setAuthToken(token)`.

4. Peticiones autenticadas:

	- `ApiService` añade automáticamente el header `Authorization: Bearer <token>` si el token está guardado en `SharedPreferences`.

5. Dónde poner la carpeta del backend:

	- Si tienes el código del backend en otra carpeta del mismo repositorio, colócalo en el nivel superior (junto a la carpeta de la app) o en la ubicación que prefieras.
	- Inicia el servidor backend desde esa carpeta (por ejemplo `npm start`, `dotnet run`, `python main.py`, según el backend).
	- Ajusta `baseUrl` en la app al puerto/dirección donde el servidor quede escuchando (por ejemplo `http://localhost:3000`).

6. Ejemplo rápido desde `main.dart` o un provider:

	final api = ApiService(baseUrl: 'http://localhost:3000');
	// después usar api.login / api.getTransactions / api.postTransaction

Notas y supuestos:

- Supongo que el backend expone rutas REST estándar: `/auth/login`, `/auth/register`, `/transactions`.
- Si el backend usa rutas distintas o necesita parámetros extra (CSRF, client id, etc.), adapta `api_service.dart` en consecuencia.
- Si prefieres no hardcodear `baseUrl`, puedo añadir `flutter_dotenv` para leer variables de entorno desde `.env`.

Siguientes pasos que puedo hacer ahora:

- Añadir integración (ej.: llamadas reales desde la pantalla de login / registro).
- Añadir manejo de errores más robusto o un provider/riverpod para inyectar `ApiService` en la app.
