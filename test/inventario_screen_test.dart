import 'package:flutter_test/flutter_test.dart';
import 'package:mi_inventario/view/productos/inventario_screen.dart';

void main() {
  group('filtrarProductosPorNombre', () {
    test('filtra productos por coincidencia parcial del nombre', () {
      final productos = [
        {'nombreProducto': 'Leche entera'},
        {'nombreProducto': 'Pan dulce'},
        {'nombreProducto': 'Agua mineral'},
      ];

      final resultado = filtrarProductosPorNombre(productos, 'le');

      expect(resultado.length, 1);
      expect(resultado.first['nombreProducto'], 'Leche entera');
    });
  });
}
