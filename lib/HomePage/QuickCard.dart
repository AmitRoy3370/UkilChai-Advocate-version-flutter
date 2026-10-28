// QuickCard.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class QuickCard extends StatefulWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final LinearGradient gradient;

  const QuickCard({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    required this.gradient,
  });

  @override
  State<QuickCard> createState() => _QuickCardState();
}

class _QuickCardState extends State<QuickCard>
    with SingleTickerProviderStateMixin {
  bool _isHovered = false;
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.97).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final screenW = size.width;

    double wPct(double pct, {double min = 0, double max = 1e9}) =>
        (screenW * pct / 100).clamp(min, max);

    // Sizing
    final double cardPadding   = wPct(3.0, min: 10, max: 16);
    final double iconBox       = wPct(11, min: 40, max: 56);
    final double iconSize      = wPct(5.5, min: 20, max: 28);
    final double iconRadius    = wPct(3, min: 10, max: 16);
    final double titleSize     = wPct(3.4, min: 12, max: 15);
    final double subtitleSize  = wPct(2.6, min: 9.5, max: 11.5);
    final double cardRadius    = wPct(4, min: 12, max: 18);
    final double gapAfterIcon  = wPct(2, min: 6, max: 10);
    final double gapBeforeSub  = wPct(0.6, min: 2, max: 4);

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTapDown: (_) => _animationController.forward(),
        onTapUp: (_) => _animationController.reverse(),
        onTapCancel: () => _animationController.reverse(),
        child: AnimatedBuilder(
          animation: _scaleAnimation,
          builder: (context, child) {
            return Transform.scale(
              scale: _scaleAnimation.value,
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: widget.onTap,
                  borderRadius: BorderRadius.circular(cardRadius),
                  splashColor: Colors.white.withOpacity(0.25),
                  highlightColor: Colors.white.withOpacity(0.12),
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: widget.gradient,
                      borderRadius: BorderRadius.circular(cardRadius),
                      boxShadow: [
                        BoxShadow(
                          color: widget.gradient.colors.first
                              .withOpacity(_isHovered ? 0.4 : 0.28),
                          blurRadius: _isHovered ? 18 : 12,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Stack(
                      children: [
                        // Radial highlight — bottom-right corner
                        Positioned(
                          bottom: -40,
                          right: -40,
                          child: Container(
                            width: iconBox * 2.6,
                            height: iconBox * 2.6,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: RadialGradient(
                                colors: [
                                  Colors.white.withOpacity(0.15),
                                  Colors.white.withOpacity(0.0),
                                ],
                              ),
                            ),
                          ),
                        ),

                        // ✅ Positioned.fill forces content to fill the whole card
                        //    so the Column can truly center horizontally
                        Positioned.fill(
                          child: Padding(
                            padding: EdgeInsets.all(cardPadding),
                            child: Column(
                              // ✅ Center horizontally
                              crossAxisAlignment: CrossAxisAlignment.center,
                              // ✅ Center vertically
                              mainAxisAlignment: MainAxisAlignment.center,
                              mainAxisSize: MainAxisSize.max,  // ✅ fill height
                              children: [
                                // ── Icon box ──
                                Container(
                                  width: iconBox,
                                  height: iconBox,
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.20),
                                    borderRadius:
                                        BorderRadius.circular(iconRadius),
                                    border: Border.all(
                                      color: Colors.white.withOpacity(0.35),
                                      width: 1.5,
                                    ),
                                  ),
                                  child: FittedBox(
                                    fit: BoxFit.scaleDown,
                                    child: Padding(
                                      padding:
                                          EdgeInsets.all(iconSize * 0.6),
                                      child: Icon(
                                        widget.icon,
                                        size: iconSize,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ),

                                SizedBox(height: gapAfterIcon),

                                // ── Title — centered ──
                                Text(
                                  widget.title,
                                  textAlign: TextAlign.center,
                                  style: GoogleFonts.poppins(
                                    fontSize: titleSize,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                    height: 1.15,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),

                                SizedBox(height: gapBeforeSub),

                                // ── Subtitle — centered ──
                                Text(
                                  widget.subtitle,
                                  textAlign: TextAlign.center,
                                  style: GoogleFonts.inter(
                                    fontSize: subtitleSize,
                                    color:
                                        Colors.white.withOpacity(0.85),
                                    height: 1.2,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}