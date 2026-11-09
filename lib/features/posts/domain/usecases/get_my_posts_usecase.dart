import 'package:moviles_auth/features/posts/data/repository/post_repository_impl.dart';
import 'package:moviles_auth/features/posts/domain/entities/post.dart';
import 'package:moviles_auth/features/posts/domain/repository/post_repository.dart';

/// Brings the latest posts of the signed in user.
class GetMyPostsUseCase {
  final PostRepository _posts = PostRepositoryImpl();

  Future<List<Post>> call({int limit = 3}) async {
    final posts = await _posts.fetchMine(limit: limit);
    return Future.wait(posts.map(_withImage));
  }

  Future<Post> _withImage(Post post) async {
    final path = post.imagePath;
    if (path == null) return post;
    return post.copyWith(imageUrl: await _posts.imageUrl(path));
  }
}
