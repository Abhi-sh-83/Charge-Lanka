import 'package:equatable/equatable.dart';

class UserEntity extends Equatable {
  final String id;
  final String firebaseUid;
  final String email;
  final String? phone;
  final String fullName;
  final String? avatarUrl;
  final String role; // USER, HOST, ADMIN
  final bool isVerified;
  final DateTime createdAt;

  const UserEntity({
    required this.id,
    required this.firebaseUid,
    required this.email,
    this.phone,
    required this.fullName,
    this.avatarUrl,
    this.role = 'USER',
    this.isVerified = false,
    required this.createdAt,
  });

  @override
  List<Object?> get props => [id, firebaseUid, email, fullName, role];
}
