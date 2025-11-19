import 'dart:io';
import 'dart:typed_data';

import 'package:cloudinary_public/cloudinary_public.dart';
import 'package:flutter/foundation.dart';

class CloudinaryService {
  CloudinaryService._();

  static final String _cloudName = const String.fromEnvironment(
    'djju2bw16',
    defaultValue: 'djju2bw16',
  );

  static final String _uploadPreset = const String.fromEnvironment(
    'flutter_upload',
    defaultValue: 'flutter_upload',
  );

  static final CloudinaryPublic _cloudinary = CloudinaryPublic(
    _cloudName,
    _uploadPreset,
    cache: false,
  );

  static Future<String> uploadProductImage({
    required String fileName,
    Uint8List? webImageBytes,
    File? file,
  }) async {
    CloudinaryFile cloudinaryFile;
    if (kIsWeb) {
      if (webImageBytes == null || webImageBytes.isEmpty) {
        throw Exception('No image bytes provided for web upload');
      }
      cloudinaryFile = CloudinaryFile.fromBytesData(
        webImageBytes,
        identifier: fileName,
        folder: 'products',
        resourceType: CloudinaryResourceType.Image,
      );
    } else {
      if (file == null) {
        throw Exception('No image file provided for upload');
      }
      cloudinaryFile = CloudinaryFile.fromFile(
        file.path,
        folder: 'products',
        resourceType: CloudinaryResourceType.Image,
      );
    }

    final response = await _cloudinary.uploadFile(cloudinaryFile);
    return response.secureUrl;
  }
}
