// lib/features/auth/data/models/user_model.dart

import '../../domain/entities/entities.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel extends UserProfile {
  UserModel({
    required String uid,
    required String email,
    String? displayName,
    String? photoUrl,
    DateTime? createdAt,
  }) : super(
          uid: uid,
          email: email,
          displayName: displayName,
          photoUrl: photoUrl,
          createdAt: createdAt,
        );

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      uid: json['uid'] as String,
      email: json['email'] as String,
      displayName: json['displayName'] as String?,
      photoUrl: json['photoUrl'] as String?,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'] as String)
          : null,
    );
  }

  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return UserModel(
      uid: doc.id,
      email: data['email'] as String,
      displayName: data['displayName'] as String?,
      photoUrl: data['photoUrl'] as String?,
      createdAt: data['createdAt'] != null
          ? DateTime.tryParse(data['createdAt'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() => super.toJson();
}
