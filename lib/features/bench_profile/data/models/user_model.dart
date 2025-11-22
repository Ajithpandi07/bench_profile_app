import '../../domain/entities/user_profile.dart';

class UserModel extends UserProfile {
  UserModel({required super.uid, super.email});

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(uid: map['uid'] as String, email: map['email'] as String?);
  }

  Map<String, dynamic> toMap() => {'uid': uid, 'email': email};
}
