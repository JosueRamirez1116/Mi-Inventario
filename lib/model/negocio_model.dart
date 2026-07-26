class NegocioModel {
  final String id;
  final String nombre;
  final String direccion;
  final String telefono;
  final String correo;
  final int estado;

  const NegocioModel({
    this.id = '',
    required this.nombre,
    required this.direccion,
    required this.telefono,
    required this.correo,
    this.estado = 1,
  });

  factory NegocioModel.fromMap(String id, Map<String, dynamic> datos) {
    return NegocioModel(
      id: id,
      nombre: datos['nombre']?.toString() ?? '',
      direccion: datos['direccion']?.toString() ?? '',
      telefono: datos['telefono']?.toString() ?? '',
      correo: datos['correo']?.toString() ?? '',
      estado: (datos['estado'] as num?)?.toInt() ?? 1,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'nombre': nombre,
      'direccion': direccion,
      'telefono': telefono,
      'correo': correo,
      'estado': estado,
    };
  }

  NegocioModel copyWith({
    String? id,
    String? nombre,
    String? direccion,
    String? telefono,
    String? correo,
    int? estado,
  }) {
    return NegocioModel(
      id: id ?? this.id,
      nombre: nombre ?? this.nombre,
      direccion: direccion ?? this.direccion,
      telefono: telefono ?? this.telefono,
      correo: correo ?? this.correo,
      estado: estado ?? this.estado,
    );
  }
}
