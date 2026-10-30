import 'package:flutter/material.dart';
import '../data/database_helper.dart';
import '../models/filtro_incidencia.dart';
import '../services/sync_service.dart';
import 'nueva_incidencia_modal.dart';

class IncidenciasScreen extends StatefulWidget {
  const IncidenciasScreen({super.key});

  @override
  State<IncidenciasScreen> createState() => _IncidenciasScreenState();
}

class _IncidenciasScreenState extends State<IncidenciasScreen> {
  // 10.0.2.2 apunta a la maquina anfitriona desde el emulador de Android
  final SyncService _syncService = SyncService(
    backendUrl: 'http://10.0.2.2:8080',
  );

  List<Map<String, dynamic>> _incidencias = [];
  bool _cargando = false;
  FiltroIncidencia _filtro = FiltroIncidencia.todas;

  @override
  void initState() {
    super.initState();
    _cargarIncidenciasLocales();
  }

  Future<void> _cargarIncidenciasLocales() async {
    final datos = await DatabaseHelper.instance.obtenerPorFiltro(_filtro);
    setState(() => _incidencias = datos);
  }

  Future<void> _sincronizar() async {
    setState(() => _cargando = true);
    final total = await _syncService.ejecutarSincronizacion('TEC-CR-001');
    await _cargarIncidenciasLocales();
    setState(() => _cargando = false);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            total > 0
                ? '¡Sincronización exitosa! ($total registros enviados).'
                : 'No hay registros pendientes o el servidor no respondió.',
          ),
          backgroundColor: total > 0 ? Colors.green[700] : Colors.orange[800],
        ),
      );
    }
  }

  void _abrirFormularioModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => NuevaIncidenciaModal(
        onGuardado: _cargarIncidenciasLocales,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('FieldTech Inspecciones'),
        actions: [
          IconButton(
            icon: _cargando
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : const Icon(Icons.sync),
            tooltip: 'Sincronizar con Servidor',
            onPressed: _cargando ? null : _sincronizar,
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(56),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
            child: SegmentedButton<FiltroIncidencia>(
              segments: const [
                ButtonSegment(
                  value: FiltroIncidencia.todas,
                  label: Text('Todas'),
                  icon: Icon(Icons.list),
                ),
                ButtonSegment(
                  value: FiltroIncidencia.offline,
                  label: Text('Offline'),
                  icon: Icon(Icons.cloud_off),
                ),
                ButtonSegment(
                  value: FiltroIncidencia.sincronizadas,
                  label: Text('Sincronizadas'),
                  icon: Icon(Icons.cloud_done),
                ),
              ],
              selected: {_filtro},
              showSelectedIcon: false,
              onSelectionChanged: (seleccion) {
                setState(() => _filtro = seleccion.first);
                _cargarIncidenciasLocales();
              },
            ),
          ),
        ),
      ),
      body: _incidencias.isEmpty
          ? const Center(
              child: Text(
                'No hay inspecciones registradas.\nPresione + para crear una.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey, fontSize: 16),
              ),
            )
          : ListView.builder(
              itemCount: _incidencias.length,
              itemBuilder: (ctx, index) {
                final item = _incidencias[index];
                final bool sincronizado = item['is_synced'] == 1;
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  elevation: 2,
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor:
                          sincronizado ? Colors.green[100] : Colors.amber[100],
                      child: Icon(
                        sincronizado ? Icons.cloud_done : Icons.cloud_off,
                        color: sincronizado ? Colors.green[800] : Colors.amber[900],
                      ),
                    ),
                    title: Text(
                      item['titulo'],
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      '${item['categoria']} | Lat: ${item['latitud']}, Lon: ${item['longitud']}',
                    ),
                    trailing: Text(
                      sincronizado ? 'En Servidor' : 'Offline',
                      style: TextStyle(
                        fontSize: 12,
                        color: sincronizado ? Colors.green[700] : Colors.amber[900],
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _abrirFormularioModal,
        icon: const Icon(Icons.add_a_photo),
        label: const Text('Nueva Incidencia'),
      ),
    );
  }
}
