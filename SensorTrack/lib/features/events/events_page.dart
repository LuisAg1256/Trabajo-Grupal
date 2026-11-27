import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/formatters.dart';
import '../../core/repository_exception.dart';
import '../../models/event.dart';
import '../../services/readings_repository.dart';

/// Historial de eventos de cambio brusco guardados en la tabla `event`.
class EventsPage extends StatefulWidget {
  const EventsPage({super.key});

  @override
  State<EventsPage> createState() => _EventsPageState();
}

class _EventsPageState extends State<EventsPage> {
  final _repo = ReadingsRepository();
  StreamSubscription<void>? _cambios;
  List<Event>? _eventos;
  String? _error;

  @override
  void initState() {
    super.initState();
    // Se recarga solo cuando se registra un evento nuevo.
    _cambios = _repo.changes.listen((_) => _recargar());
    _recargar();
  }

  @override
  void dispose() {
    _cambios?.cancel();
    super.dispose();
  }

  Future<void> _recargar() async {
    try {
      final eventos = await _repo.fetchEvents();
      if (!mounted) return;
      setState(() {
        _eventos = eventos;
        _error = null;
      });
    } on RepositoryException catch (e) {
      if (!mounted) return;
      setState(() => _error = e.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    final eventos = _eventos;
    return Scaffold(
      appBar: AppBar(title: const Text('Eventos detectados')),
      body: eventos == null && _error == null
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _recargar,
              child: _error != null || eventos!.isEmpty
                  ? ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.all(24),
                      children: [
                        Text(
                          _error ?? 'Aún no se han detectado cambios bruscos.',
                          textAlign: TextAlign.center,
                        ),
                      ],
                    )
                  : ListView.separated(
                      physics: const AlwaysScrollableScrollPhysics(),
                      itemCount: eventos.length,
                      separatorBuilder: (_, _) => const Divider(height: 1),
                      itemBuilder: (context, i) {
                        final e = eventos[i];
                        return ListTile(
                          leading: const CircleAvatar(
                            child: Icon(Icons.warning_amber_rounded),
                          ),
                          title: const Text('Cambio brusco · Acelerómetro'),
                          subtitle: Text(
                            'X: ${AppFormatters.axis(e.x)}  '
                            'Y: ${AppFormatters.axis(e.y)}  '
                            'Z: ${AppFormatters.axis(e.z)} m/s²\n'
                            '${AppFormatters.dateTime(e.recordedAt)}',
                          ),
                          isThreeLine: true,
                        );
                      },
                    ),
            ),
    );
  }
}
