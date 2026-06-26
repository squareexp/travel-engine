import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../design/colors.dart';

/// "Twende Zanzibar" — serif wordmark + small palm icon.
class TwendeBrand extends StatelessWidget {
  const TwendeBrand({
    super.key,
    this.size = 22,
    this.subtitle,
    this.color = TwendeColors.textPrimary,
  });

  final double size;
  final String? subtitle;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Twende Zanzibar',
          style: GoogleFonts.playfairDisplay(
            fontSize: size,
            fontWeight: FontWeight.w700,
            color: color,
            height: 1.1,
            letterSpacing: -0.3,
          ),
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 2),
          Text(
            subtitle!,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w400,
              color: color.withValues(alpha: 0.7),
            ),
          ),
        ],
      ],
    );
  }
}
