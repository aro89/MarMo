import 'package:flutter/material.dart';
import 'package:dropdown_button2/dropdown_button2.dart';

Widget buildDropdownGeneric<T>({
  required T? value,
  required List<T> items,
  required String hint,
  required void Function(T?) onChanged,
  String Function(T)? itemToString,
  String? Function(T?)? validator,
  IconData? icon,
}) {
  return FormField<T>(
    validator: validator ?? (val) => val == null ? 'Please select an option' : null,
    builder: (FormFieldState<T> state) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: state.hasError ? Colors.red : Colors.grey.shade300),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: DropdownButtonHideUnderline(
              child: DropdownButton2<T>(
                isExpanded: true,
                value: value,
                hint: Row(
                  children: [
                    if (icon != null) ...[
                      Icon(icon, size: 20, color: Colors.grey.shade600),
                      const SizedBox(width: 12),
                    ],
                    Expanded(
                      child: Text(
                        hint,
                        style: TextStyle(fontSize: 15, color: Colors.grey.shade700),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                items: items.map((item) {
                  final displayText = itemToString != null ? itemToString(item) : item.toString();
                  return DropdownMenuItem<T>(
                    value: item,
                    child: Text(
                      displayText,
                      style: const TextStyle(fontSize: 15),
                      overflow: TextOverflow.ellipsis,
                    ),
                  );
                }).toList(),
                onChanged: (selected) {
                  onChanged(selected);
                  state.didChange(selected);
                },
                buttonStyleData: const ButtonStyleData(
                  height: 55,
                  padding: EdgeInsets.symmetric(horizontal: 8),
                ),
                iconStyleData: IconStyleData(
                  icon: const Icon(Icons.keyboard_arrow_down),
                  iconSize: 20,
                  iconEnabledColor: Colors.grey.shade700,
                  iconDisabledColor: Colors.grey.shade400,
                ),
                dropdownStyleData: DropdownStyleData(
                  maxHeight: 300,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                  scrollbarTheme: ScrollbarThemeData(
                    radius: const Radius.circular(8),
                    thickness: WidgetStateProperty.all(6),
                    thumbVisibility: WidgetStateProperty.all(true),
                  ),
                ),
                menuItemStyleData: const MenuItemStyleData(
                  height: 50,
                  padding: EdgeInsets.symmetric(horizontal: 16),
                ),
              ),
            ),
          ),
          if (state.hasError)
            Padding(
              padding: const EdgeInsets.only(top: 5, left: 8),
              child: Text(
                state.errorText ?? '',
                style: TextStyle(color: Colors.red.shade700, fontSize: 12),
              ),
            ),
        ],
      );
    },
  );
}
