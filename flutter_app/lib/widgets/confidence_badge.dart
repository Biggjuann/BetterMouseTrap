import 'package:flutter/material.dart';

class ConfidenceBadge extends StatelessWidget {
  final String level;
  const ConfidenceBadge({super.key, required this.level});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: ShapeDecoration(
        color: _color,
        shape: const StadiumBorder(),
      ),
      child: Text(
        _label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  String get _label {
    switch (level) {
      case 'high':
        return 'High';
      case 'med':
        return 'Medium';
      default:
        return 'Low';
    }
  }

  Color get _color {
    switch (level) {
      case 'high':
        return Colors.green;
      case 'med':
        return Colors.orange;
      default:
        return Colors.red;
    }
  }
}
