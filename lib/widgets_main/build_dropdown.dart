import 'package:flutter/material.dart';
import 'package:dropdown_button2/dropdown_button2.dart';

Widget buildDropdown({
  required String? value,
  required List<String> items,
  required String hint,
  required Function(String) onChanged,
  IconData? icon,
  bool showSearch = false,
}) {
  final TextEditingController searchController = TextEditingController();

  return Container(
    decoration: BoxDecoration(
      color: Colors.grey[200],
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: Colors.grey.shade300),
    ),
    child: DropdownButtonHideUnderline(
      child: DropdownButton2<String>(
        isExpanded: true,
        hint: Row(
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                size: 20,
                color: Colors.grey.shade600,
              ),
              const SizedBox(width: 12),
            ],
            Expanded(
              child: Text(
                hint,
                style: TextStyle(
                  fontSize: 15,
                  color: Colors.grey.shade700,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        items: items.map((item) => DropdownMenuItem(
          value: item,
          child: Row(
            children: [
              Expanded(
                child: Text(
                  item,
                  style: const TextStyle(
                    fontSize: 15,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        )).toList(),
        value: value,
        onChanged: (value) {
          if (value != null) {
            onChanged(value);
          }
        },
        buttonStyleData: ButtonStyleData(
          padding: const EdgeInsets.only(left: 16, right: 16),
          height: 55,
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.grey[200],
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        iconStyleData: IconStyleData(
          icon: const Icon(Icons.keyboard_arrow_down),
          iconSize: 20,
          iconDisabledColor: Colors.grey.shade400,
          iconEnabledColor: Colors.grey.shade700,
        ),
        dropdownStyleData: DropdownStyleData(
          maxHeight: 300,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: Colors.white,
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
          padding: EdgeInsets.only(left: 16, right: 16),
        ),
        // Add search functionality if enabled
        dropdownSearchData: showSearch && items.length > 5
            ? DropdownSearchData(
          searchController: searchController,
          searchInnerWidgetHeight: 50,
          searchInnerWidget: Container(
            height: 50,
            padding: const EdgeInsets.only(
              top: 8,
              bottom: 4,
              right: 8,
              left: 8,
            ),
            child: TextFormField(
              expands: true,
              maxLines: null,
              controller: searchController,
              decoration: InputDecoration(
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 8,
                ),
                hintText: 'Search...',
                hintStyle: const TextStyle(fontSize: 14),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
          searchMatchFn: (item, searchValue) {
            return item.value.toString().toLowerCase().contains(searchValue.toLowerCase());
          },
        )
            : null,
      ),
    ),
  );
}