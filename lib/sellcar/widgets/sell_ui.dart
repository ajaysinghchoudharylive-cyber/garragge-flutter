import 'package:carsbuzz/sellcar/sell_car_flow.dart';
import 'package:carsbuzz/theme/app_colors.dart';
import 'package:flutter/material.dart';

/// Colours used across the Android sell screens.
class SellColors {
  SellColors._();
  static const Color brandsGray = Color(0xFF636363);
  static const Color apGray = Color(0xFF8C8C8C);
  static const Color pageBg = Color(0xFFF9F9F9);
  static const Color stroke = Color(0xFFF0F0F0);
  static const Color slate500 = Color(0xFF64748B);
  static const Color slate200 = Color(0xFFE2E8F0);
  static const Color green = Color(0xFF059669);
  static const Color green10 = Color(0xFF10B981);
  static const Color primaryLight = Color(0xFFE3F2FD);
  static const Color greySubtitle = Color(0xFF757575);
  static const Color designPurple = Color(0xFF4A55A2);
  static const Color emiResultBg = Color(0xFFF0F2FF);
  static const Color commentBg = Color(0xFFF5F7FF);
  static const Color softGreen = Color(0xFFECFDF5);
  static const Color softRed = Color(0xFFFEF2F2);
  static const Color softPurple = Color(0xFFF5F3FF);
}

/// Round grey back button (40dp circle #F3F4F6 with a black arrow).
class SellBackButton extends StatelessWidget {
  final VoidCallback onTap;

  const SellBackButton({super.key, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      customBorder: const CircleBorder(),
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: const BoxDecoration(color: Color(0xFFF3F4F6), shape: BoxShape.circle),
        child: const Icon(Icons.arrow_back, size: 20, color: Colors.black),
      ),
    );
  }
}

/// White toolbar used by every sell screen: back button, title, step counter, optional trailing.
class SellToolbar extends StatelessWidget {
  final String title;
  final double titleSize;
  final String? counter;
  final Widget? trailing;
  final VoidCallback? onBack;
  final double height;

  const SellToolbar({
    super.key,
    this.title = 'Sell Cars',
    this.titleSize = 18,
    this.counter,
    this.trailing,
    this.onBack,
    this.height = 56,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      height: height,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          SellBackButton(onTap: onBack ?? () => Navigator.of(context).maybePop()),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                  fontSize: titleSize, fontWeight: FontWeight.w700, color: Colors.black),
            ),
          ),
          if (counter != null)
            Text(counter!, style: const TextStyle(fontSize: 14, color: SellColors.apGray)),
          if (trailing != null) ...[const SizedBox(width: 12), trailing!],
        ],
      ),
    );
  }
}

/// "Your Car Details" chips. Each chip opens the screen that edits that value.
class CarDetailsSummary extends StatelessWidget {
  final SellCarFlow flow;
  final ValueChanged<SummaryType> onTap;
  final Color background;

  const CarDetailsSummary({
    super.key,
    required this.flow,
    required this.onTap,
    this.background = Colors.transparent,
  });

