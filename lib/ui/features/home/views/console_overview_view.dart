import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/widgets/plodyo_header.dart';
import '../../../../core/widgets/tv_section_badge.dart';

class ConsoleCardData {
  const ConsoleCardData({
    required this.title,
    required this.description,
    required this.icon,
    required this.route,
  });

  final String title;
  final String description;
  final IconData icon;
  final String route;
}

/// Console Overview Dashboard View matching the Plodyo TV design.
class ConsoleOverviewView extends StatefulWidget {
  const ConsoleOverviewView({super.key});

  @override
  State<ConsoleOverviewView> createState() => _ConsoleOverviewViewState();
}

class _ConsoleOverviewViewState extends State<ConsoleOverviewView> {
  static const List<ConsoleCardData> consoleCards = [
    ConsoleCardData(
      title: 'Partners',
      description:
          'Review applications, onboard a venue by hand, and set how many rooms each may sign in.',
      icon: Icons.apartment_rounded,
      route: '/partners',
    ),
    ConsoleCardData(
      title: 'Invites',
      description:
          'Send someone an account, chase one that was never accepted, or revoke it.',
      icon: Icons.mail_outline_rounded,
      route: '/invites',
    ),
    ConsoleCardData(
      title: 'Properties',
      description:
          'The buildings rooms are created under. Suspending one stops every room in it.',
      icon: Icons.account_balance_outlined,
      route: '/properties',
    ),
    ConsoleCardData(
      title: 'Rooms',
      description:
          'One row per TV. Pair a set, take one out of service, or add a floor at a time.',
      icon: Icons.meeting_room_outlined,
      route: '/rooms',
    ),
    ConsoleCardData(
      title: 'People',
      description:
          'Everyone who can sign in within your scope, and whether they still can.',
      icon: Icons.people_outline_rounded,
      route: '/people',
    ),
    ConsoleCardData(
      title: 'Account',
      description:
          'The account this session is signed in as, and how to sign out.',
      icon: Icons.settings_outlined,
      route: '/settings',
    ),
  ];

  late final List<FocusNode> _focusNodes;

  @override
  void initState() {
    super.initState();
    _focusNodes = List.generate(consoleCards.length, (_) => FocusNode());
  }

