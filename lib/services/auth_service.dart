import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  static User? get currentUser => _auth.currentUser;

  static Stream<User?> get authStateChanges => _auth.authStateChanges();

  // ============ E-POSTA + ŞİFRE ============
  static Future<UserCredential> kayitOl({
    required String email,
    required String sifre,
  }) async {
    return await _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: sifre,
    );
  }

  static Future<UserCredential> girisYap({
    required String email,
    required String sifre,
  }) async {
    return await _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: sifre,
    );
  }

  // ============ GOOGLE ============
  static Future<UserCredential?> googleIleGiris() async {
    final GoogleSignIn googleSignIn = GoogleSignIn.instance;

    await googleSignIn.initialize();

    final GoogleSignInAccount googleUser = await googleSignIn.authenticate();

    final GoogleSignInAuthentication googleAuth = googleUser.authentication;

    final credential = GoogleAuthProvider.credential(
      idToken: googleAuth.idToken,
    );

    return await _auth.signInWithCredential(credential);
  }

  // ============ ŞİFRE SIFIRLA ============
  static Future<void> sifreSifirla(String email) async {
    await _auth.sendPasswordResetEmail(email: email.trim());
  }

  // ============ ÇIKIŞ ============
  static Future<void> cikisYap() async {
    try {
      final googleSignIn = GoogleSignIn.instance;
      await googleSignIn.signOut();
    } catch (_) {}
    await _auth.signOut();
  }

  // ============ HESAP SİL ============
  static Future<void> hesapSil() async {
    final user = _auth.currentUser;
    if (user == null) return;
    try {
      final googleSignIn = GoogleSignIn.instance;
      await googleSignIn.signOut();
    } catch (_) {}
    await user.delete();
  }

  // ============ HATA MESAJI ============
  static String hataMesaji(dynamic e) {
    if (e is FirebaseAuthException) {
      switch (e.code) {
        case 'user-not-found':
          return 'Bu e-posta ile kayıtlı kullanıcı yok';
        case 'wrong-password':
        case 'invalid-credential':
          return 'E-posta veya şifre hatalı';
        case 'invalid-email':
          return 'Geçersiz e-posta adresi';
        case 'email-already-in-use':
          return 'Bu e-posta zaten kullanımda';
        case 'weak-password':
          return 'Şifre en az 6 karakter olmalı';
        case 'user-disabled':
          return 'Bu hesap devre dışı bırakılmış';
        case 'too-many-requests':
          return 'Çok fazla deneme. Lütfen sonra tekrar dene';
        case 'network-request-failed':
          return 'İnternet bağlantısı yok';
        case 'operation-not-allowed':
          return 'Bu giriş yöntemi etkin değil';
        case 'requires-recent-login':
          return 'Bu işlem için tekrar giriş yapman gerekiyor';
        default:
          return 'Hata: ${e.message ?? e.code}';
      }
    }
    return 'Beklenmeyen hata: $e';
  }
}