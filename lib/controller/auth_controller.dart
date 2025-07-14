// lib/controller/auth_controller.dart
import 'package:firebase_auth/firebase_auth.dart';
import '../model/user_model.dart';

class AuthController {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /* ---------- VALIDACIONES DE FORMULARIO ---------- */
  String? validateEmail(String email) {
    final regex = RegExp(r'^[a-zA-Z0-9._%-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
    return regex.hasMatch(email) ? null : 'Correo inválido';
  }

  String? validatePassword(String password) {
    final regex = RegExp(r'^(?=.*[A-Za-z])(?=.*\d)(?=.*[\W_]).{6,}$');
    return regex.hasMatch(password)
        ? null
        : 'Mín. 6 caracteres, letra, número y símbolo';
  }

  /* ------------------   LOGIN   ------------------ */
  Future<String?> login(String email, String password) async {
    try {
      await _auth.signInWithEmailAndPassword(
          email: email, password: password);
      return null;
    } on FirebaseAuthException catch (e) {
      return e.message ?? 'Error al iniciar sesión';
    }
  }

  /* ---------------- REGISTRO --------------------- */
  Future<String?> register(String email, String password) async {
    try {
      await _auth.createUserWithEmailAndPassword(
          email: email, password: password);
      return null;
    } on FirebaseAuthException catch (e) {
      return e.message ?? 'Error al registrarse';
    }
  }

  /* ------------- UTILIDADES GENERALES ------------ */
  UserModel? get currentUser {
    final user = _auth.currentUser;
    return user == null
        ? null
        : UserModel(uid: user.uid, email: user.email ?? '');
  }

  Future<void> logout() async {
    await _auth.signOut();
  }
}
