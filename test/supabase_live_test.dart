import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:moviles_auth/features/auth/data/source/supabase_auth_data_source.dart';
import 'package:moviles_auth/features/auth/data/source/supabase_profile_data_source.dart';
import 'package:moviles_auth/features/auth/domain/entities/profile.dart';
import 'package:moviles_auth/features/avatar/data/source/supabase_avatar_data_source.dart';
import 'package:moviles_auth/features/avatar/domain/entities/picked_photo.dart';
import 'package:moviles_auth/features/posts/domain/usecases/publish_post_usecase.dart';
import 'package:moviles_auth/features/posts/domain/usecases/get_feed_usecase.dart';
import 'package:moviles_auth/features/posts/domain/usecases/get_my_posts_usecase.dart';
import 'package:moviles_auth/features/posts/domain/usecases/toggle_like_usecase.dart';

class _MemoryAuthStorage extends GotrueAsyncStorage {
  final _values = <String, String>{};
  @override
  Future<String?> getItem({required String key}) async => _values[key];
  @override
  Future<void> setItem({required String key, required String value}) async {
    _values[key] = value;
  }

  @override
  Future<void> removeItem({required String key}) async {
    _values.remove(key);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  // This opt-in integration test deliberately uses the real network.
  HttpOverrides.global = null;
  final enabled = Platform.environment['LAB7_LIVE'] == '1';
  test(
    'Supabase real: login, avatars, posts, signed URLs, likes and logout',
    () async {
      await Supabase.initialize(
        url: Platform.environment['LAB7_URL']!,
        publishableKey: Platform.environment['LAB7_PUBLIC_KEY']!,
        authOptions: FlutterAuthClientOptions(
          pkceAsyncStorage: _MemoryAuthStorage(),
          localStorage: EmptyLocalStorage(),
          detectSessionInUri: false,
          autoRefreshToken: false,
        ),
        debug: false,
      );
      final client = Supabase.instance.client;
      final auth = SupabaseAuthDataSource();
      final profiles = SupabaseProfileDataSource();
      final avatars = SupabaseAvatarDataSource();
      final createdPaths = <String>[];
      final http = HttpClient();
      Future<int> readUrl(String url) async {
        final response = await (await http.getUrl(Uri.parse(url))).close();
        await response.drain<void>();
        return response.statusCode;
      }

      try {
        final user = await auth.signIn(
          email: Platform.environment['LAB7_EMAIL']!,
          password: Platform.environment['LAB7_PASSWORD']!,
        );
        expect(client.auth.currentSession, isNotNull);
        await profiles.createProfile(
          Profile(
            id: user.id,
            username: 'lab7_test',
            fullName: 'Prueba temporal Lab 7',
          ),
        );
        final photo = PickedPhoto(
          bytes: base64Decode(
            'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVQIHWP4z8DwHwAFAAH/iZk9HQAAAABJRU5ErkJggg==',
          ),
          extension: 'png',
        );
        for (var i = 0; i < 2; i++) {
          final before = await profiles.getProfile(user.id);
          final path = await avatars.upload(photo);
          createdPaths.add(path);
          await profiles.updateAvatarPath(user.id, path);
          if (before.avatarPath != null) {
            await avatars.remove(before.avatarPath!);
          }
        }
        final profile = await profiles.getProfile(user.id);
        expect(profile.avatarPath, createdPaths.last);
        expect(await readUrl(profile.avatarUrl!), 200);
        final files = await client.storage.from('avatars').list(path: user.id);
        expect(files, hasLength(1));
        debugPrint(
          'LIVE OK: avatar replaced twice; one file remains; public URL works without a token.',
        );

        final publish = PublishPostUseCase();
        await expectLater(publish(''), throwsA(isA<Exception>()));
        await expectLater(publish('x' * 281), throwsA(isA<Exception>()));
        await publish('Prueba temporal con imagen', photo: photo);
        await publish('', photo: photo);
        final mine = await GetMyPostsUseCase()(limit: 10);
        expect(mine, hasLength(2));
        expect(
          mine.every((p) => p.imagePath != null && p.imageUrl != null),
          isTrue,
        );
        expect(mine.any((p) => p.content.isEmpty), isTrue);
        for (final post in mine) {
          expect(await readUrl(post.imageUrl!), 200);
          final publicUrl = client.storage
              .from('post-images')
              .getPublicUrl(post.imagePath!);
          expect(await readUrl(publicUrl), isNot(200));
        }
        final feed = await GetFeedUseCase()(page: 0, size: 100);
        expect(feed.where((p) => mine.any((m) => m.id == p.id)), hasLength(2));
        expect(
          feed.firstWhere((p) => p.id == mine.first.id).authorAvatarUrl,
          profile.avatarUrl,
        );
        final liked = await ToggleLikeUseCase()(mine.first);
        expect(liked.likedByMe, isTrue);
        final withLike = await GetMyPostsUseCase()(limit: 10);
        expect(withLike.firstWhere((p) => p.id == liked.id).likeCount, 1);
        await ToggleLikeUseCase()(liked);
        debugPrint(
          'LIVE OK: text+image and image-only posts; feed; signed downloads; private bucket; like/unlike.',
        );
      } finally {
        final uid = client.auth.currentUser?.id;
        if (uid != null) {
          for (final bucket in ['avatars', 'post-images']) {
            final files = await client.storage.from(bucket).list(path: uid);
            if (files.isNotEmpty) {
              await client.storage
                  .from(bucket)
                  .remove(files.map((f) => '$uid/${f.name}').toList());
            }
          }
          await auth.signOut();
          expect(client.auth.currentSession, isNull);
        }
        http.close(force: true);
        await Supabase.instance.dispose();
      }
      debugPrint('LIVE OK: logout; temporary storage files removed.');
    },
    skip: !enabled ? 'Run tools/test-supabase.ps1 for the live test.' : false,
    timeout: const Timeout(Duration(minutes: 3)),
  );
}
