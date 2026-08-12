import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mi_inventario/controller/negocios_controller.dart';
import 'package:mi_inventario/model/negocio_model.dart';
import 'package:mi_inventario/view/negocios/negocio_form_screen.dart';

class NegociosScreen extends StatelessWidget {
  const NegociosScreen({super.key});

  NegociosController _obtenerController() {
    if (Get.isRegistered<NegociosController>()) {
      return Get.find<NegociosController>();
    }

    return Get.put(NegociosController());
  }

  Future<void> _abrirFormulario(
    BuildContext context,
    NegociosController controller, {
    NegocioModel? negocio,
  }) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) =>
            NegocioFormScreen(controller: controller, negocio: negocio),
      ),
    );
  }

  Future<void> _confirmarEliminar(
    BuildContext context,
    NegociosController controller,
    NegocioModel negocio,
  ) async {
    final colores = Theme.of(context).colorScheme;

    final confirmar = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Eliminar negocio'),
          content: Text(
            '¿Deseas eliminar "${negocio.nombre}"?\n\n'
            'El negocio quedará marcado como eliminado.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(false);
              },
              child: const Text('Cancelar'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: colores.error,
                foregroundColor: colores.onError,
              ),
              onPressed: () {
                Navigator.of(dialogContext).pop(true);
              },
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
      await controller.eliminarNegocio(negocio.id);

      if (!context.mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Negocio eliminado correctamente.')),
      );
    } catch (_) {
      if (!context.mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo eliminar el negocio.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = _obtenerController();

    final tema = Theme.of(context);
    final colores = tema.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Gestión de negocios',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            tooltip: 'Agregar negocio',
            onPressed: () {
              _abrirFormulario(context, controller);
            },
            icon: const Icon(Icons.add),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _abrirFormulario(context, controller);
        },
        child: const Icon(Icons.add),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 14, 14, 8),
              child: TextField(
                onChanged: controller.buscarNegocio,
                decoration: const InputDecoration(
                  hintText: 'Buscar negocio',
                  prefixIcon: Icon(Icons.search),
                ),
              ),
            ),
            Expanded(
              child: Obx(() {
                if (controller.cargando.value) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (controller.mensajeError.value.isNotEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.error_outline,
                            size: 60,
                            color: colores.error,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            controller.mensajeError.value,
                            textAlign: TextAlign.center,
                            style: TextStyle(color: colores.onSurface),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                final negocios = controller.negociosFiltrados;

                if (negocios.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.store_outlined,
                            size: 70,
                            color: colores.onSurfaceVariant.withValues(
                              alpha: 0.55,
                            ),
                          ),
                          const SizedBox(height: 14),
                          Text(
                            controller.textoBusqueda.value.isEmpty
                                ? 'No hay negocios registrados'
                                : 'No se encontraron negocios',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: colores.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            controller.textoBusqueda.value.isEmpty
                                ? 'Presiona + para agregar uno'
                                : 'Intenta con otra búsqueda',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 13,
                              color: colores.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(14, 6, 14, 90),
                  itemCount: negocios.length,
                  itemBuilder: (context, index) {
                    final negocio = negocios[index];

                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      clipBehavior: Clip.antiAlias,
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  width: 42,
                                  height: 42,
                                  decoration: BoxDecoration(
                                    color: colores.primaryContainer,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Icon(
                                    Icons.store,
                                    color: colores.primary,
                                    size: 22,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    negocio.nombre,
                                    style: TextStyle(
                                      fontSize: 17,
                                      fontWeight: FontWeight.bold,
                                      color: colores.onSurface,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Divider(height: 1, color: colores.outline),
                            const SizedBox(height: 12),
                            _datoNegocio(
                              context: context,
                              icono: Icons.location_on,
                              titulo: 'Dirección',
                              valor: negocio.direccion,
                            ),
                            const SizedBox(height: 8),
                            _datoNegocio(
                              context: context,
                              icono: Icons.phone,
                              titulo: 'Teléfono',
                              valor: negocio.telefono,
                            ),
                            const SizedBox(height: 8),
                            _datoNegocio(
                              context: context,
                              icono: Icons.email,
                              titulo: 'Correo',
                              valor: negocio.correo,
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Expanded(
                                  child: ElevatedButton.icon(
                                    onPressed: () {
                                      _abrirFormulario(
                                        context,
                                        controller,
                                        negocio: negocio,
                                      );
                                    },
                                    icon: const Icon(Icons.edit, size: 18),
                                    label: const Text('Editar'),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: ElevatedButton.icon(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: colores.error,
                                      foregroundColor: colores.onError,
                                    ),
                                    onPressed: () {
                                      _confirmarEliminar(
                                        context,
                                        controller,
                                        negocio,
                                      );
                                    },
                                    icon: const Icon(Icons.delete, size: 18),
                                    label: const Text('Eliminar'),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              }),
            ),
          ],
        ),
      ),
    );
  }

  Widget _datoNegocio({
    required BuildContext context,
    required IconData icono,
    required String titulo,
    required String valor,
  }) {
    final colores = Theme.of(context).colorScheme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icono, color: colores.primary, size: 19),
        const SizedBox(width: 8),
        Expanded(
          child: RichText(
            text: TextSpan(
              style: TextStyle(fontSize: 13, color: colores.onSurface),
              children: [
                TextSpan(
                  text: '$titulo: ',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: colores.onSurfaceVariant,
                  ),
                ),
                TextSpan(
                  text: valor.isEmpty ? 'Sin información' : valor,
                  style: TextStyle(color: colores.onSurface),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
