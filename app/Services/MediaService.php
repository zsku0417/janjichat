<?php

namespace App\Services;

use App\Models\Media;
use Illuminate\Http\UploadedFile;
use Illuminate\Support\Facades\Storage;
use Illuminate\Support\Facades\Http;
use Illuminate\Support\Facades\Log;
use CloudinaryLabs\CloudinaryLaravel\Facades\Cloudinary;
use Exception;

class MediaService
{
    /**
     * Upload a file to Cloudinary and create a Media record.
     *
     * @param UploadedFile $file
     * @param int $userId
     * @param string $folder Folder path in Cloudinary (e.g., 'documents', 'images', 'avatars')
     * @param string $resourceType 'raw' for documents, 'image' for images, 'video' for videos
     * @param array $options Additional Cloudinary upload options
     * @return Media
     */
    public function upload(
        UploadedFile $file,
        int $userId,
        string $folder = 'uploads',
        string $resourceType = 'raw',
        array $options = []
    ): Media {
        try {
            $originalName = $file->getClientOriginalName();
            $extension = strtolower($file->getClientOriginalExtension());
            $nameWithoutExt = pathinfo($originalName, PATHINFO_FILENAME);
            $sanitizedName = $this->sanitizeFilename($nameWithoutExt . '.' . $extension);
            $publicId = time() . '_' . pathinfo($sanitizedName, PATHINFO_FILENAME);
            $folderPath = "{$folder}/{$userId}";

            // Merge default options with provided options
            $uploadOptions = array_merge([
                'folder' => $folderPath,
                'public_id' => $publicId,
                'resource_type' => $resourceType,
                'type' => 'upload', // Makes files publicly accessible
                'access_mode' => 'public', // Explicitly set public access
                'use_filename' => true,
                'unique_filename' => false,
            ], $options);

            // For raw files, we need to add the format to preserve extension
            if ($resourceType === 'raw' && !isset($options['format'])) {
                $uploadOptions['format'] = $extension;
            }

            // Upload to Cloudinary using the correct method
            $uploadResult = cloudinary()->uploadApi()->upload(
                $file->getRealPath(),
                $uploadOptions
            );

            if (!$uploadResult) {
                throw new \Exception('Cloudinary upload returned null');
            }

            // Get the public ID and secure URL from the result
            $cloudinaryPublicId = $uploadResult['public_id'];
            $secureUrl = $uploadResult['secure_url'];

            // Create Media record
            $media = Media::create([
                'user_id' => $userId,
                'disk' => 'cloudinary',
                'path' => $cloudinaryPublicId,
                'original_name' => $originalName,
                'file_type' => $this->getFileType($file),
                'mime_type' => $file->getMimeType(),
                'file_size' => $file->getSize(),
                'cloudinary_public_id' => $cloudinaryPublicId,
                'metadata' => [
                    'resource_type' => $resourceType,
                    'folder' => $folderPath,
                    'secure_url' => $secureUrl,
                    'format' => $uploadResult['format'] ?? $extension,
                    'width' => $uploadResult['width'] ?? null,
                    'height' => $uploadResult['height'] ?? null,
                ],
            ]);

            return $media;
        } catch (\Exception $e) {
            Log::error('Cloudinary upload failed', [
                'file' => $file->getClientOriginalName(),
                'error' => $e->getMessage(),
                'trace' => $e->getTraceAsString()
            ]);
            throw $e;
        }
    }

    /**
     * Upload a document (PDF, DOCX, TXT, etc.) to Cloudinary.
     *
     * @param UploadedFile $file
     * @param int $userId
     * @param string|null $subfolder Optional subfolder (e.g., 'files', 'contracts')
     * @return Media
     */
    public function uploadDocument(UploadedFile $file, int $userId, ?string $subfolder = 'files'): Media
    {
        $folder = $subfolder ? "documents/{$subfolder}" : 'documents';

        $media = $this->upload($file, $userId, $folder, 'raw');

        // Store locally for text extraction during processing
        $localFilename = time() . '_' . $this->sanitizeFilename($file->getClientOriginalName());
        $localPath = $file->storeAs('documents', $localFilename, 'local');

        // Update metadata with local path for processing
        $metadata = $media->metadata ?? [];
        $metadata['local_path'] = $localPath;
        $media->update(['metadata' => $metadata]);

        return $media;
    }

    /**
     * Upload an image to Cloudinary with optional transformations.
     *
     * @param UploadedFile $file
     * @param int $userId
     * @param string $folder Folder for images (e.g., 'avatars', 'products', 'gallery')
     * @param array $transformations Cloudinary transformations (e.g., ['width' => 500, 'height' => 500, 'crop' => 'fill'])
     * @return Media
     */
    public function uploadImage(UploadedFile $file, int $userId, string $folder = 'images', array $transformations = []): Media
    {
        $options = [];

        if (!empty($transformations)) {
            $options['transformation'] = $transformations;
        }

        return $this->upload($file, $userId, $folder, 'image', $options);
    }

