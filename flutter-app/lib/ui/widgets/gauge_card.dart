import 'package:flutter/material.dart';

class GaugeCard extends StatefulWidget {
  final String label;
  final String value;
  final String unit;
  final bool warning;

  const GaugeCard({
    super.key,
    required this.label,
    required this.value,
    required this.unit,
    required this.warning,
  });

  @override
  State<GaugeCard> createState() => _GaugeCardState();
}

class _GaugeCardState extends State<GaugeCard> with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 900));
    _anim = Tween<double>(begin: 0.75, end: 1.0).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
    _ctrl.repeat(reverse: true);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final borderColor = widget.warning
        ? const Color(0xFFB60000)
        : const Color(0x9E0AFF00); // rgba(10,255,0,0.62)

    final bgColor = widget.warning
        ? const Color(0xE0F10000)
        : const Color(0x29000000); // black 16%

    return ScaleTransition(
      scale: widget.warning ? _anim : const AlwaysStoppedAnimation(1.0),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: borderColor, width: 1),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              widget.label,
              style: TextStyle(
                color: Colors.white.withOpacity(0.8),
                fontSize: 12,
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              widget.value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 32,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              widget.unit,
              style: TextStyle(
                color: Colors.white.withOpacity(0.7),
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
