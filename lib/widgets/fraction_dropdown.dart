import 'package:flutter/material.dart';
import 'package:inventory_frontend/models/fraction.dart';

class FractionDropdown extends StatelessWidget {
  final List<Fraction> fractions;
  final String selectedFractionId;
  final ValueChanged<String> onChanged;
  final double maxWidth;

  const FractionDropdown({
    super.key,
    required this.fractions,
    required this.selectedFractionId,
    required this.onChanged,
    this.maxWidth = 140,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(maxWidth: maxWidth),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          isDense: true,
          value: selectedFractionId,
          items: fractions.map((fraction) {
            return DropdownMenuItem<String>(
              value: fraction.id,
              child: Row(
                children: [
                  Icon(Icons.scale, color: Colors.blue.shade400, size: 18),
                  const SizedBox(width: 8),
                  Text(
                    fraction.name,
                    style: const TextStyle(fontWeight: FontWeight.w500),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            );
          }).toList(),
          onChanged: (value) {
            if (value != null) {
              onChanged(value);
            }
          },
          dropdownColor: Colors.white,
          style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.w600),
          icon: const Icon(Icons.arrow_drop_down, color: Colors.blue),
        ),
      ),
    );
  }
}