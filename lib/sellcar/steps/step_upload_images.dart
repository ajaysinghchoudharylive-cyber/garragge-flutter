import 'package:flutter/material.dart';

/// Step 8: Upload images & submit - mirrors native FragmentUploadOptions / UploadAndCapture
class StepUploadImages extends StatelessWidget {
  final List<String> imageUrls;
  final bool isSubmitting;
  final ValueChanged<List<String>> onImagesChanged;
  final VoidCallback onSubmit;

  const StepUploadImages({
    super.key,
    required this.imageUrls,
    required this.isSubmitting,
    required this.onImagesChanged,
    required this.onSubmit,
  });

  void _addImagePlaceholder(BuildContext context) {
    // In production, use image_picker to capture or pick photos
    // For now, simulate adding an image
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Image picker will be integrated with image_picker package'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _removeImage(int index) {
    final updated = List<String>.from(imageUrls);
    updated.removeAt(index);
    onImagesChanged(updated);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Upload photos of your car',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Add up to 10 photos. Cars with photos get 5x more responses.',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade500,
            ),
          ),
          const SizedBox(height: 20),

          // Image grid
          Expanded(
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
              ),
              itemCount: imageUrls.length + 1, // +1 for the add button
              itemBuilder: (context, index) {
                if (index == imageUrls.length) {
                  // Add button
                  return GestureDetector(
                    onTap: () => _addImagePlaceholder(context),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.grey.shade300,
                          style: BorderStyle.solid,
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.add_a_photo,
                            color: Colors.grey.shade500,
                            size: 32,
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Add Photo',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                // Image thumbnail
                return Stack(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        color: Colors.grey.shade200,
                        image: DecorationImage(
                          image: NetworkImage(imageUrls[index]),
                          fit: BoxFit.cover,
                          onError: (_, __) {},
                        ),
                      ),
                      child: imageUrls[index].isEmpty
                          ? const Center(
                              child: Icon(Icons.image, color: Colors.grey))
                          : null,
                    ),
                    Positioned(
                      top: 4,
                      right: 4,
                      child: GestureDetector(
                        onTap: () => _removeImage(index),
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.close,
                            color: Colors.white,
                            size: 14,
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),

          const SizedBox(height: 16),

          // Tips section
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF8E1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                const Icon(Icons.lightbulb_outline,
                    color: Color(0xFFF57C00), size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Tip: Take photos in good lighting. Include front, back, sides, interior and dashboard.',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade700,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Submit button
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: isSubmitting ? null : onSubmit,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green.shade600,
                disabledBackgroundColor: Colors.grey.shade300,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: isSubmitting
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text(
                      'Post Ad',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
