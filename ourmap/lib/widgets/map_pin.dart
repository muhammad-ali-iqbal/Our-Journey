import 'package:flutter/material.dart';
import '../models/memory.dart';
import '../utils/app_theme.dart';

class MapPin extends StatefulWidget {
  final Memory memory;
  final bool isSelected;
  final VoidCallback onTap;

  const MapPin({
    super.key,
    required this.memory,
    required this.isSelected,
    required this.onTap,
  });

  @override
  State<MapPin> createState() => _MapPinState();
}

class _MapPinState extends State<MapPin> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _pulse;
  late Animation<double> _glow;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2800),
    )..repeat(reverse: true);

    _pulse = Tween<double>(begin: 1.0, end: 1.12).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
    _glow = Tween<double>(begin: 0.4, end: 0.9).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = widget.isSelected ? 40.0 : 28.0;

    return GestureDetector(
      onTap: widget.onTap,
      child: AnimatedBuilder(
        animation: _ctrl,
        builder: (context, child) {
          return SizedBox(
            width: size + 24,
            height: size + 24,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Glow circle
                Container(
                  width: size + 20,
                  height: size + 20,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        AppColors.gold.withOpacity(
                          widget.isSelected
                              ? _glow.value * 0.5
                              : _glow.value * 0.25,
                        ),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),

                // Heart icon
                Transform.scale(
                  scale: _pulse.value,
                  child: Icon(
                    Icons.favorite,
                    color: AppColors.gold,
                    size: size,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
