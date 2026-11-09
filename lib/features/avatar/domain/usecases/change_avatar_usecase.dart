import 'package:moviles_auth/features/auth/data/repository/auth_repository_impl.dart';
import 'package:moviles_auth/features/auth/data/repository/profile_repository_impl.dart';
import 'package:moviles_auth/features/auth/domain/entities/profile.dart';
import 'package:moviles_auth/features/auth/domain/repository/auth_repository.dart';
import 'package:moviles_auth/features/auth/domain/repository/profile_repository.dart';
import 'package:moviles_auth/features/avatar/data/repository/avatar_repository_impl.dart';
import 'package:moviles_auth/features/avatar/domain/repository/avatar_repository.dart';

/// Uploads a new profile photo, points the profile to it and deletes the old one.
class ChangeAvatarUseCase {
  static const maxBytes = 2 * 1024 * 1024;
  final AuthRepository _auth = AuthRepositoryImpl();
  final ProfileRepository _profiles = ProfileRepositoryImpl();
  final AvatarRepository _avatars = AvatarRepositoryImpl();

  Future<Profile?> call() async {
    final user = _auth.currentUser();
    if (user == null) throw Exception('No hay una sesión iniciada');
    final photo = await _avatars.pick();
    if (photo == null) return null;
    if (photo.bytes.length > maxBytes) {
      throw Exception('La foto pesa más de 2 MB');
    }
    final before = await _profiles.getProfile(user.id);
    final path = await _avatars.upload(photo);
    await _profiles.updateAvatarPath(user.id, path);
    final oldPath = before.avatarPath;
    if (oldPath != null) await _avatars.remove(oldPath);
    return _profiles.getProfile(user.id);
  }
}
