import 'package:flutter_test/flutter_test.dart';
import 'package:mi_inventario/controller/productos_controller.dart';
import 'package:mi_inventario/model/productos_model.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('guarda negocio, categoria y usuario en el producto', () {
    final producto = ProductosModel(
      nombreProducto: 'Arroz',
      descripcion: 'Alimento',
      idCategoria: 'categoria-1',
      idNegocio: 'negocio-1',
      usuarioId: 'user-1',
      stockMaximo: 20,
      stockMinimo: 5,
      unidadMedida: 'kg',
      stockActual: 10,
      precioCompra: 100,
      precioVenta: 120,
      codigoProducto: 'P001',
      fechaCreacion: DateTime(2024, 1, 1),
    );

    final datos = producto.aMapa();
    expect(datos['idCategoria'], 'categoria-1');
    expect(datos['idNegocio'], 'negocio-1');
    expect(datos['usuarioId'], 'user-1');
  });

  test('limpia los campos de texto pero conserva negocio y categoría', () {
    final controller = ProductosController();
    controller.idNegocioSeleccionado.value = 'negocio-1';
    controller.idCategoriaSeleccionada.value = 'categoria-1';

    controller.controladorNombre.text = 'Arroz';
    controller.controladorDescripcion.text = 'Alimento';
    controller.controladorCodigoBarra.text = '123';
    controller.controladorCodigoProducto.text = 'P001';
    controller.controladorStockMaximo.text = '20';
    controller.controladorStockMinimo.text = '5';
    controller.controladorUnidadMedida.text = 'kg';
    controller.controladorStockActual.text = '10';
    controller.controladorPrecioCompra.text = '100';
    controller.controladorPrecioVenta.text = '120';

    controller.limpiarFormulario();

    expect(controller.controladorNombre.text, isEmpty);
    expect(controller.controladorDescripcion.text, isEmpty);
    expect(controller.controladorCodigoBarra.text, isEmpty);
    expect(controller.controladorCodigoProducto.text, isEmpty);
    expect(controller.controladorStockMaximo.text, isEmpty);
    expect(controller.controladorStockMinimo.text, isEmpty);
    expect(controller.controladorUnidadMedida.text, isEmpty);
    expect(controller.controladorStockActual.text, isEmpty);
    expect(controller.controladorPrecioCompra.text, isEmpty);
    expect(controller.controladorPrecioVenta.text, isEmpty);
    expect(controller.idNegocioSeleccionado.value, 'negocio-1');
    expect(controller.idCategoriaSeleccionada.value, 'categoria-1');
  });
}
