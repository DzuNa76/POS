import 'package:equatable/equatable.dart';

class UserEntity {
  final String id;
  final String name;
  final String email;
  final String image;
  final DateTime createdAt;
  final DateTime updatedAt;

  UserEntity({
    required this.id,
    required this.name,
    required this.email,
    required this.image,
    required this.createdAt,
    required this.updatedAt,
  });
}
