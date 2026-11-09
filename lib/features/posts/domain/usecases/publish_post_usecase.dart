import 'package:moviles_auth/features/avatar/domain/entities/picked_photo.dart';
import 'package:moviles_auth/features/posts/data/repository/post_repository_impl.dart';
import 'package:moviles_auth/features/posts/domain/repository/post_repository.dart';

/// Validates a post, uploads its photo if it has one and publishes it.
class PublishPostUseCase {
  static const maxLength = 280;
  final PostRepository _posts = PostRepositoryImpl();

  Future<void> call(String content, {PickedPhoto? photo}) async {
    final text = content.trim();
    if (text.isEmpty && photo == null) {
      throw Exception('Escribe algo o agrega una foto');
    }
    if (text.length > maxLength) {
      throw Exception('Máximo $maxLength caracteres');
    }
    final imagePath = photo == null ? null : await _posts.uploadImage(photo);
    await _posts.create(text, imagePath: imagePath);
  }
}
