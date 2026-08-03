import 'package:flutter_test/flutter_test.dart';
import 'package:mi_inventario/model/negocio_model.dart';

void main() {
  test('guarda y recupera el id del usuario del negocio', () {
    final negocio = NegocioModel(
      nombre: 'Mi negocio',
      direccion: 'Choloma',
      telefono: '98765432',
      correo: 'negocio@example.com',
      usuarioId: 'user-123',
    );

    final datos = negocio.toMap();
    expect(datos['usuarioId'], 'user-123');

    final negocioRecuperado = NegocioModel.fromMap('doc-1', datos);
    expect(negocioRecuperado.id, 'doc-1');
    expect(negocioRecuperado.usuarioId, 'user-123');
  });
}
