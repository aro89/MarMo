import 'package:flutter/material.dart';

/// Returns an appropriate icon based on transaction category
IconData getCategoryIcon(String category) {
  final String lowerCategory = category.toLowerCase();

  // Match expense categories
  switch (lowerCategory) {
    case 'food & dining':
    case 'food and dining':
      return Icons.restaurant;
    case 'groceries':
      return Icons.shopping_cart;
    case 'transportation':
      return Icons.directions_car;
    case 'utilities':
      return Icons.power;
    case 'rent':
      return Icons.home;
    case 'shopping':
      return Icons.shopping_bag;
    case 'healthcare':
      return Icons.medical_services;
    case 'entertainment':
      return Icons.movie;
    case 'education':
      return Icons.school;
    case 'travel':
      return Icons.flight;
    case 'insurance':
      return Icons.policy;
    case 'other':
      return Icons.more_horiz;
    default:
    // Check for wallet types if it's not an expense category
      return getWalletIcon(category);
  }
}

/// Returns an appropriate icon based on wallet type
IconData getWalletIcon(String walletType) {
  final String lowerWallet = walletType.toLowerCase();

  switch (lowerWallet) {
    case 'cash':
      return Icons.money;
    case 'crypto':
      return Icons.currency_bitcoin;
    case 'bank':
      return Icons.account_balance;
    case 'credit card':
      return Icons.credit_card;
    case 'debit card':
      return Icons.credit_card;
    case 'mobile payment':
      return Icons.phone_android;
    case 'savings':
      return Icons.savings;
    case 'investment':
      return Icons.trending_up;
    case 'online & digital':
    case 'online and digital':
      return Icons.language;
    case 'other':
      return Icons.account_balance_wallet;
  // Fallback for any other category
    default:
      if (lowerWallet.contains('food') || lowerWallet.contains('dining')) {
        return Icons.restaurant;
      } else if (lowerWallet.contains('groceries')) {
        return Icons.shopping_cart;
      } else if (lowerWallet.contains('transport') || lowerWallet.contains('travel')) {
        return Icons.directions_car;
      } else if (lowerWallet.contains('utilities') || lowerWallet.contains('bills')) {
        return Icons.receipt;
      } else if (lowerWallet.contains('rent') || lowerWallet.contains('housing')) {
        return Icons.home;
      } else if (lowerWallet.contains('shopping')) {
        return Icons.shopping_bag;
      } else if (lowerWallet.contains('health') || lowerWallet.contains('medical')) {
        return Icons.medical_services;
      } else if (lowerWallet.contains('entertainment')) {
        return Icons.movie;
      } else if (lowerWallet.contains('education')) {
        return Icons.school;
      } else if (lowerWallet.contains('income') || lowerWallet.contains('salary')) {
        return Icons.work;
      }
      return Icons.more_horiz;
  }
}

/// Helper method to get a colored CircleAvatar with category icon
Widget getCategoryIconWidget(String category, {bool isWallet = false, double size = 40.0}) {
  final IconData icon = isWallet ? getWalletIcon(category) : getCategoryIcon(category);
  final Color iconColor = getCategoryColor(category);

  return CircleAvatar(
    radius: size / 2,
    backgroundColor: iconColor.withOpacity(0.2),
    child: Icon(
      icon,
      color: iconColor,
      size: size * 0.6,
    ),
  );
}

/// Returns a color associated with the given category
Color getCategoryColor(String category) {
  final String lowerCategory = category.toLowerCase();

  // Define a rich color palette for categories
  if (lowerCategory.contains('food & dining') || lowerCategory.contains('food and dining')) {
    return Colors.orange.shade700; // Deeper orange
  } else if (lowerCategory.contains('groceries')) {
    return Colors.lightGreen.shade600; // Fresh green
  } else if (lowerCategory.contains('transportation')) {
    return Colors.blueAccent.shade700; // Deep blue
  } else if (lowerCategory.contains('utilities')) {
    return Colors.amber.shade800; // Amber
  } else if (lowerCategory.contains('rent')) {
    return Colors.brown.shade600; // Brown
  } else if (lowerCategory.contains('shopping')) {
    return Colors.pinkAccent.shade400; // Bright pink
  } else if (lowerCategory.contains('healthcare')) {
    return Colors.red.shade600; // Medical red
  } else if (lowerCategory.contains('entertainment')) {
    return Colors.deepPurple.shade400; // Purple
  } else if (lowerCategory.contains('education')) {
    return Colors.indigo.shade500; // Indigo
  } else if (lowerCategory.contains('travel')) {
    return Colors.teal.shade600; // Teal
  } else if (lowerCategory.contains('insurance')) {
    return Colors.blueGrey.shade600; // Blue-grey
  }

  // Wallet types
  else if (lowerCategory.contains('cash')) {
    return Colors.green.shade700; // Cash green
  } else if (lowerCategory.contains('crypto')) {
    return Color(0xFFF7931A); // Bitcoin orange
  } else if (lowerCategory.contains('bank')) {
    return Colors.blue.shade800; // Bank blue
  } else if (lowerCategory.contains('credit card') || lowerCategory.contains('debit card')) {
    return Colors.deepOrange.shade700; // Card orange
  } else if (lowerCategory.contains('mobile payment')) {
    return Colors.purple.shade600; // Mobile purple
  } else if (lowerCategory.contains('savings')) {
    return Colors.cyan.shade700; // Savings cyan
  } else if (lowerCategory.contains('investment')) {
    return Color(0xFF2E7D32); // Investment green
  } else if (lowerCategory.contains('online') || lowerCategory.contains('digital')) {
    return Colors.lightBlue.shade600; // Digital blue
  }

  // For income categories
  else if (lowerCategory.contains('income') || lowerCategory.contains('salary')) {
    return Colors.green.shade600; // Income green
  } else if (lowerCategory.contains('gift')) {
    return Colors.pink.shade400; // Gift pink
  } else if (lowerCategory.contains('refund')) {
    return Colors.amber.shade600; // Refund amber
  }

  // Default
  return Colors.grey.shade700; // Default grey
}