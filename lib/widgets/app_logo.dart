import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// The Garragge logo, same artwork as the Android app's res/drawable/app_logo.xml.
class AppLogo extends StatelessWidget {
  final double size;

  const AppLogo({super.key, this.size = 100});

  @override
  Widget build(BuildContext context) {
    return SvgPicture.asset(
      'assets/icons/app_logo.svg',
      width: size,
      height: size,
      fit: BoxFit.contain,
    );
  }
}
