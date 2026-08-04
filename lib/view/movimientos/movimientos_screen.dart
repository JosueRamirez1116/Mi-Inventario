import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mi_inventario/controller/movimientos_controller.dart';
import 'package:mi_inventario/model/movimiento_model.dart';

class MovimientosScreen extends StatefulWidget {
  const MovimientosScreen({super.key});

  @override
  State<MovimientosScreen> createState() => _MovimientosScreenState();
}

class _MovimientosScreenState extends State<MovimientosScreen> {
  static const Color _colorPrincipal = Color.fromARGB(255, 28, 83, 170);
  late final MovimientosController _controller;

  DateTime? _fechaInicio;
  DateTime? _fechaFin;
  String _tipoMovimiento = 'Todos';

  @override
  void initState() {
    super.initState();
    if (Get.isRegistered<MovimientosController>()) {
      _controller = Get.find<MovimientosController>();
    } else {
      _controller = Get.put(MovimientosController());
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
    setState(() => _fechaInicio = DateTime(seleccionada.year, seleccionada.month, seleccionada.day));
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

  String _formatearFecha(DateTime fecha) {
    final dia = fecha.day.toString().padLeft(2, '0');
    final mes = fecha.month.toString().padLeft(2, '0');
    final anio = fecha.year.toString();
    final hora = fecha.hour.toString().padLeft(2, '0');
    final minuto = fecha.minute.toString().padLeft(2, '0');
    return '$dia/$mes/$anio $hora:$minuto';
  }

  List<MovimientoModel> _filtrarMovimientos(List<MovimientoModel> movimientos) {
    return movimientos.where((movimiento) {
      if (_tipoMovimiento != 'Todos' && movimiento.tipoMovimiento != _tipoMovimiento) {
        return false;
      }

      if (_fechaInicio != null && movimiento.fechaMovimiento.isBefore(_fechaInicio!)) {
        return false;
      }

      if (_fechaFin != null && movimiento.fechaMovimiento.isAfter(_fechaFin!)) {
        return false;
      }

      return true;
    }).toList();
  }

  Future<void> _mostrarDialogoEdicion(MovimientoModel movimiento) async {
    String tipoSeleccionado = movimiento.tipoMovimiento;
    final cantidadController = TextEditingController(
      text: movimiento.cantidad.toString(),
    );
    bool guardando = false;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Editar movimiento'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<String>(
                    key: ValueKey('tipo-${movimiento.id}-$tipoSeleccionado'),
                    initialValue: tipoSeleccionado,
                    decoration: const InputDecoration(
                      labelText: 'Tipo de movimiento',
                    ),
                    items: const [
                      DropdownMenuItem(value: 'Entrada', child: Text('Entrada')),
                      DropdownMenuItem(value: 'Salida', child: Text('Salida')),
                    ],
                    onChanged: guardando
                        ? null
                        : (value) {
                            if (value == null) {
                              return;
                            }
                            setDialogState(() => tipoSeleccionado = value);
                          },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: cantidadController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(labelText: 'Cantidad'),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: guardando
                      ? null
                      : () => Navigator.of(dialogContext).pop(),
                  child: const Text('Cancelar'),
                ),
                FilledButton(
                  onPressed: guardando
                      ? null
                      : () async {
                          final nuevaCantidad = double.tryParse(
                            cantidadController.text.trim(),
                          );
                          if (nuevaCantidad == null || nuevaCantidad <= 0) {
                            ScaffoldMessenger.of(dialogContext).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Ingresa una cantidad válida mayor a 0',
                                ),
                              ),
                            );
                            return;
                          }

                          setDialogState(() => guardando = true);
                          try {
                            await _controller.editarMovimiento(
                              movimiento: movimiento,
                              nuevoTipoMovimiento: tipoSeleccionado,
                              nuevaCantidad: nuevaCantidad,
                            );

                            if (!dialogContext.mounted) {
                              return;
                            }
                            Navigator.of(dialogContext).pop();
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Movimiento actualizado correctamente'),
                                backgroundColor: Colors.green,
                              ),
                            );
                          } catch (error) {
                            setDialogState(() => guardando = false);
                            ScaffoldMessenger.of(dialogContext).showSnackBar(
                              SnackBar(content: Text('No se pudo actualizar: $error')),
                            );
                          }
                        },
                  child: guardando
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text('Guardar'),
                ),
              ],
            );
          },
        );
      },
    );

    cantidadController.dispose();
  }

  Future<void> _confirmarEliminacion(MovimientoModel movimiento) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Eliminar movimiento'),
          content: Text(
            '¿Deseas eliminar este registro de ${movimiento.tipoMovimiento.toLowerCase()}?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Eliminar'),
            ),
          ],
        );
      },
    );

    if (confirmar != true) {
      return;
    }

    try {
      await _controller.eliminarMovimiento(movimiento);
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Movimiento eliminado correctamente'),
          backgroundColor: Colors.red,
        ),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo eliminar: $error')),
      );
    }
  }

  void _limpiarFiltros() {
    setState(() {
      _fechaInicio = null;
      _fechaFin = null;
      _tipoMovimiento = 'Todos';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 248, 244, 250),
      appBar: AppBar(
        title: const Text('Histórico de movimientos'),
        backgroundColor: _colorPrincipal,
        foregroundColor: Colors.white,
      ),
      body: Column(
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
                              : _formatearFecha(_fechaInicio!),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _seleccionarFechaFin,
                        icon: const Icon(Icons.calendar_month),
                        label: Text(
                          _fechaFin == null ? 'Fecha fin' : _formatearFecha(_fechaFin!),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  key: ValueKey('filtro-$_tipoMovimiento'),
                  initialValue: _tipoMovimiento,
                  decoration: const InputDecoration(
                    labelText: 'Tipo de movimiento',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'Todos', child: Text('Todos')),
                    DropdownMenuItem(value: 'Entrada', child: Text('Entrada')),
                    DropdownMenuItem(value: 'Salida', child: Text('Salida')),
                  ],
                  onChanged: (value) {
                    if (value == null) {
                      return;
                    }
                    setState(() => _tipoMovimiento = value);
                  },
                ),
                const SizedBox(height: 10),
                Align(
                  alignment: Alignment.centerRight,
                  child: OutlinedButton.icon(
                    onPressed: _limpiarFiltros,
                    icon: const Icon(Icons.filter_alt_off),
                    label: const Text('Limpiar filtros'),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: StreamBuilder<List<MovimientoModel>>(
              stream: _controller.obtenerMovimientosActivos(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return const Center(
                    child: Text('No se pudieron cargar los movimientos'),
                  );
                }

                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final movimientosFiltrados = _filtrarMovimientos(snapshot.data!);
                if (movimientosFiltrados.isEmpty) {
                  return const Center(
                    child: Text('No hay movimientos para mostrar'),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                  itemCount: movimientosFiltrados.length,
                  itemBuilder: (context, index) {
                    final movimiento = movimientosFiltrados[index];
                    final esEntrada = movimiento.tipoMovimiento == 'Entrada';
                    final colorTipo = esEntrada ? Colors.green : Colors.orange;

                    return Card(
                      margin: const EdgeInsets.only(bottom: 10),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          children: [
                            GestureDetector(
                              onDoubleTap: () => _mostrarDialogoEdicion(movimiento),
                              child: const CircleAvatar(
                                backgroundColor: Color(0xFFE2E8F0),
                                child: Icon(Icons.image, color: Colors.black54),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    movimiento.nombreProducto,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text('Código: ${movimiento.codigoProducto}'),
                                  Text('Fecha: ${_formatearFecha(movimiento.fechaMovimiento)}'),
                                  Text(
                                    'Tipo: ${movimiento.tipoMovimiento}',
                                    style: TextStyle(color: colorTipo),
                                  ),
                                  Text('Cantidad: ${movimiento.cantidad}'),
                                ],
                              ),
                            ),
                            IconButton(
                              onPressed: () => _confirmarEliminacion(movimiento),
                              icon: const Icon(Icons.delete, color: Colors.red),
                              tooltip: 'Eliminar movimiento',
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