  @override
  Widget build(BuildContext context) {
    final items = flow.summary();
    if (items.isEmpty) return const SizedBox.shrink();
    return Container(
      width: double.infinity,
      color: background,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Your Car Details',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.black)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: [
              for (final (text, type) in items)
                ActionChip(
                  label: Text(text, style: const TextStyle(fontSize: 13, color: Colors.black)),
                  backgroundColor: SellColors.primaryLight,
                  side: BorderSide.none,
                  elevation: 2,
                  shadowColor: Colors.black26,
                  shape: const StadiumBorder(),
                  onPressed: () => onTap(type),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

/// The three-step header on the photo and checklist screens: Details, Upload Image, Add. Info.
/// [active] is 1 (photos) or 2 (additional info).
class SellStepper extends StatelessWidget {
  final int active;

  const SellStepper({super.key, required this.active});

  @override
  Widget build(BuildContext context) {
    Widget step(int index, String label, IconData activeIcon) {
      final done = index < active;
      final isActive = index == active;
      final Color bg = isActive ? AppColors.accent : const Color(0xFFF3F4F6);
      final Color tint = isActive
          ? Colors.white
          : done
              ? SellColors.green10
              : const Color(0xFF9CA3AF);
      final IconData icon = done ? Icons.done : activeIcon;
      return SizedBox(
        width: 72,
        child: Column(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
              child: Icon(icon, size: 16, color: tint),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isActive ? FontWeight.w700 : FontWeight.w400,
                color: isActive ? AppColors.accent : const Color(0xFF9CA3AF),
              ),
            ),
          ],
        ),
      );
    }

    Widget line(bool done) => Container(
          width: 60,
          height: 2,
          margin: const EdgeInsets.only(top: 15),
          color: done ? SellColors.green10 : const Color(0xFFE5E7EB),
        );

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          step(0, 'Details', Icons.done),
          line(active > 0),
          step(1, 'Upload Image', Icons.photo_camera_outlined),
          line(active > 1),
          step(2, 'Add. Info', Icons.add),
        ],
      ),
    );
  }
}

/// Extended "Next →" button pinned bottom-right (Android ExtendedFloatingActionButton).
class SellNextFab extends StatelessWidget {
  final VoidCallback onPressed;

  const SellNextFab({super.key, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton.extended(
      heroTag: null,
      onPressed: onPressed,
      backgroundColor: AppColors.accent,
      foregroundColor: Colors.white,
      elevation: 4,
      label: const Row(
        children: [
          Text('Next', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
          SizedBox(width: 8),
          Icon(Icons.arrow_forward, size: 20),
        ],
      ),
    );
  }
}

/// Full-width blue button with a trailing arrow (Widget.AchoApp.Button + ic_arrow_forward).
class SellPrimaryButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final double height;
  final double fontSize;
  final bool loading;

  const SellPrimaryButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.height = 56,
    this.fontSize = 16,
    this.loading = false,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: height,
      child: ElevatedButton(
        onPressed: loading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.accent,
          disabledBackgroundColor: AppColors.accent.withValues(alpha: 0.6),
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        child: loading
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(text,
                      style: TextStyle(fontSize: fontSize, fontWeight: FontWeight.w700)),
                  const SizedBox(width: 12),
                  const Icon(Icons.arrow_forward, size: 20),
                ],
              ),
      ),
    );
  }
}

/// Asks for a free-text value (used for "Other" model / variant / colour).
Future<String?> askSellText(
  BuildContext context, {
  required String title,
  required String hint,
  String? message,
}) async {
  final controller = TextEditingController();
  final result = await showDialog<String>(
    context: context,
    builder: (ctx) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 18)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (message != null) ...[
            Text(message, style: const TextStyle(fontSize: 13, color: SellColors.slate500)),
            const SizedBox(height: 12),
          ],
          TextField(
            controller: controller,
            autofocus: true,
            textCapitalization: TextCapitalization.words,
            decoration: InputDecoration(hintText: hint),
          ),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
        TextButton(
          onPressed: () {
            final text = controller.text.trim();
            if (text.isNotEmpty) Navigator.pop(ctx, text);
          },
          child: const Text('OK',
              style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.accent)),
        ),
      ],
    ),
  );
  controller.dispose();
  return result;
}

/// White search card, radius 8, 48dp, search icon (Android item_model_selection_search).
class SellSearchBox extends StatelessWidget {
  final String hint;
  final ValueChanged<String> onChanged;

  const SellSearchBox({super.key, required this.hint, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: SellColors.stroke),
        boxShadow: const [
          BoxShadow(color: Color(0x14000000), blurRadius: 4, offset: Offset(0, 1)),
        ],
      ),
      child: Row(
        children: [
          const Icon(Icons.search, size: 20, color: SellColors.brandsGray),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              onChanged: onChanged,
              textCapitalization: TextCapitalization.words,
              style: const TextStyle(fontSize: 14),
              decoration: InputDecoration(
                hintText: hint,
                isDense: true,
                border: InputBorder.none,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
