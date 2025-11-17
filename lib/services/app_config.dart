import 'api_service.dart';

/// Archivo de configuración simple para exponer una instancia de ApiService.
///
/// Cambia [baseUrl] si ejecutas el backend en otra máquina/puerto.
class AppConfig {
  static ApiService? _api;

  /// Por defecto apunta al emulador Android (10.0.2.2) en el puerto 3000.
  /// Si usas un dispositivo físico, cambia a la IP de tu máquina en la LAN
  /// (ej. http://192.168.1.42:3000).
  static ApiService apiInstance({String baseUrl = 'http://10.0.2.2:3000'}) {
    _api ??= ApiService(baseUrl: baseUrl);
    return _api!;
  }
}
