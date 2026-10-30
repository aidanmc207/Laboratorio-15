# Laboratorio 15 - FieldTech Móvil

IF0009 - Desarrollo de Software IV, Universidad de Costa Rica, Sede del Atlántico.

Sistema de inspecciones técnicas en campo con arquitectura Offline-First. La app móvil
guarda las incidencias en SQLite con coordenadas GPS y foto, y las sincroniza con un
backend Spring Boot 3 cuando hay conexión.

## Estructura

```
fieldtech-backend/     Spring Boot 3 + H2 (domain, data, business, controller)
fieldtech_mobile/      Flutter 3 (models, data, services, screens)
```

## Backend

Requisitos: Java 21 y Maven.

```bash
cd fieldtech-backend
mvn spring-boot:run
```

- API: `http://localhost:8080/api/v1/incidencias`
- Consola H2: `http://localhost:8080/h2-console` (JDBC URL `jdbc:h2:mem:fieldtechdb`, usuario `sa`)

| Método | Ruta | Descripción |
|---|---|---|
| GET | `/api/v1/incidencias` | Lista todas las incidencias |
| POST | `/api/v1/incidencias` | Registra una incidencia (`multipart/form-data`, campo `foto` opcional) |

## App móvil

```bash
cd fieldtech_mobile
flutter pub get
flutter run
```

La app apunta a `http://10.0.2.2:8080` (máquina anfitriona vista desde el emulador).
En un teléfono físico se cambia por la IP privada de la computadora en
`lib/screens/incidencias_screen.dart`.

Flujo:

1. **Nueva Incidencia**: título, descripción, categoría, GPS y foto.
2. **Guardar Localmente**: se inserta en SQLite con `is_synced = 0`.
3. Botón de sincronizar: envía las pendientes por multipart y las marca con `is_synced = 1`.
4. Filtro segmentado (Todas / Offline / Sincronizadas) que consulta SQLite con `WHERE`.

## Verificación y errores comunes

- **`SocketException: Connection refused`**: en el emulador `localhost` es el propio Android,
  usar `10.0.2.2`. También se requiere `android:usesCleartextTraffic="true"` en el manifiesto.
- **`TimeoutException` al obtener GPS**: en el AVD abrir *Extended controls → Location*,
  ingresar Latitud `9.9322`, Longitud `-84.0795` y pulsar *Set Location*.
- **`geolocator ^12.0.0` no tiene `locationSettings`**: ese parámetro llegó en la versión 13,
  por eso el `pubspec.yaml` usa `^13.0.0`.
- **Error de caché incremental de Kotlin al compilar**: ocurre cuando el proyecto y la caché
  de pub están en unidades distintas (D: y C:). Se resolvió con `kotlin.incremental=false`
  en `android/gradle.properties`.
- **El emulador no arranca (`x86_64 emulation currently requires hardware acceleration`)**:
  instalar el *Android Emulator Hypervisor Driver* o habilitar WHPX como administrador y reiniciar.
