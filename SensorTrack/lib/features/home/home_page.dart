import 'package:flutter/material.dart';

import '../../models/sensor_reading.dart';
import '../../services/location_service.dart';
import '../../services/readings_repository.dart';
import '../../services/sensor_service.dart';
import '../../widgets/status_card.dart';
import '../history/history_page.dart';
import '../location/location_page.dart';
import '../sensors/sensors_page.dart';
import '../splash/splash_page.dart';
import '../stats/stats_page.dart';

/// Contenedor principal de navegación con las 5 pestañas exigidas y contenido
/// de la pantalla **1. Inicio** (Módulos 1.3, 1.4 y 1.5).
class HomePage extends StatefulWidget {
  final InitialSystemCheck? initialCheck;

  const HomePage({super.key, this.initialCheck});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;

  bool _checkingSystem = false;
  bool? _supabaseConnected;
  String? _supabaseError;
  Map<SensorType, bool> _motionSensors = const {};
  LocationStatus _locationStatus = LocationStatus.denied;

  final ReadingsRepository _repository = ReadingsRepository();
  final SensorService _sensorService = const SensorService();
  final LocationService _locationService = const LocationService();

  @override
  void initState() {
    super.initState();
    if (widget.initialCheck != null) {
      _supabaseConnected = widget.initialCheck!.supabaseConnected;
      _supabaseError = widget.initialCheck!.supabaseError;
      _motionSensors = widget.initialCheck!.motionSensors;
      _locationStatus = widget.initialCheck!.locationStatus;
    } else {
      _refreshStatus();
    }
  }

  /// Comprueba el estado de Supabase y de todos los sensores del dispositivo.
  Future<void> _refreshStatus() async {
    setState(() {
      _checkingSystem = true;
    });

    final results = await Future.wait<Object?>([
      _repository.checkConnection(),
      _sensorService.checkMotionSensors(),
      _locationService.checkStatus(),
    ]);

    if (!mounted) return;
    setState(() {
      _supabaseConnected = results[0] as bool;
      _supabaseError = _repository.lastConnectionError;
      _motionSensors = results[1] as Map<SensorType, bool>;
      _locationStatus = results[2] as LocationStatus;
      _checkingSystem = false;
    });
  }

  void _goToTab(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final pages = <Widget>[
      _InicioTab(
        checkingSystem: _checkingSystem,
        supabaseConnected: _supabaseConnected,
        supabaseError: _supabaseError,
        motionSensors: _motionSensors,
        locationStatus: _locationStatus,
        onRefresh: _refreshStatus,
        onNavigateTab: _goToTab,
      ),
      const SensorsPage(),
      const LocationPage(),
      const HistoryPage(),
      const StatsPage(),
    ];

    return Scaffold(
      body: IndexedStack(index: _selectedIndex, children: pages),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: _goToTab,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home_rounded),
            label: 'Inicio',
          ),
          NavigationDestination(
            icon: Icon(Icons.sensors_outlined),
            selectedIcon: Icon(Icons.sensors_rounded),
            label: 'Sensores',
          ),
          NavigationDestination(
            icon: Icon(Icons.location_on_outlined),
            selectedIcon: Icon(Icons.location_on_rounded),
            label: 'Ubicación',
          ),
          NavigationDestination(
            icon: Icon(Icons.history_outlined),
            selectedIcon: Icon(Icons.history_rounded),
            label: 'Historial',
          ),
          NavigationDestination(
            icon: Icon(Icons.insights_outlined),
            selectedIcon: Icon(Icons.insights_rounded),
            label: 'Estadísticas',
          ),
        ],
      ),
    );
  }
}

class _InicioTab extends StatelessWidget {
  final bool checkingSystem;
  final bool? supabaseConnected;
  final String? supabaseError;
  final Map<SensorType, bool> motionSensors;
  final LocationStatus locationStatus;
  final Future<void> Function() onRefresh;
  final ValueChanged<int> onNavigateTab;

