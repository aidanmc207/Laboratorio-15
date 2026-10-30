import 'dart:io';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../data/database_helper.dart';
import '../services/hardware_service.dart';

class NuevaIncidenciaModal extends StatefulWidget {
  final VoidCallback onGuardado;
  const NuevaIncidenciaModal({super.key, required this.onGuardado});

  @override
  State<NuevaIncidenciaModal> createState() => _NuevaIncidenciaModalState();
}

class _NuevaIncidenciaModalState extends State<NuevaIncidenciaModal> {
  final _tituloController = TextEditingController();
  final _descController = TextEditingController();
  final HardwareService _hardware = HardwareService();

  String _categoria = 'INFRAESTRUCTURA';
  Position? _posicion;
  File? _foto;
  bool _obteniendoGps = false;

  Future<void> _capturarGPS() async {
    setState(() => _obteniendoGps = true);
    try {
      final pos = await _hardware.capturarUbicacionGPS();
      setState(() => _posicion = pos);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
        );
      }
    } finally {
      setState(() => _obteniendoGps = false);
    }
  }

  Future<void> _capturarCamara() async {
    final imagen = await _hardware.tomarFotografia();
    if (imagen != null) {
      setState(() => _foto = imagen);
    }
  }

  Future<void> _guardarEnSQLite() async {
    if (_tituloController.text.trim().isEmpty || _posicion == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Debe ingresar un título y capturar las coordenadas GPS.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final row = {
      'titulo': _tituloController.text.trim(),
      'descripcion': _descController.text.trim(),
      'categoria': _categoria,
      'latitud': _posicion!.latitude,
      'longitud': _posicion!.longitude,
      'foto_path': _foto?.path,
      'is_synced': 0,
      'fecha_creacion': DateTime.now().toIso8601String(),
    };

    await DatabaseHelper.instance.insertar(row);
    widget.onGuardado();
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
        left: 20,
        right: 20,
        top: 20,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Registrar Incidencia en Campo',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _tituloController,
              decoration: const InputDecoration(
                labelText: 'Título de la Incidencia',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _descController,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'Descripción técnica',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _categoria,
              decoration: const InputDecoration(border: OutlineInputBorder()),
              items: const [
                DropdownMenuItem(value: 'INFRAESTRUCTURA', child: Text('Infraestructura')),
                DropdownMenuItem(value: 'RED_ACCESO', child: Text('Red de Acceso')),
                DropdownMenuItem(value: 'TORRE_RADIO', child: Text('Torre de Radio')),
              ],
              onChanged: (v) => setState(() => _categoria = v!),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _obteniendoGps ? null : _capturarGPS,
                    icon: _obteniendoGps
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.my_location),
                    label: Text(
                      _posicion != null
                          ? 'GPS: ${_posicion!.latitude.toStringAsFixed(3)}, ${_posicion!.longitude.toStringAsFixed(3)}'
                          : 'Obtener GPS',
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                IconButton.filledTonal(
                  onPressed: _capturarCamara,
                  icon: const Icon(Icons.camera_alt),
                  tooltip: 'Tomar Fotografía',
                ),
              ],
            ),
            if (_foto != null) ...[
              const SizedBox(height: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.file(_foto!, height: 120, fit: BoxFit.cover),
              ),
            ],
            const SizedBox(height: 16),
            FilledButton(
              onPressed: _guardarEnSQLite,
              child: const Text('Guardar Localmente (Offline)'),
            ),
          ],
        ),
      ),
    );
  }
}
