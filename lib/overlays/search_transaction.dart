import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:madmet/models/transaction_model.dart';
import 'package:madmet/models/wallet_model.dart';
import 'package:madmet/firestore_service.dart';
import 'package:intl/intl.dart';
import 'package:madmet/theme/color.dart';

import '../utils/get_category_icons.dart';
import '../widgets_main/build_dropdown_generic.dart';
import '../widgets_main/build_text_field.dart';
import '../widgets_main/build_label.dart';
import '../widgets_main/build_dropdown.dart';
import '../misc/category_list.dart';
import '../overlays/update_transaction.dart';

class SearchTransactionsOverlay extends StatefulWidget {
  const SearchTransactionsOverlay({Key? key}) : super(key: key);

  @override
  State<SearchTransactionsOverlay> createState() => _SearchTransactionsOverlayState();
}

class _SearchTransactionsOverlayState extends State<SearchTransactionsOverlay> {
  final TextEditingController searchController = TextEditingController();

  final FirestoreService _firestoreService = FirestoreService();

  List<TransactionModel> allTransactions = [];
  List<TransactionModel> filteredTransactions = [];
  List<Wallet> wallets = [];

  String? selectedFilterType;  // Type / Wallet / Category / Date / None
  String? selectedSecondary;   // Selected value from second dropdown

  // Date range filtering
  DateTime? selectedStartDate;
  DateTime? selectedEndDate;
  bool isDateRangeMode = false;

  Timer? _debounce;

  String get userId => FirebaseAuth.instance.currentUser?.uid ?? '';

  @override
  void initState() {
    super.initState();
    _fetchData();
    searchController.addListener(_onSearchChanged);
  }

  Future<void> _fetchData() async {
    final txns = await _firestoreService.getTransactions(userId);
    final userWallets = await _firestoreService.getWallets(userId);
    setState(() {
      allTransactions = txns;
      filteredTransactions = txns;
      wallets = userWallets;
    });
  }

