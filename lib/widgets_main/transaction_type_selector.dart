// widgets_authentication/transaction_type_selector.dart
import 'package:flutter/material.dart';
import '../theme/color.dart';

class TransactionTypeSelector extends StatelessWidget {
  final String? selectedType;
  final void Function(String) onTypeSelected;

  const TransactionTypeSelector({
    Key? key,
    required this.selectedType,
    required this.onTypeSelected,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(child: _buildTypeButton('Income', Icons.arrow_downward, Colors.green)),
          Expanded(child: _buildTypeButton('Expense', Icons.arrow_upward, Colors.redAccent)),
        ],
      ),
    );
  }

  Widget _buildTypeButton(String type, IconData icon, Color activeColor) {
    final isSelected = selectedType == type;

    return InkWell(
      onTap: () => onTypeSelected(type),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: isSelected ? activeColor.withOpacity(0.2) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: isSelected ? Border.all(color: activeColor, width: 2) : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: isSelected ? activeColor : Colors.grey, size: 18),
            const SizedBox(width: 8),
            Text(
              type,
              style: TextStyle(
                color: isSelected ? activeColor : Colors.grey.shade700,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
