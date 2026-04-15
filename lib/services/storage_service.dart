import 'dart:developer';
import 'dart:io';

import 'package:supabase_flutter/supabase_flutter.dart';

/// A dedicated service class for uploading images to Supabase Storage.
///
/// All upload paths strictly follow the conventions defined by the
/// Backend Team Lead to comply with storage-level RLS policies:
///
/// | Method                 | Bucket          | Path                                              |
/// |------------------------|-----------------|---------------------------------------------------|
/// | `uploadProfilePicture` | `avatars`       | `avatars/<user_id>/profile.jpg`                   |
/// | `uploadStoryCover`     | `story-images`  | `story-images/<user_id>/cover_<story_id>.jpg`     |
/// | `uploadStoryPageImage` | `story-images`  | `story-images/<user_id>/pages/<sid>_<page>.jpg`   |
///
/// Usage:
/// ```dart
/// final storageService = SupabaseStorageService();
/// final url = await storageService.uploadProfilePicture(
///   userId: 'abc-123',
///   imageFile: File('/path/to/image.jpg'),
/// );
/// ```
///
/// This class assumes [Supabase.initialize] has already been called
/// (typically in `main.dart`) before any method is invoked.
class SupabaseStorageService {
  /// Reference to the Supabase storage client.
  final SupabaseStorageClient _storage = Supabase.instance.client.storage;

  // -------------------------------------------------------------------------
  // Bucket name constants
  // -------------------------------------------------------------------------

  static const String _avatarsBucket = 'avatars';
  static const String _storyImagesBucket = 'story-images';

  // -------------------------------------------------------------------------
  // Profile Picture
  // -------------------------------------------------------------------------

  /// Uploads a user's profile picture to Supabase Storage.
  ///
  /// **Upload path:** `avatars/<userId>/profile.jpg`
  ///
  /// Uses `upsert: true` so subsequent uploads replace the existing file
  /// without conflict errors.
  ///
  /// Returns the **public URL** of the uploaded image.
  ///
  /// Throws [StorageServiceException] on failure.
  Future<String> uploadProfilePicture({
    required String userId,
    required File imageFile,
  }) async {
    final String filePath = '$userId/profile.jpg';

    try {
      await _storage.from(_avatarsBucket).upload(
            filePath,
            imageFile,
            fileOptions: const FileOptions(upsert: true),
          );

      final String publicUrl =
          _storage.from(_avatarsBucket).getPublicUrl(filePath);

      log(
        'Profile picture uploaded: $publicUrl',
        name: 'SupabaseStorageService',
      );

      return publicUrl;
    } on StorageException catch (e) {
      log(
        'Profile picture upload failed: ${e.message}',
        name: 'SupabaseStorageService',
      );
      throw StorageServiceException(
        'Failed to upload profile picture: ${e.message}',
      );
    } catch (e) {
      log(
        'Profile picture upload unexpected error: $e',
        name: 'SupabaseStorageService',
      );
      throw const StorageServiceException(
        'An unexpected error occurred while uploading your profile picture. '
        'Please try again.',
      );
    }
  }

  // -------------------------------------------------------------------------
  // Story Cover
  // -------------------------------------------------------------------------

  /// Uploads a story's cover image to Supabase Storage.
  ///
  /// **Upload path:** `story-images/<userId>/cover_<storyId>.jpg`
  ///
  /// Uses `upsert: true` so cover updates replace the existing file.
  ///
  /// Returns the **public URL** of the uploaded image.
  ///
  /// Throws [StorageServiceException] on failure.
  Future<String> uploadStoryCover({
    required String userId,
    required String storyId,
    required File imageFile,
  }) async {
    final String filePath = '$userId/cover_$storyId.jpg';

    try {
      await _storage.from(_storyImagesBucket).upload(
            filePath,
            imageFile,
            fileOptions: const FileOptions(upsert: true),
          );

      final String publicUrl =
          _storage.from(_storyImagesBucket).getPublicUrl(filePath);

      log(
        'Story cover uploaded: $publicUrl',
        name: 'SupabaseStorageService',
      );

      return publicUrl;
    } on StorageException catch (e) {
      log(
        'Story cover upload failed: ${e.message}',
        name: 'SupabaseStorageService',
      );
      throw StorageServiceException(
        'Failed to upload story cover: ${e.message}',
      );
    } catch (e) {
      log(
        'Story cover upload unexpected error: $e',
        name: 'SupabaseStorageService',
      );
      throw const StorageServiceException(
        'An unexpected error occurred while uploading the story cover. '
        'Please try again.',
      );
    }
  }

  // -------------------------------------------------------------------------
  // Story Page Image
  // -------------------------------------------------------------------------

  /// Uploads an individual story page illustration to Supabase Storage.
  ///
  /// **Upload path:** `story-images/<userId>/pages/<storyId>_<pageNumber>.jpg`
  ///
  /// Uses `upsert: true` so illustration updates replace the existing file.
  ///
  /// Returns the **public URL** of the uploaded image.
  ///
  /// Throws [StorageServiceException] on failure.
  Future<String> uploadStoryPageImage({
    required String userId,
    required String storyId,
    required int pageNumber,
    required File imageFile,
  }) async {
    final String filePath = '$userId/pages/${storyId}_$pageNumber.jpg';

    try {
      await _storage.from(_storyImagesBucket).upload(
            filePath,
            imageFile,
            fileOptions: const FileOptions(upsert: true),
          );

      final String publicUrl =
          _storage.from(_storyImagesBucket).getPublicUrl(filePath);

      log(
        'Story page image uploaded: $publicUrl',
        name: 'SupabaseStorageService',
      );

      return publicUrl;
    } on StorageException catch (e) {
      log(
        'Story page image upload failed: ${e.message}',
        name: 'SupabaseStorageService',
      );
      throw StorageServiceException(
        'Failed to upload story page image: ${e.message}',
      );
    } catch (e) {
      log(
        'Story page image upload unexpected error: $e',
        name: 'SupabaseStorageService',
      );
      throw const StorageServiceException(
        'An unexpected error occurred while uploading the page image. '
        'Please try again.',
      );
    }
  }
}

// ---------------------------------------------------------------------------
// Custom Exception
// ---------------------------------------------------------------------------

/// A clean, user-facing exception type for storage upload errors.
///
/// The [message] is safe to display in the UI (e.g., in a SnackBar).
class StorageServiceException implements Exception {
  final String message;

  const StorageServiceException(this.message);

  @override
  String toString() => 'StorageServiceException: $message';
}
