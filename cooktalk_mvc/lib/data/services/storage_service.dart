import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path/path.dart' as path;
import '../../core/utils/logger.dart';

class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;

  Future<String> uploadImage({
    required File file,
    required String storagePath,
    bool compress = true,
    int quality = 85,
  }) async {
    try {
      Logger.info('Uploading image to $storagePath');

      File fileToUpload = file;

      if (compress) {
        Logger.info('Compressing image...');
        final compressedFile = await _compressImage(file, quality);
        if (compressedFile != null) {
          fileToUpload = compressedFile;
          Logger.info('Image compressed successfully');
        }
      }

      final ref = _storage.ref().child(storagePath);
      final uploadTask = ref.putFile(
        fileToUpload,
        SettableMetadata(
          contentType: _getContentType(file.path),
        ),
      );

      uploadTask.snapshotEvents.listen((snapshot) {
        final progress = snapshot.bytesTransferred / snapshot.totalBytes * 100;
        Logger.info('Upload progress: ${progress.toStringAsFixed(2)}%');
      });

      final snapshot = await uploadTask;
      final downloadUrl = await snapshot.ref.getDownloadURL();

      Logger.info('Image uploaded successfully: $downloadUrl');
      return downloadUrl;
    } catch (e) {
      Logger.error('Failed to upload image', e);
      rethrow;
    }
  }

  Future<List<String>> uploadMultipleImages({
    required List<File> files,
    required String storageFolder,
    bool compress = true,
    int quality = 85,
  }) async {
    try {
      Logger.info('Uploading ${files.length} images to $storageFolder');
      
      final urls = <String>[];
      
      for (var i = 0; i < files.length; i++) {
        final file = files[i];
        final fileName = '${DateTime.now().millisecondsSinceEpoch}_$i${path.extension(file.path)}';
        final storagePath = '$storageFolder/$fileName';
        
        final url = await uploadImage(
          file: file,
          storagePath: storagePath,
          compress: compress,
          quality: quality,
        );
        
        urls.add(url);
      }
      
      Logger.info('All images uploaded successfully');
      return urls;
    } catch (e) {
      Logger.error('Failed to upload multiple images', e);
      rethrow;
    }
  }

  Future<void> deleteImage(String downloadUrl) async {
    try {
      Logger.info('Deleting image: $downloadUrl');
      final ref = _storage.refFromURL(downloadUrl);
      await ref.delete();
      Logger.info('Image deleted successfully');
    } catch (e) {
      Logger.error('Failed to delete image', e);
      rethrow;
    }
  }

  Future<void> deleteFolder(String folderPath) async {
    try {
      Logger.info('Deleting folder: $folderPath');
      final ref = _storage.ref().child(folderPath);
      final listResult = await ref.listAll();

      for (final item in listResult.items) {
        await item.delete();
      }

      for (final prefix in listResult.prefixes) {
        await deleteFolder(prefix.fullPath);
      }

      Logger.info('Folder deleted successfully');
    } catch (e) {
      Logger.error('Failed to delete folder', e);
      rethrow;
    }
  }

  String generateStoragePath({
    required String folder,
    required String userId,
    required String fileName,
  }) {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final extension = path.extension(fileName);
    return '$folder/$userId/${timestamp}_$fileName$extension';
  }

  String generateRecipeImagePath(String recipeId, String fileName) {
    return generateStoragePath(
      folder: 'recipes',
      userId: recipeId,
      fileName: fileName,
    );
  }

  String generateProfileImagePath(String userId, String fileName) {
    return generateStoragePath(
      folder: 'users',
      userId: userId,
      fileName: fileName,
    );
  }

  String generateSessionImagePath(String sessionId, String fileName) {
    return generateStoragePath(
      folder: 'sessions',
      userId: sessionId,
      fileName: fileName,
    );
  }

  String generatePostImagePath(String postId, String fileName) {
    return generateStoragePath(
      folder: 'posts',
      userId: postId,
      fileName: fileName,
    );
  }

  Future<File?> _compressImage(File file, int quality) async {
    try {
      final filePath = file.absolute.path;
      final lastIndex = filePath.lastIndexOf(RegExp(r'.jp'));
      final splitPath = filePath.substring(0, lastIndex);
      final outPath = '${splitPath}_compressed${path.extension(filePath)}';

      final result = await FlutterImageCompress.compressAndGetFile(
        file.absolute.path,
        outPath,
        quality: quality,
        minWidth: 1024,
        minHeight: 1024,
      );

      return result != null ? File(result.path) : null;
    } catch (e) {
      Logger.error('Failed to compress image', e);
      return null;
    }
  }

  String _getContentType(String filePath) {
    final extension = path.extension(filePath).toLowerCase();
    switch (extension) {
      case '.jpg':
      case '.jpeg':
        return 'image/jpeg';
      case '.png':
        return 'image/png';
      case '.gif':
        return 'image/gif';
      case '.webp':
        return 'image/webp';
      default:
        return 'application/octet-stream';
    }
  }

  Future<int> getFileSize(String downloadUrl) async {
    try {
      final ref = _storage.refFromURL(downloadUrl);
      final metadata = await ref.getMetadata();
      return metadata.size ?? 0;
    } catch (e) {
      Logger.error('Failed to get file size', e);
      return 0;
    }
  }

  Future<FullMetadata?> getMetadata(String downloadUrl) async {
    try {
      final ref = _storage.refFromURL(downloadUrl);
      return await ref.getMetadata();
    } catch (e) {
      Logger.error('Failed to get metadata', e);
      return null;
    }
  }
}
