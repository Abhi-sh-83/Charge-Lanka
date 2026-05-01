import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_model.dart';

class AuthRemoteDatasource {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;

  Future<UserCredential> signInWithEmail(String email, String password) {
    return _firebaseAuth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  Future<UserCredential> registerWithEmail(String email, String password) {
    return _firebaseAuth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  Future<void> signOut() => _firebaseAuth.signOut();

  User? get currentUser => _firebaseAuth.currentUser;

  Stream<User?> get authStateChanges => _firebaseAuth.authStateChanges();

  UserModel userCredentialToModel(UserCredential credential) {
    final user = credential.user!;
    return UserModel(
      id: user.uid,
      firebaseUid: user.uid,
      email: user.email ?? '',
      phone: user.phoneNumber,
      fullName: user.displayName ?? 'Charge Lanka User',
      avatarUrl: user.photoURL,
      createdAt: user.metadata.creationTime ?? DateTime.now(),
    );
  }
}
