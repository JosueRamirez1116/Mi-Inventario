import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mi_inventario/controller/reportes_controller.dart';
import 'package:mi_inventario/model/reporte_movimiento_model.dart';
import 'package:open_filex/open_filex.dart';

class ReportesScreen extends StatefulWidget {
  const ReportesScreen({super.key});

  @override
  State<ReportesScreen> createState() => _ReportesScreenState();
}

class _ReportesScreenState extends State<ReportesScreen> {
  static const Color _colorPrincipal = Color.fromARGB(255, 28, 83, 170);
  late final ReportesController _controller;

  DateTime? _fechaInicio;
  DateTime? _fechaFin;
  String _categoriaSeleccionada = '';
  String _productoSeleccionado = '';
  bool _exportandoPdf = false;
  bool _exportandoExcel = false;

  Future<void> _abrirArchivoExportado(String rutaArchivo) async {
    final resultado = await OpenFilex.open(rutaArchivo);
    if (!mounted) {
      return;
    }

    if (resultado.type != ResultType.done) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Archivo generado, pero no se pudo abrir automáticamente: ${resultado.message}',
          ),
        ),
      );
    }
  }

  @override
  void initState() {
    super.initState();
    if (Get.isRegistered<ReportesController>()) {
      _controller = Get.find<ReportesController>();
    } else {
      _controller = Get.put(ReportesController());
    }
  }

  Future<void> _seleccionarFechaInicio() async {
    final seleccionada = await showDatePicker(
      context: context,
      initialDate: _fechaInicio ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (seleccionada == null) {
      return;
    }
    setState(() {
      _fechaInicio = DateTime(
        seleccionada.year,
        seleccionada.month,
        seleccionada.day,
      );
    });
  }

  Future<void> _seleccionarFechaFin() async {
    final seleccionada = await showDatePicker(
      context: context,
      initialDate: _fechaFin ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (seleccionada == null) {
      return;
    }
    setState(() {
      _fechaFin = DateTime(
        seleccionada.year,
        seleccionada.month,
        seleccionada.day,
        23,
        59,
        59,
      );
    });
  }

  Future<void> _exportarPdf(List<ReporteMovimientoModel> movimientos) async {
    setState(() => _exportandoPdf = true);
    try {
      final rango = _controller.construirRangoSeleccionado(_fechaInicio, _fechaFin);
      final ruta = await _controller.exportarPdf(
        movimientos: movimientos,
        rangoSeleccionado: rango,
      );
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('PDF generado en: $ruta'),
          backgroundColor: Colors.green,
        ),
      );
      await _abrirArchivoExportado(ruta);
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo exportar PDF: $error')),
      );
    } finally {
      if (mounted) {
        setState(() => _exportandoPdf = false);
      }
    }
  }

  Future<void> _exportarExcel(List<ReporteMovimientoModel> movimientos) async {
    setState(() => _exportandoExcel = true);
    try {
      final rango = _controller.construirRangoSeleccionado(_fechaInicio, _fechaFin);
      final ruta = await _controller.exportarExcel(
        movimientos: movimientos,
        rangoSeleccionado: rango,
      );
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Excel generado en: $ruta'),
          backgroundColor: Colors.green,
        ),
      );
      await _abrirArchivoExportado(ruta);
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo exportar Excel: $error')),
      );
    } finally {
      if (mounted) {
        setState(() => _exportandoExcel = false);
      }
    }
  }

  void _limpiarFiltros() {
    setState(() {
      _fechaInicio = null;
      _fechaFin = null;
      _categoriaSeleccionada = '';
      _productoSeleccionado = '';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 248, 244, 250),
      appBar: AppBar(
        title: const Text('Reportes'),
        backgroundColor: _colorPrincipal,
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<List<ReporteMovimientoModel>>(
        stream: _controller.obtenerMovimientosParaReporte(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(child: Text('No se pudo cargar la información'));
          }

          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final movimientos = snapshot.data!;
          final categorias = <String, String>{};
          final productos = <String, String>{};

          for (final item in movimientos) {
            categorias[item.idCategoria] = item.categoria;
            productos[item.idProducto] = item.producto;
          }

          final movimientosFiltrados = _controller.filtrarMovimientos(
            movimientos: movimientos,
            fechaInicio: _fechaInicio,
            fechaFin: _fechaFin,
            categoriaId: _categoriaSeleccionada,
            productoId: _productoSeleccionado,
          );

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _seleccionarFechaInicio,
                            icon: const Icon(Icons.calendar_today),
                            label: Text(
                              _fechaInicio == null
                                  ? 'Fecha inicio'
                                  : _controller.formatearFecha(_fechaInicio!),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _seleccionarFechaFin,
                            icon: const Icon(Icons.calendar_month),
                            label: Text(
                              _fechaFin == null
                                  ? 'Fecha fin'
                                  : _controller.formatearFecha(_fechaFin!),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            key: ValueKey('categoria-$_categoriaSeleccionada'),
                            initialValue: _categoriaSeleccionada.isEmpty
                                ? null
                                : _categoriaSeleccionada,
                            decoration: const InputDecoration(
                              labelText: 'Categoría',
                              border: OutlineInputBorder(),
                            ),
                            items: categorias.entries.map((entry) {
                              return DropdownMenuItem<String>(
                                value: entry.key,
                                child: Text(entry.value.isEmpty ? 'Sin categoría' : entry.value),
                              );
                            }).toList(),
                            onChanged: (value) {
                              setState(() => _categoriaSeleccionada = value ?? '');
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            key: ValueKey('producto-$_productoSeleccionado'),
                            initialValue: _productoSeleccionado.isEmpty
                                ? null
                                : _productoSeleccionado,
                            decoration: const InputDecoration(
                              labelText: 'Producto',
                              border: OutlineInputBorder(),
                            ),
                            items: productos.entries.map((entry) {
                              return DropdownMenuItem<String>(
                                value: entry.key,
                                child: Text(entry.value.isEmpty ? 'Sin producto' : entry.value),
                              );
                            }).toList(),
                            onChanged: (value) {
                              setState(() => _productoSeleccionado = value ?? '');
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _limpiarFiltros,
                            icon: const Icon(Icons.filter_alt_off),
                            label: const Text('Limpiar filtros'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _exportandoPdf
                                ? null
                                : () => _exportarPdf(movimientosFiltrados),
                            icon: _exportandoPdf
                                ? const SizedBox(
                                    height: 16,
                                    width: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Icon(Icons.picture_as_pdf),
                            label: Text(_exportandoPdf ? 'Exportando...' : 'Exportar PDF'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _exportandoExcel
                                ? null
                                : () => _exportarExcel(movimientosFiltrados),
                            icon: _exportandoExcel
                                ? const SizedBox(
                                    height: 16,
                                    width: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Icon(Icons.table_chart),
                            label: Text(
                              _exportandoExcel ? 'Exportando...' : 'Exportar Excel',
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Expanded(
                child: movimientosFiltrados.isEmpty
                    ? const Center(
                        child: Text('No hay movimientos para generar reporte'),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                        itemCount: movimientosFiltrados.length,
                        itemBuilder: (context, index) {
                          final item = movimientosFiltrados[index];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 8),
                            child: ListTile(
                              title: Text(item.producto),
                              subtitle: Text(
                                '${item.tipoMovimiento} • ${_controller.formatearFecha(item.fechaMovimiento)}\n'
                                'Categoría: ${item.categoria} • Negocio: ${item.negocio}',
                              ),
                              isThreeLine: true,
                              trailing: Text(item.cantidad.toStringAsFixed(2)),
                            ),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}
