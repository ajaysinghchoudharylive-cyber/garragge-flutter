import 'dart:io';

import 'package:carsbuzz/sellcar/screens/sell_checklist_screen.dart';
import 'package:carsbuzz/sellcar/sell_car_flow.dart';
import 'package:carsbuzz/sellcar/widgets/sell_ui.dart';
import 'package:carsbuzz/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

/// Photo upload, a port of the Android UploadAndCapture fragment
/// (activity_upload_and_capture.xml): stepper, optional RC card, "Car Photos" with a counter
/// pill, 3-column photo grid, dashed "Add More Photos" card, tips card, and "Next".
class SellUploadPhotosScreen extends StatefulWidget {
  final SellCarFlow flow;

  const SellUploadPhotosScreen({super.key, required this.flow});

  @override
  State<SellUploadPhotosScreen> createState() => _SellUploadPhotosScreenState();
}

class _SellUploadPhotosScreenState extends State<SellUploadPhotosScreen> {
  static const int _minPhotos = 6;
  static const int _maxPhotos = 20;

  final ImagePicker _picker = ImagePicker();

  SellCarFlow get _flow => widget.flow;
  List<String> get _photos => _flow.form.imagePaths;
  bool get _hasRc => (_flow.form.rcImagePath ?? '').isNotEmpty;
  bool get _canContinue =>
      _photos.length >= _minPhotos && (!_flow.form.requiresRc || _hasRc);

