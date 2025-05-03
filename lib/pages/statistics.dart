import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:madmet/models/transaction_model.dart';
import 'package:madmet/firestore_service.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:madmet/theme/color.dart';

import '../overlays/update_transaction.dart';
import '../utils/get_category_icons.dart';

class StatisticsPage extends StatefulWidget {
  const StatisticsPage({Key? key}) : super(key: key);

  @override
  State<StatisticsPage> createState() => _StatisticsPageState();
}

class _StatisticsPageState extends State<StatisticsPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final FirestoreService _firestoreService = FirestoreService();

  // For date selection
  DateTime _selectedWeekStart = DateTime.now().subtract(Duration(days: DateTime.now().weekday - 1));
  DateTime _selectedMonth = DateTime.now();
  int _selectedYear = DateTime.now().year;

  String get userId => FirebaseAuth.instance.currentUser?.uid ?? '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      setState(() {}); // Force rebuild when tab changes
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _previousPeriod() {
    setState(() {
      if (_tabController.index == 0) { // Weekly
        _selectedWeekStart = _selectedWeekStart.subtract(const Duration(days: 7));
      } else if (_tabController.index == 1) { // Monthly
        _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month - 1);
      } else { // Yearly
        _selectedYear--;
      }
    });
  }

  void _nextPeriod() {
    final now = DateTime.now();
    setState(() {
      if (_tabController.index == 0) { // Weekly
        DateTime nextWeekStart = _selectedWeekStart.add(const Duration(days: 7));
        if (!nextWeekStart.isAfter(now)) {
          _selectedWeekStart = nextWeekStart;
        }
      } else if (_tabController.index == 1) { // Monthly
        DateTime nextMonth = DateTime(_selectedMonth.year, _selectedMonth.month + 1);
        if (!nextMonth.isAfter(now)) {
          _selectedMonth = nextMonth;
        }
      } else { // Yearly
        if (_selectedYear < now.year) {
          _selectedYear++;
        }
      }
    });
  }

  void _resetToCurrentPeriod() {
    setState(() {
      final now = DateTime.now();
      if (_tabController.index == 0) { // Weekly
        _selectedWeekStart = DateTime(now.year, now.month, now.day).subtract(Duration(days: now.weekday - 1));
      } else if (_tabController.index == 1) { // Monthly
        _selectedMonth = DateTime(now.year, now.month);
      } else { // Yearly
        _selectedYear = now.year;
      }
    });
  }

  String _getPeriodLabel() {
    if (_tabController.index == 0) {
      final weekEnd = _selectedWeekStart.add(const Duration(days: 6));
      return '${DateFormat('MMM d').format(_selectedWeekStart)} - ${DateFormat('MMM d, y').format(weekEnd)}';
    } else if (_tabController.index == 1) {
      return DateFormat('MMMM y').format(_selectedMonth);
    } else {
      return _selectedYear.toString();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('Statistics', style: TextStyle(fontSize: 24)),
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Container(
            height: 50,
            margin: const EdgeInsets.symmetric(horizontal: 20.0),
            decoration: BoxDecoration(
              borderRadius: const BorderRadius.all(Radius.circular(10)),
              color: Colors.grey.shade200,
            ),
            child: TabBar(
              indicatorSize: TabBarIndicatorSize.tab,
              dividerColor: Colors.transparent,
              controller: _tabController,
              indicator: BoxDecoration(
                color: primary,
                borderRadius: BorderRadius.circular(10),
              ),
              labelColor: Colors.white,
              unselectedLabelColor: Colors.black,
              labelStyle: const TextStyle(fontSize: 16),
              tabs: const [
                Tab(text: 'Weekly'),
                Tab(text: 'Monthly'),
                Tab(text: 'Yearly'),
              ],
            ),
          ),
        ),
      ),

      body: StreamBuilder<List<TransactionModel>>(
        stream: _firestoreService.streamTransactions(userId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No transactions'));
          }

          final transactions = snapshot.data!;
          final selectedPeriod = _tabController.index == 0 ? 'week'
              : _tabController.index == 1 ? 'month'
              : 'year';

          final aggregatedData = _aggregateData(selectedPeriod, transactions);
          final filteredTxns = _filteredTransactions(selectedPeriod, transactions);

          return RefreshIndicator(
            onRefresh: () async {}, // Stream auto-updates; no need to fetch manually
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  // Period selector
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.chevron_left),
                          onPressed: _previousPeriod,
                        ),
                        GestureDetector(
                          onTap: _resetToCurrentPeriod,
                          child: Text(
                            _getPeriodLabel(),
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.chevron_right),
                          onPressed: _nextPeriod,
                        ),
                      ],
                    ),
                  ),

                  // Chart
                  Container(
                    height: 280,
                    padding: const EdgeInsets.only(top: 16),
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: SizedBox(
                        width: aggregatedData.length * 60,
                        child: BarChart(
                          BarChartData(
                            maxY: _roundMaxY(_calculateMaxY(aggregatedData)),
                            barTouchData: BarTouchData(
                              enabled: true,
                              touchTooltipData: BarTouchTooltipData(
                                getTooltipItem: (group, groupIndex, rod, rodIndex) {
                                  String type = rodIndex == 0 ? 'Income' : 'Expense';
                                  String value = '\$${rod.toY.toStringAsFixed(2)}';
                                  String label = aggregatedData[group.x.toInt()]['label'] as String? ?? '';
                                  return BarTooltipItem(
                                    '$label - $type\n$value',
                                    const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                  );
                                },
                              ),
                            ),
                            barGroups: aggregatedData.asMap().entries.map((entry) {
                              int i = entry.key;
                              var item = entry.value;
                              return BarChartGroupData(
                                x: i,
                                barRods: [
                                  BarChartRodData(
                                    toY: (item['income'] as double?) ?? 0.0,
                                    color: Colors.green,
                                    width: 8,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  BarChartRodData(
                                    toY: (item['expense'] as double?) ?? 0.0,
                                    color: Colors.red,
                                    width: 8,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                ],
                                barsSpace: 4,
                              );
                            }).toList(),
                            titlesData: FlTitlesData(
                              leftTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  interval: _calculateInterval(_calculateMaxY(aggregatedData)),
                                  reservedSize: 50,
                                  getTitlesWidget: (value, meta) {
                                    if (value >= 1000) {
                                      return Padding(
                                        padding: const EdgeInsets.only(right: 8.0),
                                        child: Text('\$${(value/1000).toStringAsFixed(1)}k'),
                                      );
                                    } else {
                                      return Padding(
                                          padding: const EdgeInsets.only(right: 8.0),
                                          child: Text('\$${value.toInt()}')
                                      );
                                    }
                                  },
                                ),
                              ),
                              bottomTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  getTitlesWidget: (value, meta) {
                                    int i = value.toInt();
                                    if (i >= 0 && i < aggregatedData.length) {
                                      return Text(
                                        (aggregatedData[i]['label'] as String? ?? ''),
                                        style: const TextStyle(fontSize: 10),
                                      );
                                    }
                                    return const Text('');
                                  },
                                ),
                              ),
                              topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                              rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                            ),
                            gridData: FlGridData(show: false),
                            minY: 0,
                            borderData: FlBorderData(show: true, border: Border.all(color: Colors.transparent, width: 8)),
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Transactions Label
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
                    child: Row(
                      children: const [
                        Text(
                          'Transactions',
                          style: TextStyle(fontSize: 20),
                        ),
                      ],
                    ),
                  ),

                  // Transactions List
                  Expanded(
                    child: ListView.builder(
                      itemCount: filteredTxns.length,
                      itemBuilder: (context, index) {
                        final txn = filteredTxns[index];
                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                          child: Card(
                            margin: const EdgeInsets.symmetric(vertical: 6),
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              leading: getCategoryIconWidget(txn.category),
                              title: Text(txn.category),
                              onTap: () => _showUpdateTransactionOverlay(context, txn),
                              subtitle: Text(
                                txn.description.isEmpty
                                    ? 'No description'
                                    : txn.description.length > 20
                                    ? '${txn.description.substring(0, 20)}...'
                                    : txn.description,
                                style: const TextStyle(fontSize: 14, color: Colors.grey),
                              ),
                              trailing: Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    txn.type == 'Expense'
                                        ? '-\$${txn.amount.toStringAsFixed(2)}'
                                        : '+\$${txn.amount.toStringAsFixed(2)}',
                                    style: TextStyle(
                                      color: txn.type == 'Expense' ? Colors.red : Colors.green,
                                      fontSize: 16,
                                    ),
                                  ),
                                  Text(
                                    DateFormat.yMMMd().format(txn.date),
                                    style: const TextStyle(fontSize: 14, color: Colors.grey),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _showUpdateTransactionOverlay(BuildContext context, TransactionModel txn) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      builder: (BuildContext context) {
        return UpdateTransactionOverlay(transaction: txn);
      },
    );
  }

  // Modified helper methods
  List<Map<String, Object>> _aggregateData(String period, List<TransactionModel> transactions) {
    Map<String, Map<String, double>> grouped = {};

    if (period == 'week') {
      const weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
      grouped = { for (var day in weekdays) day: {'income': 0.0, 'expense': 0.0} };
    } else if (period == 'month') {
      int daysInMonth = DateTime(_selectedMonth.year, _selectedMonth.month + 1, 0).day;
      grouped = { for (var day = 1; day <= daysInMonth; day++) '$day': {'income': 0.0, 'expense': 0.0} };
    } else if (period == 'year') {
      const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
      grouped = { for (var month in months) month: {'income': 0.0, 'expense': 0.0} };
    }

    for (var txn in transactions) {
      bool include = false;
      String key = '';

      if (period == 'week') {
        // Get the week's end date
        final weekEndDate = _selectedWeekStart.add(const Duration(days: 6));
        // Include transactions within the selected week
        include = !txn.date.isBefore(_selectedWeekStart) && !txn.date.isAfter(weekEndDate);
        key = DateFormat('E').format(txn.date);
      } else if (period == 'month') {
        include = txn.date.month == _selectedMonth.month && txn.date.year == _selectedMonth.year;
        key = txn.date.day.toString();
      } else if (period == 'year') {
        include = txn.date.year == _selectedYear;
        key = DateFormat('MMM').format(txn.date);
      }

      if (include) {
        if (!grouped.containsKey(key)) {
          grouped[key] = {'income': 0.0, 'expense': 0.0};
        }
        if (txn.type.toLowerCase() == 'income') {
          grouped[key]!['income'] = grouped[key]!['income']! + txn.amount;
        } else {
          grouped[key]!['expense'] = grouped[key]!['expense']! + txn.amount;
        }
      }
    }

    final sortedKeys = grouped.keys.toList()..sort((a, b) => _sortLabels(a, b, period));

    return sortedKeys.map((k) => {
      'label': k,
      'income': grouped[k]!['income'] ?? 0.0,
      'expense': grouped[k]!['expense'] ?? 0.0,
    }).toList();
  }

  List<TransactionModel> _filteredTransactions(String period, List<TransactionModel> transactions) {
    return transactions.where((txn) {
      if (period == 'week') {
        final weekEndDate = _selectedWeekStart.add(const Duration(days: 6));
        return !txn.date.isBefore(_selectedWeekStart) && !txn.date.isAfter(weekEndDate);
      } else if (period == 'month') {
        return txn.date.month == _selectedMonth.month && txn.date.year == _selectedMonth.year;
      } else if (period == 'year') {
        return txn.date.year == _selectedYear;
      }
      return false;
    }).toList();
  }

  double _calculateInterval(double maxY) => _roundMaxY(maxY) / 5;

  double _roundMaxY(double maxY) {
    if (maxY <= 10) return 10;
    double magnitude = 1;
    while (maxY / magnitude >= 10) {
      magnitude *= 10;
    }
    double normalized = maxY / magnitude;
    double roundedNormalized;
    if (normalized <= 1.5) roundedNormalized = 1.5;
    else if (normalized <= 2) roundedNormalized = 2;
    else if (normalized <= 2.5) roundedNormalized = 2.5;
    else if (normalized <= 3) roundedNormalized = 3;
    else if (normalized <= 4) roundedNormalized = 4;
    else if (normalized <= 5) roundedNormalized = 5;
    else if (normalized <= 6) roundedNormalized = 6;
    else if (normalized <= 8) roundedNormalized = 8;
    else roundedNormalized = 10;

    return roundedNormalized * magnitude;
  }

  double _calculateMaxY(List<Map<String, Object>> data) {
    double max = 0;
    for (final item in data) {
      final income = (item['income'] as double?) ?? 0.0;
      final expense = (item['expense'] as double?) ?? 0.0;
      final localMax = income > expense ? income : expense;
      if (localMax > max) max = localMax;
    }
    return max == 0 ? 100 : max + 20;
  }

  int _sortLabels(String a, String b, String period) {
    if (period == 'week') {
      const weekdayOrder = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
      return weekdayOrder.indexOf(a).compareTo(weekdayOrder.indexOf(b));
    } else if (period == 'year') {
      const monthOrder = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
      return monthOrder.indexOf(a).compareTo(monthOrder.indexOf(b));
    } else {
      return int.parse(a).compareTo(int.parse(b));
    }
  }
}