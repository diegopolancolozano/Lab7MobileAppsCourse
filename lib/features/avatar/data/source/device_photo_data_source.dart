import 'package:image_picker/image_picker.dart';
import 'package:moviles_auth/features/avatar/domain/entities/picked_photo.dart';

/// The only file that opens the gallery of the phone.
class DevicePhotoDataSource {
  final ImagePicker _picker = ImagePicker();

  Future<PickedPhoto?> pick() async {
    final file = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 512,
      maxHeight: 512,
      imageQuality: 80,
    );
    if (file == null) return null;
    return PickedPhoto(
      bytes: await file.readAsBytes(),
      extension: file.name.split('.').last.toLowerCase(),
    );
  }
}
