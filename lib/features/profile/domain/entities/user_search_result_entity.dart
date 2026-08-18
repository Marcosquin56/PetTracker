import 'package:equatable/equatable.dart';

class UserSearchResultEntity extends Equatable {
  const UserSearchResultEntity({required this.id, this.displayName, this.photoUrl});

  final String id;
  final String? displayName;
  final String? photoUrl;

  @override
  List<Object?> get props => [id, displayName, photoUrl];
}
