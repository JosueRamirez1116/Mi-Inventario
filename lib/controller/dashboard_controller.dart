import 'package:flutter/material.dart';
import 'package:mi_inventario/model/dashboard_model.dart';

class DashboardController {
  final List<DashboardModel> opciones = [
    DashboardModel(
      titulo: 'Productos',
      icono: Icons.shopping_bag,
    ),

    DashboardModel(
      titulo: 'Inventario',
      icono: Icons.inventory,
    ),

    DashboardModel(
      titulo: 'Categorias',
      icono: Icons.folder,
    ),

    DashboardModel(
      titulo: 'Mi Negocio',
      icono: Icons.store,
    ),

    DashboardModel(
      titulo: 'Reportes',
      icono: Icons.bar_chart,
    ),

    DashboardModel(
      titulo: 'Movimientos',
      icono: Icons.description,
    ),

    // Nueva opción del dashboard.
    DashboardModel(
      titulo: 'Configuración',
      icono: Icons.settings,
    ),
  ];
}