import 'package:moviles_auth/features/avatar/domain/entities/picked_photo.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

/// The only file that talks to the post-images bucket of Supabase Storage.
class SupabasePostImageDataSource {
  static const bucket = 'post-images';
  final SupabaseClient _client = Supabase.instance.client;
  final Uuid _uuid = const Uuid();

  String get _uid {
    return _client.auth.currentUser!.id;
  }

  Future<String> upload(PickedPhoto photo) async {
    final path = '$_uid/${_uuid.v4()}.${photo.extension}';
    final type = photo.extension == 'jpg' ? 'jpeg' : photo.extension;
    try {
      await _client.storage
          .from(bucket)
          .uploadBinary(
            path,
            photo.bytes,
            fileOptions: FileOptions(
              contentType: 'image/$type',
              cacheControl: '31536000',
            ),
          );
      return path;
    } on StorageException catch (e) {
      throw Exception(e.message);
    }
  }

  Future<String> signedUrl(String path) async {
    try {
      return await _client.storage.from(bucket).createSignedUrl(path, 3600);
    } on StorageException catch (e) {
      throw Exception(e.message);
    }
  }
}
