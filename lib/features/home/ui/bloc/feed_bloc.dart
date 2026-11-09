import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:moviles_auth/features/auth/domain/usecases/get_my_profile_usecase.dart';
import 'package:moviles_auth/features/avatar/domain/usecases/change_avatar_usecase.dart';
import 'package:moviles_auth/features/auth/domain/usecases/sign_out_usecase.dart';
import 'package:moviles_auth/features/home/ui/bloc/feed_event.dart';
import 'package:moviles_auth/features/home/ui/bloc/feed_state.dart';
import 'package:moviles_auth/features/posts/domain/entities/post.dart';
import 'package:moviles_auth/features/posts/domain/usecases/get_feed_usecase.dart';
import 'package:moviles_auth/features/posts/domain/usecases/get_my_posts_usecase.dart';
import 'package:moviles_auth/features/posts/domain/usecases/toggle_like_usecase.dart';

/// Loads the profile and the wall, toggles likes, changes the photo and signs out.
class FeedBloc extends Bloc<FeedEvent, FeedState> {
  static const pageSize = 10;
  final GetMyProfileUseCase _getMyProfile = GetMyProfileUseCase();
  final SignOutUseCase _signOut = SignOutUseCase();
  final GetFeedUseCase _getFeed = GetFeedUseCase();
  final GetMyPostsUseCase _getMyPosts = GetMyPostsUseCase();
  final ToggleLikeUseCase _toggleLike = ToggleLikeUseCase();
  final ChangeAvatarUseCase _changeAvatar = ChangeAvatarUseCase();

  FeedBloc() : super(const FeedState()) {
    on<ProfileRequested>(_onProfileRequested);
    on<SignOutRequested>(_onSignOutRequested);
    on<FeedStarted>(_onStarted);
    on<FeedMoreRequested>(_onMoreRequested);
    on<FeedLikeToggled>(_onLikeToggled);
    on<AvatarChangeRequested>(_onAvatarChangeRequested);
  }

  String _message(Exception e) {
    return e.toString().replaceFirst('Exception: ', '');
  }

  Future<void> _onStarted(FeedStarted event, Emitter<FeedState> emit) async {
    emit(state.copyWith(status: FeedStatus.loading));
    try {
      final posts = await _getFeed(page: 0, size: pageSize);
      final mine = await _getMyPosts();
      emit(
        state.copyWith(
          status: FeedStatus.success,
          posts: posts,
          myPosts: mine,
          page: 0,
          hasMore: posts.length == pageSize,
        ),
      );
    } on Exception catch (e) {
      emit(
        state.copyWith(status: FeedStatus.failure, errorMessage: _message(e)),
      );
    }
  }

  Future<void> _onMoreRequested(
    FeedMoreRequested event,
    Emitter<FeedState> emit,
  ) async {
    if (!state.hasMore || state.status == FeedStatus.loading) return;
    emit(state.copyWith(status: FeedStatus.loading));
    try {
      final next = await _getFeed(page: state.page + 1, size: pageSize);
      emit(
        state.copyWith(
          status: FeedStatus.success,
          posts: [...state.posts, ...next],
          page: state.page + 1,
          hasMore: next.length == pageSize,
        ),
      );
    } on Exception catch (e) {
      emit(
        state.copyWith(status: FeedStatus.failure, errorMessage: _message(e)),
      );
    }
  }

  Future<void> _onLikeToggled(
    FeedLikeToggled event,
    Emitter<FeedState> emit,
  ) async {
    try {
      final updated = await _toggleLike(event.post);
      List<Post> swap(List<Post> list) {
        return [
          for (final post in list) post.id == updated.id ? updated : post,
        ];
      }

      emit(
        state.copyWith(posts: swap(state.posts), myPosts: swap(state.myPosts)),
      );
    } on Exception catch (e) {
      emit(
        state.copyWith(status: FeedStatus.failure, errorMessage: _message(e)),
      );
    }
  }

  Future<void> _onAvatarChangeRequested(
    AvatarChangeRequested event,
    Emitter<FeedState> emit,
  ) async {
    emit(state.copyWith(avatarStatus: AvatarStatus.uploading));
    try {
      final profile = await _changeAvatar();
      if (profile == null) {
        emit(state.copyWith(avatarStatus: AvatarStatus.idle));
        return;
      }
      emit(state.copyWith(profile: profile, avatarStatus: AvatarStatus.idle));
      add(FeedStarted());
    } on Exception catch (e) {
      emit(
        state.copyWith(
          avatarStatus: AvatarStatus.failure,
          errorMessage: _message(e),
        ),
      );
    }
  }

  Future<void> _onProfileRequested(
    ProfileRequested event,
    Emitter<FeedState> emit,
  ) async {
    try {
      final profile = await _getMyProfile();
      emit(state.copyWith(profile: profile));
    } on Exception catch (e) {
      emit(
        state.copyWith(
          status: FeedStatus.failure,
          errorMessage: e.toString().replaceFirst('Exception: ', ''),
        ),
      );
    }
  }

  Future<void> _onSignOutRequested(
    SignOutRequested event,
    Emitter<FeedState> emit,
  ) async {
    await _signOut();
    emit(state.copyWith(signedOut: true));
  }
}
