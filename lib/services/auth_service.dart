import 'package:firebase_auth/firebase_auth.dart';
import 'firestore_service.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirestoreService _firestoreService = FirestoreService();

  // Kayıt ol
  Future<UserCredential?> register(
    String email,
    String password, {
    String name = '',
  }) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      // Firestore'a profil kaydet
      if (credential.user != null) {
        await _firestoreService.createUserProfile(
          credential.user!.uid,
          name.isEmpty ? email.split('@')[0] : name,
          email,
        );
      }
      return credential;
    } catch (e) {
      rethrow;
    }
  }

  // Giriş yap
  Future<UserCredential?> login(String email, String password) async {
    try {
      return await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    } catch (e) {
      rethrow;
    }
  }

  // Çıkış yap
  Future<void> logout() async {
    await _auth.signOut();
  }

  // Mevcut kullanıcı
  User? get currentUser => _auth.currentUser;

  // Kullanıcı durumu stream
  Stream<User?> get authStateChanges => _auth.authStateChanges();
}
