import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:moviles_auth/features/compose/ui/bloc/compose_event.dart';
import 'package:moviles_auth/features/compose/ui/bloc/compose_state.dart';
import 'package:moviles_auth/features/posts/domain/usecases/publish_post_usecase.dart';
import 'package:moviles_auth/features/posts/domain/usecases/pick_post_image_usecase.dart';

/// Attaches a photo to the new post and publishes it.
class ComposeBloc extends Bloc<ComposeEvent, ComposeState> {
  final PublishPostUseCase _publish = PublishPostUseCase();
  final PickPostImageUseCase _pickImage = PickPostImageUseCase();

  ComposeBloc() : super(const ComposeState()) {
    on<ComposePhotoRequested>(_onPhotoRequested);
    on<ComposePhotoRemoved>(_onPhotoRemoved);
    on<ComposeSubmitted>(_onSubmitted);
  }

  String _message(Exception e) {
    return e.toString().replaceFirst('Exception: ', '');
  }

  Future<void> _onPhotoRequested(
    ComposePhotoRequested event,
    Emitter<ComposeState> emit,
  ) async {
    try {
      final photo = await _pickImage();
      if (photo == null) return;
      emit(state.copyWith(status: ComposeStatus.initial, photo: photo));
    } on Exception catch (e) {
      emit(
        state.copyWith(
          status: ComposeStatus.failure,
          errorMessage: _message(e),
        ),
      );
    }
  }

  Future<void> _onPhotoRemoved(
    ComposePhotoRemoved event,
    Emitter<ComposeState> emit,
  ) async {
    emit(state.copyWith(removePhoto: true));
  }

  Future<void> _onSubmitted(
    ComposeSubmitted event,
    Emitter<ComposeState> emit,
  ) async {
    emit(state.copyWith(status: ComposeStatus.loading));
    try {
      await _publish(event.content, photo: state.photo);
      emit(state.copyWith(status: ComposeStatus.success));
    } on Exception catch (e) {
      emit(
        state.copyWith(
          status: ComposeStatus.failure,
          errorMessage: _message(e),
        ),
      );
    }
  }
}
