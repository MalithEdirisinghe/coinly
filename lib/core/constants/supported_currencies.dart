class SupportedCurrency {
  const SupportedCurrency({required this.code, required this.label});

  final String code;
  final String label;
}

abstract final class SupportedCurrencies {
  static const usd = SupportedCurrency(code: 'USD', label: 'US Dollar');
  static const eur = SupportedCurrency(code: 'EUR', label: 'Euro');
  static const gbp = SupportedCurrency(code: 'GBP', label: 'British Pound');
  static const lkr = SupportedCurrency(code: 'LKR', label: 'Sri Lankan Rupee');
  static const inr = SupportedCurrency(code: 'INR', label: 'Indian Rupee');
  static const aud = SupportedCurrency(code: 'AUD', label: 'Australian Dollar');
  static const cad = SupportedCurrency(code: 'CAD', label: 'Canadian Dollar');
  static const sgd = SupportedCurrency(code: 'SGD', label: 'Singapore Dollar');

  static const values = [usd, eur, gbp, lkr, inr, aud, cad, sgd];
}
