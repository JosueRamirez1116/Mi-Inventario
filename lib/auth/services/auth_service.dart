import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import 'package:mi_inventario/controller/productos_controller.dart';

class AuthService {
  FirebaseAuth? _auth;
  FirebaseFirestore? _db;

  FirebaseAuth get _authInstance {
    _auth ??= FirebaseAuth.instance;
    return _auth!;
  }

  FirebaseFirestore get _dbInstance {
    _db ??= FirebaseFirestore.instance;
    return _db!;
  }

  Stream<User?> get authStateChanges {
    try {
      return _authInstance.authStateChanges();
    } on FirebaseException catch (_) {
      return const Stream.empty();
    }
  }

  User? get usuarioActual {
    try {
      return _authInstance.currentUser;
    } on FirebaseException catch (_) {
      return null;
    }
  }

  Future<UserCredential> registrar(String email, String password) {
    return _authInstance.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  Future<void> registrarConPerfil({
    required String email,
    required String password,
    required String nombre,
    required String apellido,
    required DateTime fechaNacimiento,
    required String telefono,
  }) async {
    final credencial = await _authInstance.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    final uid = credencial.user?.uid;
    if (uid == null) {
      throw FirebaseAuthException(
        code: 'missing-uid',
        message: 'No se pudo obtener el UID del usuario.',
      );
    }

    try {
      await _dbInstance.collection('usuarios').doc(uid).set({
        'uid': uid,
        'nombre': nombre.trim(),
        'apellido': apellido.trim(),
        'email': email.trim(),
        'fechaNacimiento': Timestamp.fromDate(fechaNacimiento),
        'telefono': telefono.trim(),
        'telefonoVerificado': true,
        'estado': 1,
        'creadoEn': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } on FirebaseException {
      // Evita usuarios huerfanos en Authentication cuando falla Firestore.
      try {
        await credencial.user?.delete();
      } catch (_) {}
      rethrow;
    }
  }

  Future<void> iniciarVerificacionTelefono({
    required String numeroTelefono,
    required void Function(String verificationId, int? resendToken)
    codigoEnviado,
    required void Function(FirebaseAuthException e) verificacionFallida,
    required Future<void> Function() verificacionAutomaticaCompletada,
  }) async {
    await _authInstance.verifyPhoneNumber(
      phoneNumber: numeroTelefono,
      verificationCompleted: (PhoneAuthCredential credential) async {
        await _authInstance.signInWithCredential(credential);
        await _authInstance.signOut();
        await verificacionAutomaticaCompletada();
      },
      verificationFailed: verificacionFallida,
      codeSent: codigoEnviado,
      codeAutoRetrievalTimeout: (_) {},
    );
  }

  Future<void> confirmarCodigoTelefono({
    required String verificationId,
    required String codigoSms,
  }) async {
    final credential = PhoneAuthProvider.credential(
      verificationId: verificationId,
      smsCode: codigoSms,
    );

    await _authInstance.signInWithCredential(credential);
    await _authInstance.signOut();
  }

  Future<UserCredential> iniciarSesion(String email, String password) async {
    final credencial = await _authInstance.signInWithEmailAndPassword(
      email: email,
      password: password,
    );

    final user = credencial.user;
    if (user != null) {
      try {
        await _asegurarPerfilUsuarioMinimo(user);
      } catch (_) {}
    }

    return credencial;
  }

  Future<void> _asegurarPerfilUsuarioMinimo(User user) async {
    final ref = _dbInstance.collection('usuarios').doc(user.uid);
    final doc = await ref.get();
    if (doc.exists) return;

    await ref.set({
      'uid': user.uid,
      'nombre': '',
      'apellido': '',
      'email': (user.email ?? '').trim(),
      'telefono': '',
      'telefonoVerificado': false,
      'estado': 1,
      'creadoEn': FieldValue.serverTimestamp(),
      'perfilIncompleto': true,
    }, SetOptions(merge: true));
  }

  Future<void> cerrarSesion() async {
    await _authInstance.signOut();
    if (Get.isRegistered<ProductosController>()) {
      Get.delete<ProductosController>();
    }
  }

  Future<void> restablecerContrasena(String email) {
    return _authInstance.sendPasswordResetEmail(email: email.trim());
  }

  Future<void> reautenticarConContrasena({
    required String email,
    required String password,
  }) async {
    final user = _authInstance.currentUser;
    if (user == null) {
      throw FirebaseAuthException(
        code: 'missing-uid',
        message: 'No hay un usuario autenticado.',
      );
    }

    final credential = EmailAuthProvider.credential(
      email: email.trim(),
      password: password,
    );

    await user.reauthenticateWithCredential(credential);
  }

  Future<Map<String, dynamic>?> obtenerPerfilUsuario() async {
    final uid = _authInstance.currentUser?.uid;
    if (uid == null) return null;

    final doc = await _dbInstance.collection('usuarios').doc(uid).get();
    return doc.data();
  }

  Future<Map<String, dynamic>?> obtenerPerfilNegocio() async {
    final uid = _authInstance.currentUser?.uid;
    if (uid == null) return null;

    final doc = await _dbInstance.collection('negocios').doc(uid).get();
    return doc.data();
  }

  Future<void> actualizarPerfilUsuario({
    required String nombre,
    required String apellido,
    required DateTime fechaNacimiento,
    required String telefono,
  }) async {
    final uid = _authInstance.currentUser?.uid;
    if (uid == null) {
      throw FirebaseAuthException(
        code: 'missing-uid',
        message: 'No hay un usuario autenticado.',
      );
    }

    await _dbInstance.collection('usuarios').doc(uid).set({
      'nombre': nombre.trim(),
      'apellido': apellido.trim(),
      'fechaNacimiento': Timestamp.fromDate(fechaNacimiento),
      'telefono': telefono.trim(),
      'actualizadoEn': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> actualizarPerfilNegocio({
    required String nombreNegocio,
    required String direccion,
    required String telefono,
    required String correo,
  }) async {
    final uid = _authInstance.currentUser?.uid;
    if (uid == null) {
      throw FirebaseAuthException(
        code: 'missing-uid',
        message: 'No hay un usuario autenticado.',
      );
    }

    await _dbInstance.collection('negocios').doc(uid).set({
      'nombreNegocio': nombreNegocio.trim(),
      'direccion': direccion.trim(),
      'telefono': telefono.trim(),
      'correo': correo.trim(),
      'actualizadoEn': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> eliminarNegocio() async {
    final uid = _authInstance.currentUser?.uid;
    if (uid == null) {
      throw FirebaseAuthException(
        code: 'missing-uid',
        message: 'No hay un usuario autenticado.',
      );
    }

    await _dbInstance.collection('negocios').doc(uid).set({
      'estado': 0,
      'eliminadoEn': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> eliminarCuentaUsuario() async {
    final user = _authInstance.currentUser;
    final uid = user?.uid;

    if (user == null || uid == null) {
      throw FirebaseAuthException(
        code: 'missing-uid',
        message: 'No hay un usuario autenticado.',
      );
    }

    await _dbInstance.collection('usuarios').doc(uid).set({
      'estado': 0,
      'eliminadoEn': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    await user.delete();
  }
}
