import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// The Android app's R.drawable.car_placeholder (converted to SVG). Glide shows it while an
/// image loads and when it fails, so this widget does the same.
class CarPlaceholder extends StatelessWidget {
  final Color background;

  const CarPlaceholder({super.key, this.background = Colors.white});

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: background,
      child: LayoutBuilder(
        builder: (context, c) {
          final shortest = c.biggest.shortestSide;
          final pad = shortest.isFinite ? shortest * 0.12 : 8.0;
          return Padding(
            padding: EdgeInsets.all(pad),
            child: Center(
              child: SvgPicture.asset('assets/icons/car_placeholder.svg', fit: BoxFit.contain),
            ),
          );
        },
      ),
    );
  }
}

/// Image.network with the car placeholder shown while loading and on error, like Glide's
/// `.placeholder(R.drawable.car_placeholder).error(R.drawable.car_placeholder)`.
class AppNetworkImage extends StatelessWidget {
  final String? url;
  final BoxFit fit;
  final double? width;
  final double? height;
  final Color placeholderBackground;

  const AppNetworkImage(
    this.url, {
    super.key,
    this.fit = BoxFit.cover,
    this.width,
    this.height,
    this.placeholderBackground = Colors.white,
  });

  @override
  Widget build(BuildContext context) {
    final u = url;
    Widget placeholder() => SizedBox(
          width: width,
          height: height,
          child: CarPlaceholder(background: placeholderBackground),
        );
    if (u == null || u.trim().isEmpty) return placeholder();
    return Image.network(
      u,
      fit: fit,
      width: width,
      height: height,
      frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
        if (wasSynchronouslyLoaded || frame != null) return child;
        return placeholder();
      },
      errorBuilder: (_, __, ___) => placeholder(),
    );
  }
}