  void _onSearchChanged() {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), _filterTransactions);
  }

  void _filterTransactions() {
    final query = searchController.text.toLowerCase();

    setState(() {
      filteredTransactions = allTransactions.where((txn) {
        // Apply filter dropdown condition
        bool matchesSecondary = true;

        if (selectedFilterType == 'Type') {
          matchesSecondary = selectedSecondary == null ||
              txn.type.toLowerCase() == selectedSecondary!.toLowerCase();
        } else if (selectedFilterType == 'Wallet') {
          matchesSecondary = selectedSecondary == null ||
              txn.walletId == selectedSecondary;
        } else if (selectedFilterType == 'Category') {
          matchesSecondary = selectedSecondary == null ||
              txn.category == selectedSecondary;
        } else if (selectedFilterType == 'Date') {
          // Handle date filtering
          if (isDateRangeMode && selectedStartDate != null && selectedEndDate != null) {
            // Add one day to end date to include the entire end date
            final endDatePlusOne = selectedEndDate!.add(const Duration(days: 1));
            matchesSecondary = txn.date.isAfter(selectedStartDate!) &&
                txn.date.isBefore(endDatePlusOne);
          } else if (selectedSecondary != null) {
            // Single date option selected
            final txnDate = DateFormat('yyyy-MM-dd').format(txn.date);

            if (selectedSecondary == 'Today') {
              final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
              matchesSecondary = txnDate == today;
            } else if (selectedSecondary == 'This Week') {
              final now = DateTime.now();
              final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
              final endOfWeek = startOfWeek.add(const Duration(days: 6));
              matchesSecondary = txn.date.isAfter(startOfWeek.subtract(const Duration(days: 1))) &&
                  txn.date.isBefore(endOfWeek.add(const Duration(days: 1)));
            } else if (selectedSecondary == 'This Month') {
              final now = DateTime.now();
              final thisMonth = DateFormat('yyyy-MM').format(now);
              final txnMonth = DateFormat('yyyy-MM').format(txn.date);
              matchesSecondary = txnMonth == thisMonth;
            } else if (selectedSecondary == 'Custom Range') {
              // This will be handled in the date range picker
              matchesSecondary = true;
            }
          }
        }

        // Smart search
        final matchesAmount = txn.amount.toStringAsFixed(2).contains(query);
        final matchesSearch = txn.category.toLowerCase().contains(query) ||
            txn.description.toLowerCase().contains(query) ||
            txn.type.toLowerCase().contains(query) ||
            matchesAmount;

        return matchesSecondary && matchesSearch;
      }).toList();
    });
  }

  Future<void> _selectDateRange() async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      initialDateRange: selectedStartDate != null && selectedEndDate != null
          ? DateTimeRange(start: selectedStartDate!, end: selectedEndDate!)
          : null,
      builder: (BuildContext context, Widget? child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: const ColorScheme.light(
              primary: primary,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        selectedStartDate = picked.start;
        selectedEndDate = picked.end;
        isDateRangeMode = true;
        _filterTransactions();
      });
    }
  }

  @override
  void dispose() {
    searchController.removeListener(_onSearchChanged);
    searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _openUpdateOverlay(TransactionModel txn) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      builder: (_) => UpdateTransactionOverlay(transaction: txn),
    );
  }

  List<String> _getSecondaryOptions() {
    if (selectedFilterType == 'Type') {
      return ['None', 'Income', 'Expense'];
    } else if (selectedFilterType == 'Wallet') {
      return ['None', ...wallets.map((w) => w.id)];
    } else if (selectedFilterType == 'Category') {
      return ['None', ...walletTypes, ...expenseCategories];
    } else if (selectedFilterType == 'Date') {
      return ['Today', 'This Week', 'This Month', 'Custom Range'];
    }
    return ['None'];
  }

  String _getSecondaryDisplayText(String id) {
    if (selectedFilterType == 'Wallet') {
      return wallets.firstWhere((w) => w.id == id, orElse: () => Wallet(id: '', name: 'None', value: 0.0, type: '')).name;
    }
    return id;
  }

  Map<String, List<TransactionModel>> _groupTransactionsByDate(List<TransactionModel> txns) {
    Map<String, List<TransactionModel>> grouped = {};
    for (var txn in txns) {
      final dateKey = DateFormat.yMMMMd().format(txn.date); // "April 26, 2025"
      if (!grouped.containsKey(dateKey)) {
        grouped[dateKey] = [];
      }
      grouped[dateKey]!.add(txn);
    }
    return grouped;
  }

  Widget _buildDateFilterInfo() {
    if (selectedFilterType != 'Date' || selectedSecondary == null) {
      return const SizedBox.shrink();
    }

    if (selectedSecondary == 'Custom Range' && isDateRangeMode && selectedStartDate != null && selectedEndDate != null) {
      final startFormatted = DateFormat('MMM d, yyyy').format(selectedStartDate!);
      final endFormatted = DateFormat('MMM d, yyyy').format(selectedEndDate!);

      return Container(
        margin: const EdgeInsets.only(top: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: primary.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            const Icon(Icons.date_range, size: 16, color: primary),
            const SizedBox(width: 8),
            Text(
              '$startFormatted to $endFormatted',
              style: const TextStyle(
                fontSize: 14,
                color: primary,
                fontWeight: FontWeight.w500,
              ),
            ),
            const Spacer(),
            IconButton(
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              icon: const Icon(Icons.close, size: 16, color: primary),
              onPressed: () {
                setState(() {
                  selectedStartDate = null;
                  selectedEndDate = null;
                  isDateRangeMode = false;
                  _filterTransactions();
                });
              },
            )
          ],
        ),
      );
    }

    return const SizedBox.shrink();
  }

  @override
  Widget build(BuildContext context) {
    final grouped = _groupTransactionsByDate(filteredTransactions);

    return SafeArea(
      child: Scaffold(
        backgroundColor: Colors.white,
        body: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: primary,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                  const Text(
                    'Search',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(width: 40),
                ],
              ),
              const SizedBox(height: 30),

              buildLabel('Filters'),
              Row(
                children: [
                  Expanded(
                    child: buildDropdown(
                      value: selectedFilterType,
                      items: ['None', 'Type', 'Wallet', 'Category', 'Date'],
                      hint: 'Filter by',
                      onChanged: (val) {
                        setState(() {
                          selectedFilterType = val == 'None' ? null : val;
                          selectedSecondary = null;
                          selectedStartDate = null;
                          selectedEndDate = null;
                          isDateRangeMode = false;
                          searchController.clear();
                          _filterTransactions();
                        });
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: (selectedFilterType != null && selectedFilterType != 'None')
                        ? buildDropdownGeneric<String>(
                      value: selectedSecondary,
                      items: _getSecondaryOptions(),
                      hint: 'Select',
                      onChanged: (val) {
                        setState(() {
                          selectedSecondary = val == 'None' ? null : val;

                          // Handle selecting custom date range
                          if (selectedFilterType == 'Date' && val == 'Custom Range') {
                            _selectDateRange();
                          } else {
                            isDateRangeMode = false;
                            selectedStartDate = null;
                            selectedEndDate = null;
                            _filterTransactions();
                          }
                        });
                      },
                      itemToString: (item) => _getSecondaryDisplayText(item),
                    )
                        : Container(),
                  ),
                ],
              ),

              // Display date range info if applicable
              _buildDateFilterInfo(),
              const SizedBox(height: 20),

              buildLabel('Search'),
              buildTextField(
                controller: searchController,
                hintText: 'Enter keyword',
              ),
              const SizedBox(height: 20),

              Expanded(
                child: grouped.isEmpty
                    ? const Center(child: Text('No transactions found', style: TextStyle(fontSize: 16)))
                    : AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: ListView(
                    key: ValueKey(filteredTransactions.length),
                    children: grouped.entries.map((entry) {
                      final date = entry.key;
                      final txns = entry.value;

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            margin: const EdgeInsets.symmetric(vertical: 10),
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: primary,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              date,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          ...txns.map((txn) => AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                            child: Card(
                              margin: const EdgeInsets.symmetric(vertical: 6),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: ListTile(
                                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                leading: getCategoryIconWidget(txn.category),
                                title: Text(
                                  txn.category,
                                  style: const TextStyle( fontSize: 16,
                                    //fontWeight: FontWeight.bold
                                  ),
                                ),
                                subtitle: Text(
                                  txn.description.isEmpty
                                      ? 'No description'
                                      : txn.description.length > 30
                                      ? '${txn.description.substring(0, 30)}...'
                                      : txn.description,
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey,
                                  ),
                                ),
                                trailing: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      txn.type == 'Expense'
                                          ? '-\$${txn.amount.toStringAsFixed(2)}'
                                          : '+\$${txn.amount.toStringAsFixed(2)}',
                                      style: TextStyle(
                                        color: txn.type == 'Expense' ? Colors.red : Colors.green,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ],
                                ),
                                onTap: () => _openUpdateOverlay(txn),
                              ),
                            ),
                          )),
                        ],
                      );
                    }).toList(),
                  ),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}