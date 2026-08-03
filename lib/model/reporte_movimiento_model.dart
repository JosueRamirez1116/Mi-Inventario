class ReporteMovimientoModel {
  final String idMovimiento;
  final String idProducto;
  final String idCategoria;
  final String idNegocio;
  final String producto;
  final String codigoProducto;
  final String categoria;
  final String negocio;
  final String tipoMovimiento;
  final DateTime fechaMovimiento;
  final double cantidad;

  const ReporteMovimientoModel({
    required this.idMovimiento,
    required this.idProducto,
    required this.idCategoria,
    required this.idNegocio,
    required this.producto,
    required this.codigoProducto,
    required this.categoria,
    required this.negocio,
    required this.tipoMovimiento,
    required this.fechaMovimiento,
    required this.cantidad,
  });
}
