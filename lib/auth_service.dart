import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  FirebaseAuth? _auth;

  FirebaseAuth get _authInstance {
    _auth ??= FirebaseAuth.instance;
    return _auth!;
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

  Future<UserCredential> iniciarSesion(String email, String password) {
    return _authInstance.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  Future<void> cerrarSesion() {
    return _authInstance.signOut();
  }

  Future<void> restablecerContrasena(String email) {
    return _authInstance.sendPasswordResetEmail(email: email.trim());
  }
}
