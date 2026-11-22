import 'package:carsbuzz/theme/app_colors.dart';
import 'package:flutter/material.dart';

/// Primary button, same as the Android app's Widget.AchoApp.Button: 56dp, radius 12,
/// #2563EB, Outfit bold 16sp white. While [loading] it shows the three-dot loader instead of text.
class AppButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool loading;
  final double height;
  final Color color;

  const AppButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.loading = false,
    this.height = 56,
    this.color = AppColors.accent,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: height,
      child: ElevatedButton(
        onPressed: loading ? () {} : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          disabledBackgroundColor: color.withValues(alpha: 0.5),
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: const TextStyle(
            fontFamily: 'Outfit',
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
        child: loading ? const ThreeDotLoader() : Text(text),
      ),
    );
  }
}

/// Port of the Android app's ThreeDotProgressBar (white dots pulsing in turn).
class ThreeDotLoader extends StatefulWidget {
  final Color color;

  const ThreeDotLoader({super.key, this.color = Colors.white});

  @override
  State<ThreeDotLoader> createState() => _ThreeDotLoaderState();
}

class _ThreeDotLoaderState extends State<ThreeDotLoader>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (i) {
            final phase = (_controller.value * 3 - i) % 3;
            final active = phase >= 0 && phase < 1;
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 3),
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: widget.color.withValues(alpha: active ? 1 : 0.4),
                shape: BoxShape.circle,
              ),
            );
          }),
        );
      },
    );
  }
}

/// Simple message dialog with an OK button (Android: Utilities.showDialogFragment).
Future<void> showMessageDialog(BuildContext context, String message,
    {VoidCallback? onOk}) {
  return showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (ctx) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      content: Text(
        message,
        style: const TextStyle(
            fontFamily: 'Outfit', fontSize: 16, color: AppColors.textPrimary),
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(ctx).pop();
            onOk?.call();
          },
          child: const Text('OK',
              style: TextStyle(
                  fontFamily: 'Outfit',
                  fontWeight: FontWeight.w700,
                  color: AppColors.accent)),
        ),
      ],
    ),
  );
}

/// Yes / No confirmation dialog (Android: Utilities.deleteAdBuilder). Returns true on Yes.
Future<bool> showConfirmDialog(BuildContext context, String message) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      content: Text(
        message,
        style: const TextStyle(
            fontFamily: 'Outfit', fontSize: 16, color: AppColors.textPrimary),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(false),
          child: const Text('No',
              style: TextStyle(fontFamily: 'Outfit', color: AppColors.slate500)),
        ),
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(true),
          child: const Text('Yes',
              style: TextStyle(
                  fontFamily: 'Outfit',
                  fontWeight: FontWeight.w700,
                  color: AppColors.accent)),
        ),
      ],
    ),
  );
  return result ?? false;
}

/// Blue snackbar used on the login / OTP screens (login_snackbar_bg, white text).
void showAppSnackBar(BuildContext context, String message,
    {Duration duration = const Duration(seconds: 3)}) {
  final messenger = ScaffoldMessenger.of(context);
  messenger.hideCurrentSnackBar();
  messenger.showSnackBar(
    SnackBar(
      content: Text(message,
          style: const TextStyle(fontFamily: 'Outfit', color: Colors.white)),
      backgroundColor: AppColors.snackbar,
      duration: duration,
      behavior: SnackBarBehavior.floating,
    ),
  );
}
