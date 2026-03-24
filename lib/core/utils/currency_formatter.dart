import 'package:intl/intl.dart';

class CurrencyFormatter {
  const CurrencyFormatter._();

  static String format(double amount, {String currencyCode = 'USD'}) {
    try {
      return NumberFormat.simpleCurrency(name: currencyCode).format(amount);
    } on Exception {
      return '$currencyCode ${amount.toStringAsFixed(2)}';
    }
  }
}
