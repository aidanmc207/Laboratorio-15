import 'dart:io';
import 'package:http/http.dart' as http;
import '../data/database_helper.dart';

class SyncService {
  final String backendUrl;
  final DatabaseHelper dbHelper = DatabaseHelper.instance;

  SyncService({required this.backendUrl});

  Future<int> ejecutarSincronizacion(String codigoTecnico) async {
    final List<Map<String, dynamic>> pendientes = await dbHelper.obtenerPendientes();
    if (pendientes.isEmpty) return 0;

    int enviadasConExito = 0;

    for (final inc in pendientes) {
      final int localId = inc['id'] as int;
      final uri = Uri.parse('$backendUrl/api/v1/incidencias');
      final request = http.MultipartRequest('POST', uri);

      request.fields['titulo'] = inc['titulo'];
      request.fields['descripcion'] = inc['descripcion'];
      request.fields['categoria'] = inc['categoria'];
      request.fields['latitud'] = inc['latitud'].toString();
      request.fields['longitud'] = inc['longitud'].toString();
      request.fields['tecnicoCodigo'] = codigoTecnico;

      final String? rutaFoto = inc['foto_path'];
      if (rutaFoto != null && File(rutaFoto).existsSync()) {
        request.files.add(
          await http.MultipartFile.fromPath('foto', rutaFoto),
        );
      }

      try {
        final streamedRes = await request.send().timeout(
          const Duration(seconds: 15),
        );
        if (streamedRes.statusCode == 200) {
          await dbHelper.marcarSincronizado(localId);
          enviadasConExito++;
        }
      } catch (e) {
        // Sin señal: se corta la cola y se reintenta en la siguiente sincronizacion
        break;
      }
    }
    return enviadasConExito;
  }
}
