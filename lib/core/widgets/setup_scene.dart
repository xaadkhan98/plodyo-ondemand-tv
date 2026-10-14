import 'package:flutter/widgets.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// The scene behind the screens a set shows before it has a room: stars over a low horizon. Without it,
/// one short sentence on a 1080p panel reads as an error page rather than the start of a bedtime app.
class NightBackdrop extends StatelessWidget {
  const NightBackdrop({super.key});

  @override
  Widget build(BuildContext context) {
    // `slice` in the SVG: cover the screen, cropping rather than letterboxing.
    return IgnorePointer(
      child: SvgPicture.asset(
        'assets/images/night_backdrop.svg',
        fit: BoxFit.cover,
      ),
    );
  }
}

/// A set with a story already playing in it: the one bold thing the unpaired screen shows from the door.
class TvSetArt extends StatelessWidget {
  const TvSetArt({super.key, required this.height});

  final double height;

  @override
  Widget build(BuildContext context) =>
      SvgPicture.asset('assets/images/tv_set.svg', height: height);
}
