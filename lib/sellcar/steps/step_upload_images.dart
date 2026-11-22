import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

/// Step 10: Upload photos & videos - mirrors native UploadAndCapture fragment
/// Features:
/// - Camera and gallery image picking
/// - Grid display of selected photos
/// - Minimum 6 photos validation (native requirement)
/// - Maximum 20 photos limit
/// - Exterior & interior video placeholders
/// - ML car detection placeholder (native uses MLKit)
class StepUploadImages extends StatefulWidget {
  final List<String> imageUrls;
  final bool isSubmitting;
  final ValueChanged<List<String>> onImagesChanged;
  final VoidCallback onSubmit;

  /// True when the seller picked an "Other" model/variant/colour: an RC (registration
  /// certificate) photo is then required so an admin can verify the details.
  final bool requiresRc;
  final String? rcImagePath;
  final ValueChanged<String?>? onRcChanged;

  const StepUploadImages({
    super.key,
    required this.imageUrls,
    required this.isSubmitting,
    required this.onImagesChanged,
    required this.onSubmit,
    this.requiresRc = false,
    this.rcImagePath,
    this.onRcChanged,
  });

  @override
  State<StepUploadImages> createState() => _StepUploadImagesState();
}

class _StepUploadImagesState extends State<StepUploadImages> {
  final ImagePicker _picker = ImagePicker();
  String? _exteriorVideoPath;
  String? _interiorVideoPath;

  static const int _minPhotos = 6;
  static const int _maxPhotos = 20;

  bool get _hasMinimumPhotos => widget.imageUrls.length >= _minPhotos;

  bool get _hasRc =>
      widget.rcImagePath != null && widget.rcImagePath!.isNotEmpty;

  bool get _canContinue => _hasMinimumPhotos && (!widget.requiresRc || _hasRc);

