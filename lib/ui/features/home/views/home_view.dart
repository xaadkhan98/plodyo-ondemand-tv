import 'package:flutter/material.dart';
import '../../../../core/widgets/shimmer_box.dart';
import '../../../../core/widgets/plodyo_header.dart';

/// Shimmer Skeleton Home View matching Plodyo UI design.
class HomeView extends StatelessWidget {
  const HomeView({
    super.key,
    this.viewModel,
    this.onMediaSelected,
  });

  final dynamic viewModel;
  final dynamic onMediaSelected;

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final horizontalSpacing = screenWidth * 0.10;

    return Scaffold(
      backgroundColor: const Color(0xFFFAF7FC),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Header: Logo + "Plodyo" Name (kept at default padding)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 32),
              child: PlodyoHeader(),
            ),

            // Main Section UI with 10% horizontal screen spacing
            Padding(
              padding: EdgeInsets.symmetric(horizontal: horizontalSpacing),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Big Hero Banner Shimmer Placeholder
                  const ShimmerBox(
                    width: double.infinity,
                    height: 250,
                    borderRadius: BorderRadius.all(Radius.circular(18)),
                  ),

                  const SizedBox(height: 24),

                  // Section Header: "| New this week"
                  Row(
                    children: [
                      Container(
                        width: 3.5,
                        height: 18,
                        decoration: BoxDecoration(
                          color: const Color(0xFF9333EA),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'New this week',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF18181B),
                          letterSpacing: -0.2,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 14),

                  // Horizontal Story Cards Shimmer Rail
                  SizedBox(
                    height: 170,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      physics: const BouncingScrollPhysics(),
                      itemCount: 8,
                      separatorBuilder: (context, index) => const SizedBox(width: 14),
                      itemBuilder: (context, index) {
                        return const ShimmerBox(
                          width: 115,
                          height: 170,
                          borderRadius: BorderRadius.all(Radius.circular(14)),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
