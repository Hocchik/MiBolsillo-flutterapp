import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class CurrencyService {
  static final CurrencyService _instance = CurrencyService._internal();
  factory CurrencyService() => _instance;
  CurrencyService._internal();

  static const _prefsKey = 'selected_currency';

  // default base is USD (stored values assumed in USD)
  String baseCurrency = 'USD';
  String selectedCurrency = 'USD';

  // supported currencies (5 most used + local PEN)
  final List<String> supported = ['USD', 'EUR', 'GBP', 'JPY', 'PEN'];

  // symbols
  final Map<String, String> symbols = {
    'USD': '\$',
    'EUR': '€',
    'GBP': '£',
    'JPY': '¥',
    'PEN': 'S/ ',
  };

  // rates relative to base (USD)
  Map<String, double> rates = {
    'USD': 1.0,
    'EUR': 0.92,
    'GBP': 0.79,
    'JPY': 155.0,
    'PEN': 3.5,
  };

  DateTime? lastUpdated;

  Future<void> init() async {
    final p = await SharedPreferences.getInstance();
    selectedCurrency = p.getString(_prefsKey) ?? 'USD';
    // try to update rates in background (non-blocking)
    try {
      await updateRates();
    } catch (_) {}
  }

  Future<void> updateRates() async {
    // try to fetch latest rates from exchangerate.host
    final url = Uri.parse('https://api.exchangerate.host/latest?base=USD&symbols=${supported.join(',')}');
    final resp = await http.get(url).timeout(const Duration(seconds: 6));
    if (resp.statusCode == 200) {
      final json = jsonDecode(resp.body) as Map<String, dynamic>;
      final fetched = (json['rates'] as Map).cast<String, dynamic>();
      for (final k in fetched.keys) {
        final v = (fetched[k] as num?)?.toDouble();
        if (v != null) rates[k] = v;
      }
      lastUpdated = DateTime.now();
    }
  }

  double convertFromBase(double amountUsd) {
    final rate = rates[selectedCurrency] ?? 1.0;
    return amountUsd * rate;
  }

  /// Convert an amount expressed in the currently selected currency back to
  /// the base currency (USD) used for storage.
  double convertToBase(double amountInSelected) {
    final rate = rates[selectedCurrency] ?? 1.0;
    if (rate == 0) return amountInSelected;
    return amountInSelected / rate;
  }

  String format(double? amountUsd) {
    if (amountUsd == null) return '---';
    final converted = convertFromBase(amountUsd);
    final symbol = symbols[selectedCurrency] ?? '';
    // show with 2 decimals
    return '$symbol${converted.toStringAsFixed(2)}';
  }

  Future<void> setSelected(String code) async {
    if (!supported.contains(code)) return;
    selectedCurrency = code;
    final p = await SharedPreferences.getInstance();
    await p.setString(_prefsKey, code);
  }
}