  Future<void> _pickRc(ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        imageQuality: 80,
        maxWidth: 1920,
        maxHeight: 1920,
      );
      if (image != null) widget.onRcChanged?.call(image.path);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not pick RC photo: $e')),
        );
      }
    }
  }

  Widget _buildRcCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF3E0),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: _hasRc ? Colors.green.shade300 : const Color(0xFFFFB74D),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'RC photo required',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          ),
          const SizedBox(height: 2),
          Text(
            'You chose an option that is not in our list. Add a photo of your '
            'registration certificate (RC) so we can verify the details.',
            style: TextStyle(fontSize: 11, color: Colors.grey.shade700),
          ),
          const SizedBox(height: 8),
          if (_hasRc)
            Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.green, size: 18),
                const SizedBox(width: 6),
                const Expanded(
                  child: Text('RC photo added', style: TextStyle(fontSize: 12)),
                ),
                TextButton(
                  onPressed: () => widget.onRcChanged?.call(null),
                  child: const Text('Remove'),
                ),
              ],
            )
          else
            Row(
              children: [
                OutlinedButton.icon(
                  onPressed: () => _pickRc(ImageSource.camera),
                  icon: const Icon(Icons.camera_alt, size: 16),
                  label: const Text('Camera'),
                ),
                const SizedBox(width: 8),
                OutlinedButton.icon(
                  onPressed: () => _pickRc(ImageSource.gallery),
                  icon: const Icon(Icons.photo_library, size: 16),
                  label: const Text('Gallery'),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Future<void> _pickFromCamera() async {
    if (widget.imageUrls.length >= _maxPhotos) {
      _showMaxLimitMessage();
      return;
    }

    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 80,
        maxWidth: 1920,
        maxHeight: 1080,
      );

      if (image != null) {
        final updated = List<String>.from(widget.imageUrls)..add(image.path);
        widget.onImagesChanged(updated);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Camera error: $e')),
        );
      }
    }
  }

  Future<void> _pickFromGallery() async {
    final remaining = _maxPhotos - widget.imageUrls.length;
    if (remaining <= 0) {
      _showMaxLimitMessage();
      return;
    }

    try {
      final List<XFile> images = await _picker.pickMultiImage(
        imageQuality: 80,
        maxWidth: 1920,
        maxHeight: 1080,
      );

      if (images.isNotEmpty) {
        final toAdd = images.take(remaining).map((f) => f.path).toList();
        final updated = List<String>.from(widget.imageUrls)..addAll(toAdd);
        widget.onImagesChanged(updated);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gallery error: $e')),
        );
      }
    }
  }

  Future<void> _pickVideo(bool isExterior) async {
    try {
      final XFile? video = await _picker.pickVideo(
        source: ImageSource.camera,
        maxDuration: const Duration(seconds: 30),
      );

      if (video != null && mounted) {
        setState(() {
          if (isExterior) {
            _exteriorVideoPath = video.path;
          } else {
            _interiorVideoPath = video.path;
          }
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Video error: $e')),
        );
      }
    }
  }

  void _removeImage(int index) {
    final updated = List<String>.from(widget.imageUrls)..removeAt(index);
    widget.onImagesChanged(updated);
  }

  void _showMaxLimitMessage() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Maximum 20 photos allowed')),
    );
  }

  void _showUploadOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Add Photos',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE3F2FD),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.camera_alt, color: Color(0xFF1A73E8)),
                ),
                title: const Text('Take Photo'),
                subtitle: const Text('Use camera to capture'),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickFromCamera();
                },
              ),
              const SizedBox(height: 8),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8F5E9),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.photo_library, color: Colors.green),
                ),
                title: const Text('Choose from Gallery'),
                subtitle: const Text('Select multiple photos'),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickFromGallery();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Header info
        Container(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    '${widget.imageUrls.length}/$_maxPhotos photos',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: _hasMinimumPhotos
                          ? Colors.green.shade700
                          : Colors.orange.shade700,
                    ),
                  ),
                  const SizedBox(width: 8),
                  if (!_hasMinimumPhotos)
                    Text(
                      '(min $_minPhotos required)',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.orange.shade700,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 4),
              // Progress bar for minimum photos
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: (widget.imageUrls.length / _minPhotos).clamp(0.0, 1.0),
                  backgroundColor: Colors.grey.shade200,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    _hasMinimumPhotos ? Colors.green : Colors.orange,
                  ),
                  minHeight: 4,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 12),

        // Photo grid
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
            ),
            itemCount: widget.imageUrls.length + 1,
            itemBuilder: (context, index) {
              if (index == 0) {
                // Add button (always first)
                return _AddPhotoButton(onTap: _showUploadOptions);
              }

              final imageIndex = index - 1;
              final path = widget.imageUrls[imageIndex];

              return _PhotoTile(
                path: path,
                index: imageIndex,
                onRemove: () => _removeImage(imageIndex),
              );
            },
          ),
        ),

        // Video section
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              Expanded(
                child: _VideoCard(
                  label: 'Exterior Video',
                  icon: Icons.videocam,
                  hasVideo: _exteriorVideoPath != null,
                  onTap: () => _pickVideo(true),
                  onDelete: () => setState(() => _exteriorVideoPath = null),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _VideoCard(
                  label: 'Interior Video',
                  icon: Icons.videocam,
                  hasVideo: _interiorVideoPath != null,
                  onTap: () => _pickVideo(false),
                  onDelete: () => setState(() => _interiorVideoPath = null),
                ),
              ),
            ],
          ),
        ),

        if (widget.requiresRc) _buildRcCard(),

        // Tips
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: const Color(0xFFFFF8E1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            children: [
              const Icon(Icons.lightbulb_outline,
                  color: Color(0xFFF57C00), size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Take clear photos: front, back, both sides, dashboard, engine & interior.',
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade700),
                ),
              ),
            ],
          ),
        ),

        // Continue button
        Padding(
          padding: const EdgeInsets.all(16),
          child: SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: _canContinue ? widget.onSubmit : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1A73E8),
                disabledBackgroundColor: Colors.grey.shade300,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                _hasMinimumPhotos
                    ? (_canContinue ? 'Continue' : 'Add RC photo')
                    : 'Add ${_minPhotos - widget.imageUrls.length} more photo${_minPhotos - widget.imageUrls.length == 1 ? '' : 's'}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _AddPhotoButton extends StatelessWidget {
  final VoidCallback onTap;

  const _AddPhotoButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFFF5F9FF),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: const Color(0xFF1A73E8),
            style: BorderStyle.solid,
            width: 1.5,
          ),
        ),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add_a_photo, color: Color(0xFF1A73E8), size: 28),
            SizedBox(height: 4),
            Text(
              'Add',
              style: TextStyle(
                fontSize: 12,
                color: Color(0xFF1A73E8),
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PhotoTile extends StatelessWidget {
  final String path;
  final int index;
  final VoidCallback onRemove;

  const _PhotoTile({
    required this.path,
    required this.index,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: _buildImage(),
        ),
        // Index badge
        Positioned(
          bottom: 4,
          left: 4,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.black54,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              '${index + 1}',
              style: const TextStyle(
                  color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
            ),
          ),
        ),
        // Remove button
        Positioned(
          top: 4,
          right: 4,
          child: GestureDetector(
            onTap: onRemove,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: const BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.close, color: Colors.white, size: 14),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildImage() {
    // Check if it's a local file path or a network URL
    if (path.startsWith('http')) {
      return Image.network(
        path,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _placeholder(),
      );
    }
    final file = File(path);
    if (file.existsSync()) {
      return Image.file(file, fit: BoxFit.cover);
    }
    return _placeholder();
  }

  Widget _placeholder() {
    return Container(
      color: Colors.grey.shade200,
      child: const Center(
        child: Icon(Icons.broken_image, color: Colors.grey),
      ),
    );
  }
}

class _VideoCard extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool hasVideo;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _VideoCard({
    required this.label,
    required this.icon,
    required this.hasVideo,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: hasVideo ? null : onTap,
      child: Container(
        height: 60,
        decoration: BoxDecoration(
          color: hasVideo ? const Color(0xFFE8F5E9) : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: hasVideo ? Colors.green.shade300 : Colors.grey.shade300,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              hasVideo ? Icons.check_circle : icon,
              color: hasVideo ? Colors.green : Colors.grey.shade500,
              size: 20,
            ),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                hasVideo ? 'Recorded' : label,
                style: TextStyle(
                  fontSize: 11,
                  color: hasVideo ? Colors.green.shade700 : Colors.grey.shade600,
                  fontWeight: FontWeight.w500,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (hasVideo) ...[
              const SizedBox(width: 4),
              GestureDetector(
                onTap: onDelete,
                child: const Icon(Icons.close, color: Colors.red, size: 16),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
