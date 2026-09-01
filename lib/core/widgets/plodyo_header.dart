import 'package:flutter/material.dart';

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
            width: 28,
            height: 28,
            errorBuilder: (context, error, stackTrace) => Container(
              width: 28,
              height: 28,
              decoration: const BoxDecoration(
                color: Color(0xFF9333EA),
                shape: BoxShape.circle,
              ),
            ),
          ),
          const SizedBox(width: 8),
          const Text(
            'Plodyo',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: Color(0xFF9333EA),
              letterSpacing: -0.4,
            ),
          ),
        ],
      ),
    );
  }
}