  void _toast(String text) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(text)));
  }

  Future<ImageSource?> _askSource() {
    return showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.photo_camera_outlined, color: AppColors.accent),
                title: const Text('Take a photo'),
                onTap: () => Navigator.pop(ctx, ImageSource.camera),
              ),
              ListTile(
                leading: const Icon(Icons.photo_library_outlined, color: AppColors.accent),
                title: const Text('Choose from gallery'),
                onTap: () => Navigator.pop(ctx, ImageSource.gallery),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _addPhotos() async {
    final remaining = _maxPhotos - _photos.length;
    if (remaining <= 0) {
      _toast('Maximum 20 photos allowed');
      return;
    }
    final source = await _askSource();
    if (source == null) return;
    try {
      if (source == ImageSource.camera) {
        final image = await _picker.pickImage(
            source: ImageSource.camera, imageQuality: 80, maxWidth: 1920, maxHeight: 1080);
        if (image != null) setState(() => _photos.add(image.path));
      } else {
        final images =
            await _picker.pickMultiImage(imageQuality: 80, maxWidth: 1920, maxHeight: 1080);
        if (images.length > remaining) _toast('Maximum 20 photos allowed');
        setState(() => _photos.addAll(images.take(remaining).map((f) => f.path)));
      }
    } catch (e) {
      _toast('Could not add photo: $e');
    }
  }

  Future<void> _pickRc() async {
    final source = await _askSource();
    if (source == null) return;
    final image =
        await _picker.pickImage(source: source, imageQuality: 80, maxWidth: 1920, maxHeight: 1920);
    if (image != null) setState(() => _flow.form.rcImagePath = image.path);
  }

  void _onNext() {
    if (_flow.form.requiresRc && !_hasRc) {
      _toast("Please upload a photo of your car's RC");
      return;
    }
    Navigator.of(context).push(MaterialPageRoute(
      settings: const RouteSettings(name: SellRoutes.checklist),
      builder: (_) => SellChecklistScreen(flow: _flow),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      body: SafeArea(
        child: Column(
          children: [
            const SellToolbar(title: 'Sell Car', titleSize: 16, counter: '9/9'),
            const SellStepper(active: 1),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                children: [
                  if (_flow.form.requiresRc) _rcCard(),
                  _photosHeader(),
                  const SizedBox(height: 8),
                  if (_photos.isNotEmpty)
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      padding: EdgeInsets.zero,
                      itemCount: _photos.length,
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        crossAxisSpacing: 8,
                        mainAxisSpacing: 8,
                      ),
                      itemBuilder: (_, i) => _photoTile(i),
                    ),
                  const SizedBox(height: 16),
                  _addCard(),
                  const SizedBox(height: 24),
                  _tipsCard(),
                ],
              ),
            ),
            if (_canContinue)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
                child: SellPrimaryButton(text: 'Next', onPressed: _onNext),
              ),
          ],
        ),
      ),
    );
  }

  Widget _rcCard() {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: SellColors.slate200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Car RC photo (required)',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.black)),
          const SizedBox(height: 2),
          const Text(
            "Upload a clear photo of your car's Registration Certificate so we can verify the details.",
            style: TextStyle(fontSize: 13, color: SellColors.slate500),
          ),
          if (_hasRc) ...[
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Container(
                height: 160,
                width: double.infinity,
                color: const Color(0xFFECEFF3),
                child: Image.file(File(_flow.form.rcImagePath!), fit: BoxFit.cover),
              ),
            ),
          ],
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: OutlinedButton.icon(
              onPressed: _pickRc,
              icon: const Icon(Icons.photo_camera_outlined, size: 20),
              label: Text(_hasRc ? 'Change RC photo' : 'Upload RC photo',
                  style: const TextStyle(fontWeight: FontWeight.w600)),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.accent,
                side: const BorderSide(color: AppColors.accent),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _photosHeader() {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(
        children: [
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Car Photos',
                    style:
                        TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Colors.black)),
                SizedBox(height: 4),
                Text('Upload 6 to 20 clear photos of your car.',
                    style: TextStyle(fontSize: 14, color: SellColors.slate500)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFFEFF6FF),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.done, size: 16, color: AppColors.accent),
                const SizedBox(width: 6),
                Text('${_photos.length}/$_maxPhotos photos added',
                    style: const TextStyle(
                        fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.accent)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _photoTile(int i) {
    final path = _photos[i];
    return Stack(
      fit: StackFit.expand,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Container(
            color: const Color(0xFFF8FAFC),
            child: Image.file(
              File(path),
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) =>
                  const Icon(Icons.broken_image_outlined, color: Colors.black26),
            ),
          ),
        ),
        Positioned(
          top: 6,
          right: 6,
          child: GestureDetector(
            onTap: () => setState(() => _photos.removeAt(i)),
            child: Container(
              width: 20,
              height: 20,
              decoration: const BoxDecoration(color: AppColors.accent, shape: BoxShape.circle),
              child: const Icon(Icons.close, size: 12, color: Colors.white),
            ),
          ),
        ),
      ],
    );
  }

  Widget _addCard() {
    return InkWell(
      onTap: _addPhotos,
      borderRadius: BorderRadius.circular(12),
      child: CustomPaint(
        painter: _DashedBorderPainter(),
        child: SizedBox(
          height: 56,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration:
                    const BoxDecoration(color: Color(0xFFEFF6FF), shape: BoxShape.circle),
                child: const Icon(Icons.add, color: AppColors.accent),
              ),
              const SizedBox(width: 16),
              const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Add More Photos',
                      style: TextStyle(
                          fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.accent)),
                  Text('Tap to upload',
                      style: TextStyle(fontSize: 12, color: SellColors.slate500)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _tipsCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: SellColors.slate200),
      ),
      child: const Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: Color(0xFFEFF6FF),
            child: Icon(Icons.trending_flat, color: AppColors.accent),
          ),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Tips for best results',
                    style:
                        TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.black)),
                SizedBox(height: 2),
                Text('Use natural light and capture the car from\nall important angles.',
                    style: TextStyle(fontSize: 13, color: SellColors.slate500)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Dashed blue rounded border (Android bg_dashed_blue).
class _DashedBorderPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.accent
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    final rrect = RRect.fromRectAndRadius(Offset.zero & size, const Radius.circular(12));
    final path = Path()..addRRect(rrect);
    for (final metric in path.computeMetrics()) {
      double d = 0;
      while (d < metric.length) {
        canvas.drawPath(metric.extractPath(d, d + 6), paint);
        d += 10;
      }
    }
    canvas.drawRRect(rrect, Paint()..color = const Color(0x08FFFFFF));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
