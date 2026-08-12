import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mi_inventario/Categorias/categoria_screen.dart';
import 'package:mi_inventario/auth/services/auth_service.dart';
import 'package:mi_inventario/configuracion/configuracion_screen.dart';
import 'package:mi_inventario/controller/dashboard_controller.dart';
import 'package:mi_inventario/controller/productos_controller.dart';
import 'package:mi_inventario/model/dashboard_model.dart';
import 'package:mi_inventario/view/movimientos/movimientos_screen.dart';
import 'package:mi_inventario/view/negocios/negocios_screen.dart';
import 'package:mi_inventario/view/productos/agregar_productos_screen.dart';
import 'package:mi_inventario/view/productos/inventario_screen.dart';
import 'package:mi_inventario/view/reportes/reportes_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key, required this.authService});

  final AuthService authService;

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final DashboardController _controller = DashboardController();

  List<DashboardModel> opciones = [];

  @override
  void initState() {
    super.initState();
    opciones = _controller.opciones;
  }

  void abrirOpcion(DashboardModel opcion) {
    final uid = widget.authService.usuarioActual?.uid ?? 'default';

    switch (opcion.titulo) {
      case 'Productos':
        if (!Get.isRegistered<ProductosController>()) {
          Get.put(ProductosController());
        }

        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const AgregarProductosScreen()),
        );
        break;

      case 'Inventario':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const InventarioScreen()),
        );
        break;

      case 'Categorias':
      case 'Categorías':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => CategoriaScreen(negocioId: uid)),
        );
        break;

      case 'Negocios':
      case 'Tiendas':
      case 'Mi Negocio':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const NegociosScreen()),
        );
        break;

      case 'Movimientos':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const MovimientosScreen()),
        );
        break;

      case 'Reportes':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const ReportesScreen()),
        );
        break;

      case 'Configuración':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const ConfiguracionScreen()),
        );
        break;

      default:
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'La pantalla de ${opcion.titulo} '
              'estará disponible próximamente',
            ),
          ),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final colores = tema.colorScheme;
    final esOscuro = tema.brightness == Brightness.dark;

    final radioTarjeta = esOscuro ? 18.0 : 14.0;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Inicio - Mi Inventario',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            onPressed: widget.authService.cerrarSesion,
            icon: const Icon(Icons.logout),
            tooltip: 'Cerrar sesión',
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: GridView.builder(
          itemCount: opciones.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 14,
            mainAxisSpacing: 14,
            childAspectRatio: 1.15,
          ),
          itemBuilder: (context, index) {
            final opcion = opciones[index];

            return Card(
              margin: EdgeInsets.zero,
              clipBehavior: Clip.antiAlias,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(radioTarjeta),
                side: BorderSide(color: colores.outline),
              ),
              child: InkWell(
                borderRadius: BorderRadius.circular(radioTarjeta),
                onTap: () {
                  abrirOpcion(opcion);
                },
                child: Padding(
                  padding: const EdgeInsets.all(15),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 62,
                        height: 62,
                        decoration: BoxDecoration(
                          color: colores.primaryContainer,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Icon(
                          opcion.icono,
                          size: 40,
                          color: colores.primary,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        opcion.titulo,
                        textAlign: TextAlign.center,
                        style: tema.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: colores.onSurface,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
