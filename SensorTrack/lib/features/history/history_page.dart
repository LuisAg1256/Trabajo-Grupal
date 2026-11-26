import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/formatters.dart';
import '../../core/repository_exception.dart';
import '../../models/sensor_reading.dart';
import '../../services/readings_repository.dart';
import '../../widgets/reading_tile.dart';
import 'reading_detail_page.dart';

/// Pantalla **Historial** (módulo 4): lista de registros guardados en Supabase,
/// del más reciente al más antiguo, con filtro por sensor, paginación y detalle.
class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key});

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  static const _pageSize = 20;
  static const _filtros = <SensorType?>[
    null, // Todos
    SensorType.accelerometer,
    SensorType.gyroscope,
    SensorType.gps,
  ];

  final _repo = ReadingsRepository();
  final _scroll = ScrollController();
  final List<SensorReading> _items = [];
  StreamSubscription<void>? _cambios;

  SensorType? _filtro;
  bool _cargando = true;
  bool _cargandoMas = false;
  bool _hayMas = true;
  String? _error;

  /// Se incrementa en cada recarga para descartar respuestas de consultas
  /// anteriores (por ejemplo, si se cambia el filtro mientras carga).
  int _consulta = 0;

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_alHacerScroll);
    // Recarga automática cuando se guardan mediciones nuevas (módulo 3).
    _cambios = _repo.changes.listen((_) => _recargar());
    _recargar();
  }

  @override
  void dispose() {
    _cambios?.cancel();
    _scroll.dispose();
    super.dispose();
  }

  void _alHacerScroll() {
    if (_scroll.position.extentAfter < 300) _cargarMas();
  }

  /// Vuelve a cargar la primera página.
  Future<void> _recargar() async {
    final consulta = ++_consulta;
    setState(() {
      _cargando = _items.isEmpty;
      _error = null;
    });
    try {
      final pagina = await _repo.fetchPage(
        from: 0,
        to: _pageSize - 1,
        type: _filtro,
      );
      if (!mounted || consulta != _consulta) return;
      setState(() {
        _items
          ..clear()
          ..addAll(pagina);
        _hayMas = pagina.length == _pageSize;
      });
    } on RepositoryException catch (e) {
      if (!mounted || consulta != _consulta) return;
      setState(() => _error = e.message);
    } finally {
      if (mounted && consulta == _consulta) setState(() => _cargando = false);
    }
  }

  /// Carga la siguiente página al llegar al final de la lista.
  Future<void> _cargarMas() async {
    if (_cargando || _cargandoMas || !_hayMas || _error != null) return;
    final consulta = _consulta;
    setState(() => _cargandoMas = true);
    try {
      final desde = _items.length;
      final pagina = await _repo.fetchPage(
        from: desde,
        to: desde + _pageSize - 1,
        type: _filtro,
      );
      if (!mounted || consulta != _consulta) return;
      setState(() {
        _items.addAll(pagina);
        _hayMas = pagina.length == _pageSize;
      });
    } on RepositoryException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.message),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    } finally {
      if (mounted) setState(() => _cargandoMas = false);
    }
  }

  void _cambiarFiltro(SensorType? filtro) {
    if (filtro == _filtro) return;
    setState(() {
      _filtro = filtro;
      _items.clear();
      _hayMas = true;
    });
    _recargar();
  }

  void _abrirDetalle(SensorReading reading) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => ReadingDetailPage(reading: reading)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Historial'),
        actions: [
          IconButton(
            tooltip: 'Recargar',
            icon: const Icon(Icons.refresh),
            onPressed: _recargar,
          ),
        ],
      ),
      body: Column(
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                for (final filtro in _filtros)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(
                        filtro == null
                            ? 'Todos'
                            : AppFormatters.sensorName(filtro),
                      ),
                      avatar: filtro == null
                          ? null
                          : Icon(AppFormatters.sensorIcon(filtro)),
                      selected: _filtro == filtro,
                      onSelected: (_) => _cambiarFiltro(filtro),
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            child: RefreshIndicator(onRefresh: _recargar, child: _contenido()),
          ),
        ],
      ),
    );
  }

  Widget _contenido() {
    if (_cargando) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null && _items.isEmpty) {
      return _Mensaje(
        icono: Icons.cloud_off,
        texto: _error!,
        accion: FilledButton.icon(
          onPressed: _recargar,
          icon: const Icon(Icons.refresh),
          label: const Text('Reintentar'),
        ),
      );
    }
    if (_items.isEmpty) {
      return const _Mensaje(
        icono: Icons.inbox_outlined,
        texto: 'Aún no hay mediciones guardadas.',
      );
    }
    return ListView.separated(
      controller: _scroll,
      physics: const AlwaysScrollableScrollPhysics(),
      itemCount: _items.length + (_hayMas ? 1 : 0),
      separatorBuilder: (_, _) => const Divider(height: 1),
      itemBuilder: (context, i) {
        if (i == _items.length) {
          return const Padding(
            padding: EdgeInsets.all(16),
            child: Center(child: CircularProgressIndicator()),
          );
        }
        final reading = _items[i];
        return ReadingTile(
          reading: reading,
          onTap: () => _abrirDetalle(reading),
        );
      },
    );
  }
}

/// Mensaje centrado (lista vacía o error). Se puede desplazar para que el
/// gesto de "deslizar para recargar" siga funcionando.
class _Mensaje extends StatelessWidget {
  const _Mensaje({required this.icono, required this.texto, this.accion});

  final IconData icono;
  final String texto;
  final Widget? accion;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: SizedBox(
          height: constraints.maxHeight,
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icono, size: 48),
                  const SizedBox(height: 12),
                  Text(texto, textAlign: TextAlign.center),
                  if (accion != null) ...[const SizedBox(height: 16), accion!],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
