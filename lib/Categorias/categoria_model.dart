class CategoriaModel {
  final String? id; // ID del documento en Firestore (null si aún no se crea)
  final String nombre;
  final String descripcion;
  final int estado; // 1 = activo, 0 = eliminado (borrado lógico)
  final String negocioId; // a qué negocio pertenece la categoría

  CategoriaModel({
    this.id,
    required this.nombre,
    required this.descripcion,
    this.estado = 1,
    required this.negocioId,
  });

  // Convertir de Firestore -> Objeto Dart
  factory CategoriaModel.fromMap(Map<String, dynamic> data, String id) {
    return CategoriaModel(
      id: id,
      nombre: data['nombre'] ?? '',
      descripcion: data['descripcion'] ?? '',
      estado: data['estado'] ?? 1,
      negocioId: data['negocioId'] ?? '',
    );
  }

  // Convertir de Objeto Dart -> Firestore
  Map<String, dynamic> toMap() {
    return {
      'nombre': nombre,
      'descripcion': descripcion,
      'estado': estado,
      'negocioId': negocioId,
    };
  }

  // Util para editar sin tener que reescribir todo el objeto
  CategoriaModel copyWith({
    String? nombre,
    String? descripcion,
    int? estado,
  }) {
    return CategoriaModel(
      id: id,
      nombre: nombre ?? this.nombre,
      descripcion: descripcion ?? this.descripcion,
      estado: estado ?? this.estado,
      negocioId: negocioId,
    );
  }
}