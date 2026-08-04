import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:excel/excel.dart';
import 'package:get/get.dart';
import 'package:mi_inventario/model/reporte_movimiento_model.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

class ReportesController extends GetxController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _movimientosRef {
    return _firestore.collection('movimientos');
  }

  CollectionReference<Map<String, dynamic>> get _categoriasRef {
    return _firestore.collection('categorias');
  }

  CollectionReference<Map<String, dynamic>> get _negociosRef {
    return _firestore.collection('negocios');
  }

  Stream<List<ReporteMovimientoModel>> obtenerMovimientosParaReporte() {
    return _movimientosRef
        .where('estado', isEqualTo: 1)
        .snapshots()
        .asyncMap((movimientosSnapshot) async {
          final categoriasSnapshot = await _categoriasRef.get();
          final negociosSnapshot = await _negociosRef.get();

          final categoriasPorId = <String, String>{
            for (final categoria in categoriasSnapshot.docs)
              categoria.id: (categoria.data()['nombre'] ?? '').toString(),
          };

          final negociosPorId = <String, String>{
            for (final negocio in negociosSnapshot.docs)
              negocio.id: (negocio.data()['nombre'] ?? '').toString(),
          };

          final movimientos = movimientosSnapshot.docs.map((doc) {
            final data = doc.data();
            final fecha = data['fechaMovimiento'];
            final fechaMovimiento = fecha is Timestamp
                ? fecha.toDate()
                : DateTime.now();

            final idCategoria = (data['idCategoria'] ?? '').toString();
            final idNegocio = (data['idNegocio'] ?? '').toString();

            return ReporteMovimientoModel(
              idMovimiento: doc.id,
              idProducto: (data['idProducto'] ?? '').toString(),
              idCategoria: idCategoria,
              idNegocio: idNegocio,
              producto: (data['nombreProducto'] ?? '').toString(),
              codigoProducto: (data['codigoProducto'] ?? '').toString(),
              categoria: categoriasPorId[idCategoria] ?? 'Sin categoría',
              negocio: negociosPorId[idNegocio] ?? 'Sin negocio',
              tipoMovimiento: (data['tipoMovimiento'] ?? '').toString(),
              fechaMovimiento: fechaMovimiento,
              cantidad: (data['cantidad'] as num?)?.toDouble() ?? 0,
            );
          }).toList();

          movimientos.sort(
            (a, b) => b.fechaMovimiento.compareTo(a.fechaMovimiento),
          );

          return movimientos;
        });
  }

  List<ReporteMovimientoModel> filtrarMovimientos({
    required List<ReporteMovimientoModel> movimientos,
    DateTime? fechaInicio,
    DateTime? fechaFin,
    String categoriaId = '',
    String productoId = '',
  }) {
    return movimientos.where((movimiento) {
      if (categoriaId.isNotEmpty && movimiento.idCategoria != categoriaId) {
        return false;
      }

      if (productoId.isNotEmpty && movimiento.idProducto != productoId) {
        return false;
      }

      if (fechaInicio != null && movimiento.fechaMovimiento.isBefore(fechaInicio)) {
        return false;
      }

      if (fechaFin != null && movimiento.fechaMovimiento.isAfter(fechaFin)) {
        return false;
      }

      return true;
    }).toList();
  }

  String formatearFecha(DateTime fecha) {
    final dia = fecha.day.toString().padLeft(2, '0');
    final mes = fecha.month.toString().padLeft(2, '0');
    final anio = fecha.year.toString();
    final hora = fecha.hour.toString().padLeft(2, '0');
    final minuto = fecha.minute.toString().padLeft(2, '0');
    return '$dia/$mes/$anio $hora:$minuto';
  }

  String construirRangoSeleccionado(DateTime? fechaInicio, DateTime? fechaFin) {
    final inicio = fechaInicio == null ? 'Sin inicio' : formatearFecha(fechaInicio);
    final fin = fechaFin == null ? 'Sin fin' : formatearFecha(fechaFin);
    return '$inicio - $fin';
  }

  Future<String> exportarPdf({
    required List<ReporteMovimientoModel> movimientos,
    required String rangoSeleccionado,
  }) async {
    if (movimientos.isEmpty) {
      throw Exception('No hay datos para exportar');
    }

    final documento = pw.Document();

    final filas = movimientos.map((movimiento) {
      return <String>[
        movimiento.producto,
        movimiento.codigoProducto,
        movimiento.categoria,
        movimiento.tipoMovimiento,
        formatearFecha(movimiento.fechaMovimiento),
        movimiento.cantidad.toStringAsFixed(2),
        rangoSeleccionado,
        movimiento.negocio,
      ];
    }).toList();

    documento.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4.landscape,
        build: (context) {
          return [
            pw.Text(
              'Reporte de entradas y salidas',
              style: pw.TextStyle(
                fontSize: 16,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
            pw.SizedBox(height: 8),
            pw.Text('Rango seleccionado: $rangoSeleccionado'),
            pw.SizedBox(height: 12),
            pw.TableHelper.fromTextArray(
              headers: const [
                'Producto',
                'Código',
                'Categoría',
                'Tipo',
                'Fecha',
                'Cantidad',
                'Rango',
                'Negocio',
              ],
              data: filas,
              headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
              headerDecoration: const pw.BoxDecoration(
                color: PdfColors.grey300,
              ),
              cellAlignment: pw.Alignment.centerLeft,
              cellStyle: const pw.TextStyle(fontSize: 9),
            ),
          ];
        },
      ),
    );

    final directorio = await getApplicationDocumentsDirectory();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final archivo = File('${directorio.path}/reporte_movimientos_$timestamp.pdf');
    await archivo.writeAsBytes(await documento.save());
    return archivo.path;
  }

  Future<String> exportarExcel({
    required List<ReporteMovimientoModel> movimientos,
    required String rangoSeleccionado,
  }) async {
    if (movimientos.isEmpty) {
      throw Exception('No hay datos para exportar');
    }

    final excel = Excel.createExcel();
    final hoja = excel['Reporte'];

    hoja.appendRow([
      TextCellValue('Producto'),
      TextCellValue('Código de producto'),
      TextCellValue('Categoría'),
      TextCellValue('Tipo de movimiento'),
      TextCellValue('Fecha de movimiento'),
      TextCellValue('Cantidad'),
      TextCellValue('Rango de fecha seleccionado'),
      TextCellValue('Nombre del negocio'),
    ]);

    for (final movimiento in movimientos) {
      hoja.appendRow([
        TextCellValue(movimiento.producto),
        TextCellValue(movimiento.codigoProducto),
        TextCellValue(movimiento.categoria),
        TextCellValue(movimiento.tipoMovimiento),
        TextCellValue(formatearFecha(movimiento.fechaMovimiento)),
        DoubleCellValue(movimiento.cantidad),
        TextCellValue(rangoSeleccionado),
        TextCellValue(movimiento.negocio),
      ]);
    }

    final bytes = excel.save();
    if (bytes == null) {
      throw Exception('No se pudo generar el archivo de Excel');
    }

    final directorio = await getApplicationDocumentsDirectory();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final archivo = File('${directorio.path}/reporte_movimientos_$timestamp.xlsx');
    await archivo.writeAsBytes(bytes, flush: true);
    return archivo.path;
  }
}