  @override
  void dispose() {
    for (final node in _focusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAF7FC),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Sticky Top Plodyo Logo Header
            const Padding(
              padding: EdgeInsets.fromLTRB(52, 18, 52, 14),
              child: PlodyoHeader(padding: EdgeInsets.zero),
            ),

            // Sticky Screen Name Section (Title + Superadmin Badge + Subtitle)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 52),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Floating 4-Square Icon Box with white border and glow
                      const TvSectionBadge(
                        icon: Icons.grid_view_rounded,
                        size: 54,
                        iconSize: 28,
                        gradientColors: [
                          Color(0xFFF472B6),
                          Color(0xFFD946EF),
                          Color(0xFF9333EA),
                        ],
                      ),
                      const SizedBox(width: 16),

                      // "Console" text
                      Text(
                        'Console',
                        style: GoogleFonts.baloo2(
                          fontSize: 34,
                          fontWeight: FontWeight.w900,
                          color: const Color(0xFF9333EA),
                          letterSpacing: -0.6,
                        ),
                      ),
                      const SizedBox(width: 14),

                      // "Superadmin" Pill Badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFFDCFCE7),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                            color: const Color(0xFFBBF7D0),
                            width: 1.2,
                          ),
                        ),
                        child: Text(
                          'Superadmin',
                          style: GoogleFonts.nunito(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF166534),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // Explanatory Subtitle
                  Text(
                    'Every partner, property and room on Plodyo TV. The story library is not here —\nit is shown by the TVs themselves, each signed in with its own room credential.',
                    style: GoogleFonts.nunito(
                      fontSize: 15,
                      height: 1.45,
                      fontWeight: FontWeight.w400,
                      color: const Color(0xFF4B5563),
                    ),
                  ),
                  const SizedBox(height: 18),
                ],
              ),
            ),

            // Scrollable 2-Column Grid of 6 Management Action Cards
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(52, 4, 52, 28),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                // Left Column (Cards 0, 2, 4: Partners, Properties, People)
                Expanded(
                  child: Column(
                    children: [
                      _ConsoleActionCard(
                        card: consoleCards[0],
                        focusNode: _focusNodes[0],
                        autofocus: true,
                        onKeyNavigate: (key) {
                          if (key == LogicalKeyboardKey.arrowRight) {
                            _focusNodes[1].requestFocus();
                            return true;
                          } else if (key == LogicalKeyboardKey.arrowDown) {
                            _focusNodes[2].requestFocus();
                            return true;
                          }
                          return false;
                        },
                      ),
                      const SizedBox(height: 16),
                      _ConsoleActionCard(
                        card: consoleCards[2],
                        focusNode: _focusNodes[2],
                        onKeyNavigate: (key) {
                          if (key == LogicalKeyboardKey.arrowRight) {
                            _focusNodes[3].requestFocus();
                            return true;
                          } else if (key == LogicalKeyboardKey.arrowDown) {
                            _focusNodes[4].requestFocus();
                            return true;
                          } else if (key == LogicalKeyboardKey.arrowUp) {
                            _focusNodes[0].requestFocus();
                            return true;
                          }
                          return false;
                        },
                      ),
                      const SizedBox(height: 16),
                      _ConsoleActionCard(
                        card: consoleCards[4],
                        focusNode: _focusNodes[4],
                        onKeyNavigate: (key) {
                          if (key == LogicalKeyboardKey.arrowRight) {
                            _focusNodes[5].requestFocus();
                            return true;
                          } else if (key == LogicalKeyboardKey.arrowUp) {
                            _focusNodes[2].requestFocus();
                            return true;
                          }
                          return false;
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 22),

                // Right Column (Cards 1, 3, 5: Invites, Rooms, Account)
                Expanded(
                  child: Column(
                    children: [
                      _ConsoleActionCard(
                        card: consoleCards[1],
                        focusNode: _focusNodes[1],
                        onKeyNavigate: (key) {
                          if (key == LogicalKeyboardKey.arrowLeft) {
                            _focusNodes[0].requestFocus();
                            return true;
                          } else if (key == LogicalKeyboardKey.arrowDown) {
                            _focusNodes[3].requestFocus();
                            return true;
                          }
                          return false;
                        },
                      ),
                      const SizedBox(height: 16),
                      _ConsoleActionCard(
                        card: consoleCards[3],
                        focusNode: _focusNodes[3],
                        onKeyNavigate: (key) {
                          if (key == LogicalKeyboardKey.arrowLeft) {
                            _focusNodes[2].requestFocus();
                            return true;
                          } else if (key == LogicalKeyboardKey.arrowDown) {
                            _focusNodes[5].requestFocus();
                            return true;
                          } else if (key == LogicalKeyboardKey.arrowUp) {
                            _focusNodes[1].requestFocus();
                            return true;
                          }
                          return false;
                        },
                      ),
                      const SizedBox(height: 16),
                      _ConsoleActionCard(
                        card: consoleCards[5],
                        focusNode: _focusNodes[5],
                        onKeyNavigate: (key) {
                          if (key == LogicalKeyboardKey.arrowLeft) {
                            _focusNodes[4].requestFocus();
                            return true;
                          } else if (key == LogicalKeyboardKey.arrowUp) {
                            _focusNodes[3].requestFocus();
                            return true;
                          }
                          return false;
                        },
                      ),
                    ],
                  ),
                ),
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

class _ConsoleActionCard extends StatefulWidget {
  const _ConsoleActionCard({
    required this.card,
    required this.focusNode,
    this.autofocus = false,
    this.onKeyNavigate,
  });

  final ConsoleCardData card;
  final FocusNode focusNode;
  final bool autofocus;
  final bool Function(LogicalKeyboardKey key)? onKeyNavigate;

  @override
  State<_ConsoleActionCard> createState() => _ConsoleActionCardState();
}

class _ConsoleActionCardState extends State<_ConsoleActionCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final isFocused = widget.focusNode.hasFocus;
    final isHighlighted = isFocused || _isHovered;

    return Focus(
      focusNode: widget.focusNode,
      autofocus: widget.autofocus,
      onFocusChange: (_) => setState(() {}),
      onKeyEvent: (node, event) {
        if (event is KeyDownEvent) {
          final key = event.logicalKey;
          if (widget.onKeyNavigate != null && widget.onKeyNavigate!(key)) {
            return KeyEventResult.handled;
          }
          if (key == LogicalKeyboardKey.select ||
              key == LogicalKeyboardKey.enter ||
              key == LogicalKeyboardKey.space ||
              key == LogicalKeyboardKey.gameButtonA) {
            context.go(widget.card.route);
            return KeyEventResult.handled;
          }
        }
        return KeyEventResult.ignored;
      },
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        child: GestureDetector(
          onTap: () {
            widget.focusNode.requestFocus();
            context.go(widget.card.route);
          },
          child: AnimatedScale(
            scale: isHighlighted ? 1.02 : 1.0,
            duration: const Duration(milliseconds: 140),
            curve: Curves.easeOutCubic,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 140),
              curve: Curves.easeOutCubic,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isHighlighted
                      ? const Color(0xFF8B5CF6)
                      : const Color(0xFFCBD5E1).withValues(alpha: 0.8),
                  width: isHighlighted ? 2.0 : 1.3,
                ),
                boxShadow: [
                  if (isHighlighted)
                    BoxShadow(
                      color: const Color(0xFF8B5CF6).withValues(alpha: 0.38),
                      blurRadius: 24,
                      spreadRadius: 2.5,
                      offset: const Offset(0, 6),
                    )
                  else ...const [
                    BoxShadow(
                      color: Color(0x0A000000),
                      blurRadius: 8,
                      offset: Offset(0, 3),
                    ),
                    BoxShadow(
                      color: Color(0x059333EA),
                      blurRadius: 12,
                      offset: Offset(0, 4),
                    ),
                  ],
                ],
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Leading Icon inside rounded container (Larger size: 28px)
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: isHighlighted
                          ? const Color(0xFFF3E8FF)
                          : const Color(0xFFFAF5FF),
                      borderRadius: BorderRadius.circular(13),
                      border: Border.all(
                        color: isHighlighted
                            ? const Color(0xFFDDD6FE)
                            : const Color(0xFFF1EBF5),
                        width: 1.2,
                      ),
                    ),
                    child: Center(
                      child: Icon(
                        widget.card.icon,
                        size: 26,
                        color: const Color(0xFF9333EA),
                      ),
                    ),
                  ),
                  const SizedBox(width: 18),

                  // Title & Description (Larger typography)
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.card.title,
                          style: GoogleFonts.baloo2(
                            fontSize: 19.5,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF0F172A),
                            letterSpacing: -0.2,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          widget.card.description,
                          style: GoogleFonts.nunito(
                            fontSize: 14.5,
                            fontWeight: FontWeight.w400,
                            color: const Color(0xFF64748B),
                            height: 1.48,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),

                  // Trailing Chevron (Larger size: 26px)
                  Icon(
                    Icons.chevron_right_rounded,
                    size: 26,
                    color: isHighlighted
                        ? const Color(0xFF8B5CF6)
                        : const Color(0xFF94A3B8),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