  const _InicioTab({
    required this.checkingSystem,
    required this.supabaseConnected,
    required this.supabaseError,
    required this.motionSensors,
    required this.locationStatus,
    required this.onRefresh,
    required this.onNavigateTab,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    const primaryTeal = Color.fromARGB(255, 1, 169, 184);

    // Configuración visual del estado de Supabase (3 estados: Comprobando / Conectado / Sin conexión)
    final bool isChecking = checkingSystem || supabaseConnected == null;
    final bool isConnected = supabaseConnected == true;

    final Color supaColor = isChecking
        ? primaryTeal
        : (isConnected ? Colors.green : Colors.redAccent);
    final String supaBadge = isChecking
        ? 'Comprobando…'
        : (isConnected ? 'Conectado' : 'Sin conexión');
    final String supaSubtitle = isChecking
        ? 'Verificando acceso a la tabla sensor_readings…'
        : (isConnected
              ? 'Conexión activa con PostgreSQL en Supabase.'
              : (supabaseError ?? 'No se pudo conectar con Supabase.'));

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'SensorTrack',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            onPressed: checkingSystem ? null : onRefresh,
            tooltip: 'Actualizar estado',
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: onRefresh,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // 1. Estado de conexión con Supabase (Módulo 1.4)
            const Text(
              'Estado del Backend',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            StatusCard(
              title: 'Supabase Cloud',
              subtitle: supaSubtitle,
              leadingIcon: isConnected
                  ? Icons.cloud_done_rounded
                  : Icons.cloud_off_rounded,
              statusColor: supaColor,
              badgeText: supaBadge,
              isLoading: isChecking,
              trailingAction: !isChecking && !isConnected
                  ? OutlinedButton.icon(
                      onPressed: onRefresh,
                      icon: const Icon(Icons.refresh_rounded, size: 18),
                      label: const Text('Reintentar'),
                    )
                  : null,
            ),
            const SizedBox(height: 22),

            // 2. Sensores disponibles en el dispositivo (Módulo 1.5)
            const Text(
              'Sensores del Dispositivo',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                color: colorScheme.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: colorScheme.outlineVariant),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 4,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  _SensorAvailabilityTile(
                    icon: Icons.speed_rounded,
                    name: 'Acelerómetro',
                    description:
                        'Aceleración en X, Y, Z · Detectar movimiento del dispositivo',
                    available: motionSensors[SensorType.accelerometer],
                    checking: checkingSystem && motionSensors.isEmpty,
                  ),
                  const Divider(height: 1),
                  _SensorAvailabilityTile(
                    icon: Icons.threesixty_rounded,
                    name: 'Giroscopio',
                    description:
                        'Velocidad angular X, Y, Z · Detectar rotaciones',
                    available: motionSensors[SensorType.gyroscope],
                    checking: checkingSystem && motionSensors.isEmpty,
                  ),
                  const Divider(height: 1),
                  _GpsAvailabilityTile(status: locationStatus),
                  const Divider(height: 1),
                  _SensorAvailabilityTile(
                    icon: Icons.explore_rounded,
                    name: 'Magnetómetro (opcional)',
                    description: 'Campo magnético · Obtener orientación',
                    available: motionSensors[SensorType.magnetometer],
                    checking: checkingSystem && motionSensors.isEmpty,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 22),

            // 3. Menú principal de acceso rápido (Módulo 1.3)
            const Text(
              'Menú Principal',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1.45,
              children: [
                _QuickNavCard(
                  title: 'Sensores',
                  subtitle: 'Acelerómetro y giroscopio en vivo',
                  icon: Icons.sensors_rounded,
                  color: primaryTeal,
                  onTap: () => onNavigateTab(1),
                ),
                _QuickNavCard(
                  title: 'Ubicación GPS',
                  subtitle: 'Coordenadas, precisión y mapa',
                  icon: Icons.location_on_rounded,
                  color: Colors.indigo,
                  onTap: () => onNavigateTab(2),
                ),
                _QuickNavCard(
                  title: 'Historial',
                  subtitle: 'Registros guardados en Supabase',
                  icon: Icons.history_rounded,
                  color: Colors.deepOrange,
                  onTap: () => onNavigateTab(3),
                ),
                _QuickNavCard(
                  title: 'Estadísticas',
                  subtitle: 'Totales, máx/mín y evolución',
                  icon: Icons.insights_rounded,
                  color: Colors.teal.shade700,
                  onTap: () => onNavigateTab(4),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SensorAvailabilityTile extends StatelessWidget {
  final IconData icon;
  final String name;
  final String description;
  final bool? available;
  final bool checking;

  const _SensorAvailabilityTile({
    required this.icon,
    required this.name,
    required this.description,
    required this.available,
    required this.checking,
  });

  @override
  Widget build(BuildContext context) {
    final bool isOk = available == true;
    final Color badgeColor = checking
        ? Colors.grey
        : (isOk ? Colors.green : Colors.redAccent);
    final String label = checking
        ? 'Verificando'
        : (isOk ? 'Disponible' : 'No disponible');

    return ListTile(
      leading: Icon(icon, color: const Color.fromARGB(255, 1, 169, 184)),
      title: Text(
        name,
        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
      ),
      subtitle: Text(description, style: const TextStyle(fontSize: 12)),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            checking
                ? Icons.hourglass_top_rounded
                : (isOk ? Icons.check_circle_rounded : Icons.cancel_rounded),
            color: badgeColor,
            size: 18,
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: badgeColor,
            ),
          ),
        ],
      ),
    );
  }
}

class _GpsAvailabilityTile extends StatelessWidget {
  final LocationStatus status;

  const _GpsAvailabilityTile({required this.status});

  @override
  Widget build(BuildContext context) {
    late final Color color;
    late final String label;
    late final IconData statusIcon;

    switch (status) {
      case LocationStatus.available:
        color = Colors.green;
        label = 'Disponible';
        statusIcon = Icons.check_circle_rounded;
      case LocationStatus.serviceDisabled:
        color = Colors.orange;
        label = 'Desactivado';
        statusIcon = Icons.location_disabled_rounded;
      case LocationStatus.denied:
      case LocationStatus.deniedForever:
        color = Colors.amber.shade800;
        label = 'Sin permiso';
        statusIcon = Icons.lock_outline_rounded;
    }

    return ListTile(
      leading: const Icon(
        Icons.my_location_rounded,
        color: Color.fromARGB(255, 1, 169, 184),
      ),
      title: const Text(
        'GPS / Ubicación',
        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
      ),
      subtitle: const Text(
        'Latitud y longitud · Obtener ubicación geográfica',
        style: TextStyle(fontSize: 12),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(statusIcon, color: color, size: 18),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickNavCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _QuickNavCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: colorScheme.outlineVariant),
          boxShadow: const [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 4,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withAlpha(30),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: color, size: 22),
                ),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 14,
                  color: colorScheme.onSurfaceVariant,
                ),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
