/// Una zona del catálogo (`public.zonas`), tal como la ve el conductor al
/// elegir dónde trabaja.
///
/// No trae el polígono: PostgREST devuelve `geography` en un formato binario
/// que la app no sabe leer. La forma para el mapa sale de la copia local de
/// `core/geo/zonas_maracaibo.dart`, emparejada por [nombre]. Cuando el
/// catálogo deje de ser provisional, el polígono debe llegar del servidor con
/// `ST_AsGeoJSON` (ver el comentario de ese archivo).
class Zona {
  const Zona({required this.id, required this.nombre, required this.municipio});

  factory Zona.fromMap(Map<String, dynamic> map) {
    return Zona(
      id: map['id'] as String,
      nombre: map['nombre'] as String,
      municipio: map['municipio'] as String,
    );
  }

  final String id;
  final String nombre;
  final String municipio;

  @override
  bool operator ==(Object other) => other is Zona && other.id == id;

  @override
  int get hashCode => id.hashCode;
}
