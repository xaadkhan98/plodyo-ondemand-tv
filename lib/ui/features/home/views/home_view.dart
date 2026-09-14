import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
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
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Sticky Top Header: Logo + "Plodyo" Name
            const Padding(
              padding: EdgeInsets.fromLTRB(32, 16, 32, 8),
              child: PlodyoHeader(),
            ),

            // Scrollable Main Content Body
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: EdgeInsets.symmetric(
                  horizontal: horizontalSpacing,
                  vertical: 12,
                ),
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
                        Text(
                          'New this week',
                          style: GoogleFonts.baloo2(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF18181B),
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
                        separatorBuilder: (context, index) =>
                            const SizedBox(width: 14),
                        itemBuilder: (context, index) {
                          return const ShimmerBox(
                            width: 115,
                            height: 170,
                            borderRadius: BorderRadius.all(Radius.circular(14)),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
