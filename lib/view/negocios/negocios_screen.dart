import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mi_inventario/controller/negocios_controller.dart';
import 'package:mi_inventario/model/negocio_model.dart';
import 'package:mi_inventario/view/negocios/negocio_form_screen.dart';

class NegociosScreen extends StatelessWidget {
  const NegociosScreen({super.key});

  static const Color _colorPrincipal = Color.fromARGB(255, 28, 83, 170);

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
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
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

    final esOscuro = Theme.of(context).brightness == Brightness.dark;

    final colorFondo = esOscuro
        ? const Color(0xFF121212)
        : const Color.fromARGB(255, 248, 244, 250);

    final colorTarjeta = esOscuro ? const Color(0xFF202020) : Colors.white;

    final colorCampo = esOscuro ? const Color(0xFF242424) : Colors.white;

    final colorTexto = esOscuro ? Colors.white : const Color(0xFF303030);

    final colorSecundario = esOscuro ? Colors.white70 : Colors.black54;

    final colorBorde = esOscuro ? Colors.white24 : Colors.grey.shade300;

    return Scaffold(
      backgroundColor: colorFondo,
      appBar: AppBar(
        backgroundColor: _colorPrincipal,
        foregroundColor: Colors.white,
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
        backgroundColor: _colorPrincipal,
        foregroundColor: Colors.white,
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
                style: TextStyle(color: colorTexto),
                decoration: InputDecoration(
                  hintText: 'Buscar negocio',
                  hintStyle: TextStyle(color: colorSecundario),
                  prefixIcon: Icon(Icons.search, color: colorSecundario),
                  filled: true,
                  fillColor: colorCampo,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: colorBorde),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: colorBorde),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(
                      color: _colorPrincipal,
                      width: 2,
                    ),
                  ),
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
                          const Icon(
                            Icons.error_outline,
                            size: 60,
                            color: Colors.red,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            controller.mensajeError.value,
                            textAlign: TextAlign.center,
                            style: TextStyle(color: colorTexto),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                final negocios = controller.negociosFiltrados;

                if (negocios.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.store_outlined,
                          size: 70,
                          color: esOscuro
                              ? Colors.white38
                              : Colors.grey.shade400,
                        ),
                        const SizedBox(height: 14),
                        Text(
                          controller.textoBusqueda.value.isEmpty
                              ? 'No hay negocios registrados'
                              : 'No se encontraron negocios',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: colorSecundario,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          controller.textoBusqueda.value.isEmpty
                              ? 'Presiona + para agregar uno'
                              : 'Intenta con otra búsqueda',
                          style: TextStyle(
                            fontSize: 13,
                            color: colorSecundario,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(14, 6, 14, 90),
                  itemCount: negocios.length,
                  itemBuilder: (context, index) {
                    final negocio = negocios[index];

                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: colorTarjeta,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: colorBorde),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(
                              alpha: esOscuro ? 0.20 : 0.08,
                            ),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(
                                Icons.store,
                                color: _colorPrincipal,
                                size: 22,
                              ),
                              const SizedBox(width: 9),
                              Expanded(
                                child: Text(
                                  negocio.nombre,
                                  style: TextStyle(
                                    fontSize: 17,
                                    fontWeight: FontWeight.bold,
                                    color: colorTexto,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Divider(height: 1, color: colorBorde),
                          const SizedBox(height: 10),
                          _datoNegocio(
                            icono: Icons.location_on,
                            titulo: 'Dirección',
                            valor: negocio.direccion,
                            colorTexto: colorTexto,
                            colorSecundario: colorSecundario,
                          ),
                          const SizedBox(height: 8),
                          _datoNegocio(
                            icono: Icons.phone,
                            titulo: 'Teléfono',
                            valor: negocio.telefono,
                            colorTexto: colorTexto,
                            colorSecundario: colorSecundario,
                          ),
                          const SizedBox(height: 8),
                          _datoNegocio(
                            icono: Icons.email,
                            titulo: 'Correo',
                            valor: negocio.correo,
                            colorTexto: colorTexto,
                            colorSecundario: colorSecundario,
                          ),
                          const SizedBox(height: 14),
                          Row(
                            children: [
                              Expanded(
                                child: ElevatedButton.icon(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: _colorPrincipal,
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(25),
                                    ),
                                  ),
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
                                    backgroundColor: Colors.red,
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(25),
                                    ),
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
    required IconData icono,
    required String titulo,
    required String valor,
    required Color colorTexto,
    required Color colorSecundario,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icono, color: _colorPrincipal, size: 19),
        const SizedBox(width: 8),
        Expanded(
          child: RichText(
            text: TextSpan(
              style: TextStyle(fontSize: 13, color: colorTexto),
              children: [
                TextSpan(
                  text: '$titulo: ',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: colorSecundario,
                  ),
                ),
                TextSpan(
                  text: valor.isEmpty ? 'Sin información' : valor,
                  style: TextStyle(color: colorTexto),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
