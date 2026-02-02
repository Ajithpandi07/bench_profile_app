// lib/features/auth/data/models/user_model.dart

import '../../domain/entities/entities.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel extends UserProfile {
  const UserModel({
    required String uid,
    required String email,
    String? displayName,
    String? photoUrl,
    DateTime? createdAt,
    double? targetCalories,
    double? targetWater,
  }) : super(
         uid: uid,
         email: email,
         displayName: displayName,
         photoUrl: photoUrl,
         createdAt: createdAt,
         targetCalories: targetCalories,
         targetWater: targetWater,
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
      targetCalories: (json['targetCalories'] as num?)?.toDouble(),
      targetWater: (json['targetWater'] as num?)?.toDouble(),
    );
  }

  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return UserModel(
      uid: doc.id,
      email: data['email'] as String? ?? '',
      displayName: data['displayName'] as String?,
      photoUrl: data['photoUrl'] as String?,
      createdAt: data['createdAt'] != null
          ? (data['createdAt'] is Timestamp
                ? (data['createdAt'] as Timestamp).toDate()
                : DateTime.tryParse(data['createdAt'].toString()))
          : null,
      // Map from specific requested keys (support both correct and typo versions)
      targetCalories:
          _parseDouble(data['target_calories']) ??
          _parseDouble(data['target_calroees']),
      targetWater: _parseDouble(data['target_water']),
    );
  }

  static double? _parseDouble(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }

  Map<String, dynamic> toJson() {
    final json = super.toJson();
    if (targetCalories != null) json['targetCalories'] = targetCalories;
    if (targetWater != null) json['targetWater'] = targetWater;
    return json;
  }
}
