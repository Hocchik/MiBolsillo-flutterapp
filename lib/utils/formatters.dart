import '../services/currency_service.dart';

String fmtMoneyOrPlaceholder(double? value) {
  if (value == null) return '---';
  try {
    return CurrencyService().format(value);
  } catch (_) {
    return '\$${value.toStringAsFixed(2)}';
  }
}

String fmtPercentOrPlaceholder(double? pct) {
  if (pct == null) return '---';
  return '${(pct * 100).round()}%';
}

String fmtCountOrPlaceholder(int? count) {
  if (count == null) return '---';
  return count.toString();
}

String fmtDateOrPlaceholder(String? iso) {
  if (iso == null || iso.isEmpty) return '---';
  try {
    final d = DateTime.parse(iso);
    return '${d.day}/${d.month}/${d.year}';
  } catch (_) {
    return '---';
  }
}
