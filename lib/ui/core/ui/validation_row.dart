import 'package:flutter/material.dart';

class ValidationRow extends StatelessWidget {
  final String text;
  final bool isValid;

  const ValidationRow({
    required this.text,
    required this.isValid,
  });

  @override
  Widget build(BuildContext context) {
    final color = isValid ? Colors.green : Colors.grey;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Icon(
            isValid ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
            color: color,
            size: 20,
          ),
          const SizedBox(width: 10),
          Text(
            text,
            style: TextStyle(
              color: color,
              fontWeight: isValid ? FontWeight.bold : FontWeight.normal,
              //decoration: isValid ? TextDecoration.lineThrough : null,
            ),
          ),
        ],
      ),
    );
  }
}