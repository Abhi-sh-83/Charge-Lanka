import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_remote_datasource.dart';
import '../models/user_model.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDatasource _remoteDatasource;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  AuthRepositoryImpl(this._remoteDatasource);

  @override
  Future<UserEntity> login({
    required String email,
    required String password,
  }) async {
    final credential = await _remoteDatasource.signInWithEmail(email, password);
    return _remoteDatasource.userCredentialToModel(credential);
  }

  @override
  Future<UserEntity> register({
    required String email,
    required String password,
    required String fullName,
    String? phone,
  }) async {
    final credential = await _remoteDatasource.registerWithEmail(
      email,
      password,
    );
    final user = credential.user!;
    await user.updateDisplayName(fullName);
    await _firestore.collection('users').doc(user.uid).set({
      'email': email,
      'full_name': fullName,
      'phone': phone,
      'role': 'USER',
      'is_verified': false,
      'created_at': FieldValue.serverTimestamp(),
      'updated_at': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
    await _firestore.collection('wallets').doc(user.uid).set({
      'user_id': user.uid,
      'balance': 0.0,
      'currency': 'LKR',
      'created_at': FieldValue.serverTimestamp(),
      'updated_at': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
    return _mapFirebaseUserToModel(user);
  }

  @override
  Future<void> logout() => _remoteDatasource.signOut();

  @override
  Future<UserEntity?> getCurrentUser() async {
    final user = _remoteDatasource.currentUser;
    if (user == null) return null;
    return _mapFirebaseUserToModel(user);
  }

  @override
  Stream<UserEntity?> get authStateChanges {
    return _remoteDatasource.authStateChanges.map((user) {
      if (user == null) return null;
      return _mapFirebaseUserToModel(user);
    });
  }

  UserModel _mapFirebaseUserToModel(User user) {
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
