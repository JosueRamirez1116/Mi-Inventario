import 'package:cloud_firestore/cloud_firestore.dart';

class MovimientoModel {
  final String id;
  final String idProducto;
  final String nombreProducto;
  final String codigoProducto;
  final String idCategoria;
  final String idNegocio;
  final String tipoMovimiento;
  final double cantidad;
  final double stockAnterior;
  final double stockNuevo;
  final int estado;
  final DateTime fechaMovimiento;

  const MovimientoModel({
    required this.id,
    required this.idProducto,
    required this.nombreProducto,
    required this.codigoProducto,
    required this.idCategoria,
    required this.idNegocio,
    required this.tipoMovimiento,
    required this.cantidad,
    required this.stockAnterior,
    required this.stockNuevo,
    required this.estado,
    required this.fechaMovimiento,
  });

  factory MovimientoModel.fromMap(String id, Map<String, dynamic> data) {
    final fecha = data['fechaMovimiento'];
    final fechaMovimiento = fecha is Timestamp ? fecha.toDate() : DateTime.now();

    return MovimientoModel(
      id: id,
      idProducto: (data['idProducto'] ?? '').toString(),
      nombreProducto: (data['nombreProducto'] ?? '').toString(),
      codigoProducto: (data['codigoProducto'] ?? '').toString(),
      idCategoria: (data['idCategoria'] ?? '').toString(),
      idNegocio: (data['idNegocio'] ?? '').toString(),
      tipoMovimiento: (data['tipoMovimiento'] ?? '').toString(),
      cantidad: (data['cantidad'] as num?)?.toDouble() ?? 0,
      stockAnterior: (data['stockAnterior'] as num?)?.toDouble() ?? 0,
      stockNuevo: (data['stockNuevo'] as num?)?.toDouble() ?? 0,
      estado: (data['estado'] as num?)?.toInt() ?? 1,
      fechaMovimiento: fechaMovimiento,
    );
  }
}
