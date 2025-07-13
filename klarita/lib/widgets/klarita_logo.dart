import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';

class KlaritaLogo extends StatelessWidget {
  final double fontSize;
  final bool center;
  const KlaritaLogo({Key? key, this.fontSize = 26, this.center = false}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).brightness == Brightness.dark
        ? AppTheme.darkTextPrimary
        : AppTheme.primary;
    return Row(
      mainAxisAlignment: center ? MainAxisAlignment.center : MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Icon(Icons.auto_awesome, color: color, size: fontSize * 0.9),
        const SizedBox(width: 8),
        Text(
          'Klarita',
          style: GoogleFonts.manrope(
            fontWeight: FontWeight.w800,
            fontSize: fontSize,
            color: color,
            letterSpacing: -1.2,
          ),
        ),
      ],
    );
  }
} 