    /**
     * Upload a video to Cloudinary.
     *
     * @param UploadedFile $file
     * @param int $userId
     * @param string $folder
     * @return Media
     */
    public function uploadVideo(UploadedFile $file, int $userId, string $folder = 'videos'): Media
    {
        return $this->upload($file, $userId, $folder, 'video');
    }

    /**
     * Delete a media file from Cloudinary and database.
     *
     * @param Media $media
     * @return bool
     */
    public function delete(Media $media): bool
    {
        // Delete from Cloudinary
        if ($media->cloudinary_public_id) {
            try {
                $resourceType = $media->metadata['resource_type'] ?? 'raw';
                cloudinary()->uploadApi()->destroy(
                    $media->cloudinary_public_id,
                    ['resource_type' => $resourceType]
                );
            } catch (Exception $e) {
                Log::warning('Failed to delete file from Cloudinary', [
                    'media_id' => $media->id,
                    'public_id' => $media->cloudinary_public_id,
                    'error' => $e->getMessage(),
                ]);
            }
        }

        // Delete local file if exists
        $localPath = $media->metadata['local_path'] ?? null;
        if ($localPath && Storage::disk('local')->exists($localPath)) {
            Storage::disk('local')->delete($localPath);
        }

        // Delete the media record
        return $media->delete();
    }

    /**
     * Download a file from Cloudinary to a temporary location.
     *
     * @param Media $media
     * @return string Path to the downloaded file
     * @throws Exception
     */
    public function downloadToTemp(Media $media): string
    {
        $tempPath = storage_path('app/temp/' . $media->original_name);

        // Ensure temp directory exists
        if (!is_dir(dirname($tempPath))) {
            mkdir(dirname($tempPath), 0755, true);
        }

        // Get secure URL from metadata or generate it
        $url = $media->metadata['secure_url'] ?? $this->getCloudinaryUrl($media);

        // Download file from Cloudinary URL
        $response = Http::get($url);

        if ($response->successful()) {
            file_put_contents($tempPath, $response->body());
            return $tempPath;
        }

        throw new Exception('Failed to download file from Cloudinary');
    }

    /**
     * Generate Cloudinary URL for a media file.
     *
     * @param Media $media
     * @return string
     */
    protected function getCloudinaryUrl(Media $media): string
    {
        $resourceType = $media->metadata['resource_type'] ?? 'raw';
        $cloudName = config('filesystems.disks.cloudinary.cloud');

        return "https://res.cloudinary.com/{$cloudName}/{$resourceType}/upload/{$media->cloudinary_public_id}";
    }

    /**
     * Get the local file path if available, otherwise download from Cloudinary.
     *
     * @param Media $media
     * @return string Path to the file
     */
    public function getLocalPath(Media $media): string
    {
        // First try local file (for initial processing)
        $localPath = $media->metadata['local_path'] ?? null;

        if ($localPath && Storage::disk('local')->exists($localPath)) {
            return Storage::disk('local')->path($localPath);
        }

        // Download from Cloudinary
        return $this->downloadToTemp($media);
    }

    /**
     * Clean up the local temporary file for a media.
     *
     * @param Media $media
     * @return void
     */
    public function cleanupLocalFile(Media $media): void
    {
        $localPath = $media->metadata['local_path'] ?? null;

        if ($localPath && Storage::disk('local')->exists($localPath)) {
            Storage::disk('local')->delete($localPath);
        }

        // Clear the local path from metadata
        $metadata = $media->metadata ?? [];
        unset($metadata['local_path']);
        $media->update(['metadata' => $metadata ?: null]);
    }

    /**
     * Sanitize filename for safe storage.
     *
     * @param string $filename
     * @return string
     */
    protected function sanitizeFilename(string $filename): string
    {
        // Remove special characters but keep extension
        $name = pathinfo($filename, PATHINFO_FILENAME);
        $ext = pathinfo($filename, PATHINFO_EXTENSION);

        // Replace spaces and special chars with underscores
        $name = preg_replace('/[^a-zA-Z0-9_-]/', '_', $name);
        $name = preg_replace('/_+/', '_', $name); // Remove multiple underscores

        return $name . '.' . $ext;
    }

    /**
     * Get file type from uploaded file.
     *
     * @param UploadedFile $file
     * @return string
     */
    protected function getFileType(UploadedFile $file): string
    {
        $extension = strtolower($file->getClientOriginalExtension());

        return match ($extension) {
            'pdf' => 'pdf',
            'docx', 'doc' => 'docx',
            'txt' => 'txt',
            'md', 'markdown' => 'md',
            'jpg', 'jpeg' => 'jpg',
            'png' => 'png',
            'gif' => 'gif',
            'webp' => 'webp',
            'svg' => 'svg',
            'mp4' => 'mp4',
            'mov' => 'mov',
            'avi' => 'avi',
            default => $extension,
        };
    }
}