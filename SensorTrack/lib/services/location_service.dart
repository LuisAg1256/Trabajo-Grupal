import 'package:geolocator/geolocator.dart';

/// Estados posibles del servicio y permisos de ubicación GPS.
enum LocationStatus {
  /// Servicio activo y permiso concedido.
  available,

  /// El GPS / servicio de ubicación del sistema está apagado.
  serviceDisabled,

  /// Permiso aún no concedido o denegado temporalmente.
  denied,

  /// Permiso denegado permanentemente (requiere ir a Ajustes).
  deniedForever,
}

/// Servicio encargado de consultar estado, solicitar permisos y obtener
/// lecturas GPS mediante `geolocator` (Módulos 1 y 2).
class LocationService {
  const LocationService();

  /// Consulta el estado actual del GPS sin abrir el diálogo del sistema
  /// (ideal para la pantalla Inicio en el Módulo 1).
  Future<LocationStatus> checkStatus() async {
    try {
      final enabled = await Geolocator.isLocationServiceEnabled();
      if (!enabled) return LocationStatus.serviceDisabled;

      final permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.deniedForever) {
        return LocationStatus.deniedForever;
      }
      if (permission == LocationPermission.denied) {
        return LocationStatus.denied;
      }
      return LocationStatus.available;
    } catch (_) {
      return LocationStatus.serviceDisabled;
    }
  }

  /// Verifica el servicio y solicita permiso al sistema si estaba en `denied`
  /// (usado en la pantalla Ubicación del Módulo 2 tras mostrar el aviso de privacidad).
  Future<LocationStatus> ensurePermission() async {
    final enabled = await Geolocator.isLocationServiceEnabled();
    if (!enabled) return LocationStatus.serviceDisabled;

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.deniedForever) {
      return LocationStatus.deniedForever;
    }
    if (permission == LocationPermission.denied) {
      return LocationStatus.denied;
    }
    return LocationStatus.available;
  }

  /// Obtiene la ubicación actual con alta precisión y límite de tiempo de 15 s.
  Future<Position> getCurrent() {
    return Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        timeLimit: Duration(seconds: 15),
      ),
    );
  }

  /// Stream continuo de posiciones cuando el usuario se desplaza al menos [distanceFilter] metros.
  Stream<Position> track({int distanceFilter = 5}) {
    return Geolocator.getPositionStream(
      locationSettings: LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: distanceFilter,
      ),
    );
  }

  /// Abre la pantalla de configuración de ubicación del sistema operativo.
  Future<bool> openLocationSettings() async {
    try {
      return await Geolocator.openLocationSettings();
    } catch (_) {
      return false;
    }
  }

  /// Abre los ajustes de permisos de la aplicación en el sistema operativo.
  Future<bool> openAppSettings() async {
    try {
      return await Geolocator.openAppSettings();
    } catch (_) {
      return false;
    }
  }
}
