import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Reusable Top Header with the Plodyo icon logo and "Plodyo" text name.
class PlodyoHeader extends StatelessWidget {
  const PlodyoHeader({
    super.key,
    this.padding = const EdgeInsets.only(bottom: 18),
  });

  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Image.asset(
            'assets/images/logo.png',
            width: 34,
            height: 34,
            errorBuilder: (context, error, stackTrace) => Container(
              width: 34,
              height: 34,
              decoration: const BoxDecoration(
                color: Color(0xFF9333EA),
                shape: BoxShape.circle,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Text(
            'Plodyo TV',
            style: GoogleFonts.baloo2(
              fontSize: 24,
              fontWeight: FontWeight.w900,
              color: const Color(0xFF9333EA),
              letterSpacing: -0.4,
            ),
          ),
        ],
      ),
    );
  }
}
