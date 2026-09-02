import 'package:flutter/material.dart';

/// SmartAutoCar brand mark from [assets/logo.png].
class AppLogo extends StatelessWidget {
  const AppLogo({
    super.key,
    this.height = 88,
    this.width,
    this.fit = BoxFit.contain,
  });

  final double height;
  final double? width;
  final BoxFit fit;

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/logo.png',
      height: height,
      width: width,
      fit: fit,
      filterQuality: FilterQuality.high,
      gaplessPlayback: true,
    );
  }
}
