import 'package:moviles_auth/features/avatar/data/source/device_photo_data_source.dart';
import 'package:moviles_auth/features/avatar/data/source/supabase_avatar_data_source.dart';
import 'package:moviles_auth/features/avatar/domain/entities/picked_photo.dart';
import 'package:moviles_auth/features/avatar/domain/repository/avatar_repository.dart';

/// Fulfils AvatarRepository with the phone for picking and Storage for keeping.
class AvatarRepositoryImpl implements AvatarRepository {
  final DevicePhotoDataSource _device = DevicePhotoDataSource();
  final SupabaseAvatarDataSource _storage = SupabaseAvatarDataSource();

  @override
  Future<PickedPhoto?> pick() {
    return _device.pick();
  }

  @override
  Future<String> upload(PickedPhoto photo) {
    return _storage.upload(photo);
  }

  @override
  Future<void> remove(String path) {
    return _storage.remove(path);
  }
}
