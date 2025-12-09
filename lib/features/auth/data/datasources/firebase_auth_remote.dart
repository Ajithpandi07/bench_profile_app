import 'package:firebase_auth/firebase_auth.dart' as fb;
import '../models/user_model.dart';

class FirebaseAuthRemote {
  final fb.FirebaseAuth _auth;

  FirebaseAuthRemote({required fb.FirebaseAuth firebaseAuth})
      : _auth = firebaseAuth;

  Future<UserModel> signInWithEmail(String email, String password) async {
    final cred = await _auth.signInWithEmailAndPassword(email: email, password: password);
    final user = cred.user;
    if (user == null) throw Exception('No user returned from FirebaseAuth');
    return UserModel(uid: user.uid, email: user.email!);
  }

  Future<UserModel> signUpWithEmail(String email, String password) async {
    final cred = await _auth.createUserWithEmailAndPassword(email: email, password: password);
    final user = cred.user;
    if (user == null) throw Exception('No user returned from FirebaseAuth');
    return UserModel(uid: user.uid, email: user.email!);
  }

  Future<void> sendPasswordResetEmail(String email) async {
    await _auth.sendPasswordResetEmail(email: email);
  }

  Future<void> signOut() => _auth.signOut();
}
