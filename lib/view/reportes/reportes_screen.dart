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
  late final ReportesController _controller;

  DateTime? _fechaInicio;
  DateTime? _fechaFin;

  String _negocioSeleccionado = '';
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
            'Archivo generado, pero no se pudo abrir automáticamente: '
            '${resultado.message}',
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
    final colores = Theme.of(context).colorScheme;

    setState(() => _exportandoPdf = true);

    try {
      final rango = _controller.construirRangoSeleccionado(
        _fechaInicio,
        _fechaFin,
      );

      final ruta = await _controller.exportarPdf(
        movimientos: movimientos,
        rangoSeleccionado: rango,
      );

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'PDF generado en: $ruta',
            style: TextStyle(color: colores.onTertiary),
          ),
          backgroundColor: colores.tertiary,
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
    final colores = Theme.of(context).colorScheme;

    setState(() => _exportandoExcel = true);

    try {
      final rango = _controller.construirRangoSeleccionado(
        _fechaInicio,
        _fechaFin,
      );

      final ruta = await _controller.exportarExcel(
        movimientos: movimientos,
        rangoSeleccionado: rango,
      );

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Excel generado en: $ruta',
            style: TextStyle(color: colores.onTertiary),
          ),
          backgroundColor: colores.tertiary,
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
      _negocioSeleccionado = '';
      _categoriaSeleccionada = '';
      _productoSeleccionado = '';
    });
  }

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final colores = tema.colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Reportes')),
      body: StreamBuilder<List<ReporteMovimientoModel>>(
        stream: _controller.obtenerMovimientosParaReporte(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(
              child: Text('No se pudo cargar la información'),
            );
          }

          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final movimientos = snapshot.data!;

          final negocios = <String, String>{};

          final categorias = <String, String>{};

          final productos = <String, String>{};

          for (final item in movimientos) {
            negocios[item.idNegocio] = item.negocio;
          }

          for (final item in movimientos) {
            final coincideNegocio =
                _negocioSeleccionado.isEmpty ||
                item.idNegocio == _negocioSeleccionado;

            if (coincideNegocio) {
              categorias[item.idCategoria] = item.categoria;
            }
          }

          for (final item in movimientos) {
            final coincideNegocio =
                _negocioSeleccionado.isEmpty ||
                item.idNegocio == _negocioSeleccionado;

            final coincideCategoria =
                _categoriaSeleccionada.isEmpty ||
                item.idCategoria == _categoriaSeleccionada;

            if (coincideNegocio && coincideCategoria) {
              productos[item.idProducto] = item.producto;
            }
          }

          if (_categoriaSeleccionada.isNotEmpty &&
              !categorias.containsKey(_categoriaSeleccionada)) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (!mounted) {
                return;
              }

              setState(() {
                _categoriaSeleccionada = '';
                _productoSeleccionado = '';
              });
            });
          }

          if (_productoSeleccionado.isNotEmpty &&
              !productos.containsKey(_productoSeleccionado)) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (!mounted) {
                return;
              }

              setState(() => _productoSeleccionado = '');
            });
          }

          final movimientosFiltrados = _controller.filtrarMovimientos(
            movimientos: movimientos,
            fechaInicio: _fechaInicio,
            fechaFin: _fechaFin,
            negocioId: _negocioSeleccionado,
            categoriaId: _categoriaSeleccionada,
            productoId: _productoSeleccionado,
          );

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Card(
                  margin: EdgeInsets.zero,
                  child: Padding(
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
                                      : _controller.formatearFecha(
                                          _fechaInicio!,
                                        ),
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

                        DropdownButtonFormField<String>(
                          key: ValueKey('negocio-$_negocioSeleccionado'),
                          initialValue: _negocioSeleccionado.isEmpty
                              ? null
                              : _negocioSeleccionado,
                          decoration: const InputDecoration(
                            labelText: 'Negocio',
                            prefixIcon: Icon(Icons.storefront_outlined),
                          ),
                          isExpanded: true,
                          items: negocios.entries.map((entry) {
                            return DropdownMenuItem<String>(
                              value: entry.key,
                              child: Text(
                                entry.value.isEmpty
                                    ? 'Sin negocio'
                                    : entry.value,
                              ),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setState(() {
                              _negocioSeleccionado = value ?? '';

                              _categoriaSeleccionada = '';

                              _productoSeleccionado = '';
                            });
                          },
                        ),

                        const SizedBox(height: 10),

                        Row(
                          children: [
                            Expanded(
                              child: DropdownButtonFormField<String>(
                                key: ValueKey(
                                  'categoria-$_categoriaSeleccionada',
                                ),
                                initialValue: _categoriaSeleccionada.isEmpty
                                    ? null
                                    : _categoriaSeleccionada,
                                decoration: const InputDecoration(
                                  labelText: 'Categoría',
                                  prefixIcon: Icon(Icons.category_outlined),
                                ),
                                isExpanded: true,
                                items: categorias.entries.map((entry) {
                                  return DropdownMenuItem<String>(
                                    value: entry.key,
                                    child: Text(
                                      entry.value.isEmpty
                                          ? 'Sin categoría'
                                          : entry.value,
                                    ),
                                  );
                                }).toList(),
                                onChanged: (value) {
                                  setState(() {
                                    _categoriaSeleccionada = value ?? '';

                                    _productoSeleccionado = '';
                                  });
                                },
                              ),
                            ),

                            const SizedBox(width: 8),

                            Expanded(
                              child: DropdownButtonFormField<String>(
                                key: ValueKey(
                                  'producto-$_productoSeleccionado',
                                ),
                                initialValue: _productoSeleccionado.isEmpty
                                    ? null
                                    : _productoSeleccionado,
                                decoration: const InputDecoration(
                                  labelText: 'Producto',
                                  prefixIcon: Icon(Icons.inventory_2_outlined),
                                ),
                                isExpanded: true,
                                items: productos.entries.map((entry) {
                                  return DropdownMenuItem<String>(
                                    value: entry.key,
                                    child: Text(
                                      entry.value.isEmpty
                                          ? 'Sin producto'
                                          : entry.value,
                                    ),
                                  );
                                }).toList(),
                                onChanged: (value) {
                                  setState(
                                    () => _productoSeleccionado = value ?? '',
                                  );
                                },
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 10),

                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: _limpiarFiltros,
                            icon: const Icon(Icons.filter_alt_off),
                            label: const Text('Limpiar filtros'),
                          ),
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
                                    ? SizedBox(
                                        height: 16,
                                        width: 16,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: colores.onError,
                                        ),
                                      )
                                    : const Icon(Icons.picture_as_pdf),
                                label: Text(
                                  _exportandoPdf
                                      ? 'Exportando...'
                                      : 'Exportar PDF',
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: colores.error,
                                  foregroundColor: colores.onError,
                                ),
                              ),
                            ),

                            const SizedBox(width: 8),

                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: _exportandoExcel
                                    ? null
                                    : () =>
                                          _exportarExcel(movimientosFiltrados),
                                icon: _exportandoExcel
                                    ? SizedBox(
                                        height: 16,
                                        width: 16,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: colores.onTertiary,
                                        ),
                                      )
                                    : const Icon(Icons.table_chart),
                                label: Text(
                                  _exportandoExcel
                                      ? 'Exportando...'
                                      : 'Exportar Excel',
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: colores.tertiary,
                                  foregroundColor: colores.onTertiary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              Expanded(
                child: movimientosFiltrados.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.description_outlined,
                              size: 60,
                              color: colores.onSurfaceVariant.withValues(
                                alpha: 0.65,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'No hay movimientos para generar reporte',
                              style: tema.textTheme.bodyLarge?.copyWith(
                                color: colores.onSurfaceVariant,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                        itemCount: movimientosFiltrados.length,
                        itemBuilder: (context, index) {
                          final item = movimientosFiltrados[index];

                          final esEntrada = item.tipoMovimiento == 'Entrada';

                          final colorTipo = esEntrada
                              ? colores.tertiary
                              : colores.error;

                          return Card(
                            margin: const EdgeInsets.only(bottom: 8),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: colorTipo.withValues(
                                  alpha: 0.15,
                                ),
                                child: Icon(
                                  esEntrada
                                      ? Icons.arrow_downward
                                      : Icons.arrow_upward,
                                  color: colorTipo,
                                ),
                              ),
                              title: Text(
                                item.producto,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              subtitle: Text(
                                '${item.tipoMovimiento} • '
                                '${_controller.formatearFecha(item.fechaMovimiento)}\n'
                                'Categoría: ${item.categoria} • '
                                'Negocio: ${item.negocio}',
                              ),
                              isThreeLine: true,
                              trailing: Text(
                                item.cantidad.toStringAsFixed(2),
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: colorTipo,
                                ),
                              ),
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
