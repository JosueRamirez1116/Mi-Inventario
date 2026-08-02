import 'package:cloud_firestore/cloud_firestore.dart';

/// Modelo que representa un producto dentro del inventario.
///
/// Corresponde a un documento de la colección `productos` en Cloud Firestore.
class ProductosModel {
  String? id; // ID del documento en Firestore (nulo antes de guardarse)
  String nombreProducto;
  String descripcion;
  String idCategoria; // ID de categoría
  String idNegocio; // ID de tienda/negocio
  String usuarioId; // ID del usuario autenticado
  String? codigoBarra; // Manual por ahora, opcional
  int estado; // 1 = activo, 0 = eliminado. Lo asigna el sistema, no el usuario.
  double stockMaximo;
  double stockMinimo;
  String unidadMedida;
  double stockActual; // Inventario inicial del producto
  double precioCompra;
  double precioVenta;
  String fotoProducto; // URL de la foto, vacío por ahora
  String codigoProducto; // Manual por ahora (luego será autoincremental)
  DateTime fechaCreacion;

  ProductosModel({
    this.id,
    required this.nombreProducto,
    required this.descripcion,
    required this.idCategoria,
    required this.idNegocio,
    required this.usuarioId,
    this.codigoBarra,
    this.estado = 1,
    required this.stockMaximo,
    required this.stockMinimo,
    required this.unidadMedida,
    required this.stockActual,
    required this.precioCompra,
    required this.precioVenta,
    this.fotoProducto = '',
    required this.codigoProducto,
    required this.fechaCreacion,
  });

  /// Crea una instancia a partir de un documento de Firestore.
  factory ProductosModel.desdeMapa(Map<String, dynamic> mapa, String id) {
    return ProductosModel(
      id: id,
      nombreProducto: mapa['nombreProducto'] ?? '',
      descripcion: mapa['descripcion'] ?? '',
      idCategoria: mapa['idCategoria'] ?? '',
      idNegocio: mapa['idNegocio'] ?? '',
      usuarioId: mapa['usuarioId']?.toString() ?? '',
      codigoBarra: mapa['codigoBarra'],
      estado: mapa['estado'] ?? 1,
      stockMaximo: (mapa['stockMaximo'] ?? 0).toDouble(),
      stockMinimo: (mapa['stockMinimo'] ?? 0).toDouble(),
      unidadMedida: mapa['unidadMedida'] ?? '',
      stockActual: (mapa['stockActual'] ?? 0).toDouble(),
      precioCompra: (mapa['precioCompra'] ?? 0).toDouble(),
      precioVenta: (mapa['precioVenta'] ?? 0).toDouble(),
      fotoProducto: mapa['fotoProducto'] ?? '',
      codigoProducto: mapa['codigoProducto'] ?? '',
      fechaCreacion: mapa['fechaCreacion'] != null
          ? (mapa['fechaCreacion'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }

  /// Convierte la instancia a un mapa listo para guardarse en Firestore.
  Map<String, dynamic> aMapa() {
    return {
      'nombreProducto': nombreProducto,
      'descripcion': descripcion,
      'idCategoria': idCategoria,
      'idNegocio': idNegocio,
      'usuarioId': usuarioId,
      'codigoBarra': codigoBarra,
      'estado': estado,
      'stockMaximo': stockMaximo,
      'stockMinimo': stockMinimo,
      'unidadMedida': unidadMedida,
      'stockActual': stockActual,
      'precioCompra': precioCompra,
      'precioVenta': precioVenta,
      'fotoProducto': fotoProducto,
      'codigoProducto': codigoProducto,
      'fechaCreacion': Timestamp.fromDate(fechaCreacion),
    };
  }
}
