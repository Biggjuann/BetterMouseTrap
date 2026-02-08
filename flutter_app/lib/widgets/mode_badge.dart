import 'package:flutter/material.dart';

class ModeBadge extends StatelessWidget {
  final String mode;
  final String label;
  const ModeBadge({super.key, required this.mode, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: ShapeDecoration(
        color: _colorForMode(mode),
        shape: const StadiumBorder(),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  static Color _colorForMode(String mode) {
    switch (mode) {
      case 'cost_down':
        return Colors.blue;
      case 'durability':
        return Colors.brown;
      case 'safety':
        return Colors.red;
      case 'convenience':
        return Colors.green;
      case 'sustainability':
        return Colors.teal;
      case 'performance':
        return Colors.orange;
      case 'mashup':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }
}
