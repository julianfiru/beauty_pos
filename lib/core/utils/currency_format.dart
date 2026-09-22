import 'package:intl/intl.dart';

class CurrencyFormat {
  static String toIdr(dynamic number, {int decimalDigit = 0}) {
    NumberFormat currencyFormatter = NumberFormat.currency(
      locale: 'id',
      symbol: 'Rp ',
      decimalDigits: decimalDigit,
    );
    return currencyFormatter.format(number);
  }

  static String toCompactIdr(dynamic number) {
    if (number == null) return '0';
    double val = (number is num) ? number.toDouble() : (double.tryParse(number.toString()) ?? 0.0);
    if (val == 0) return '0';
    if (val.abs() >= 1000000000000) {
      double t = val / 1000000000000;
      return '${t.toStringAsFixed(t.truncateToDouble() == t ? 0 : 1)} T';
    } else if (val.abs() >= 1000000000) {
      double m = val / 1000000000;
      return '${m.toStringAsFixed(m.truncateToDouble() == m ? 0 : 1)} M';
    } else if (val.abs() >= 1000000) {
      double jt = val / 1000000;
      return '${jt.toStringAsFixed(jt.truncateToDouble() == jt ? 0 : 1)} Jt';
    } else if (val.abs() >= 1000) {
      double rb = val / 1000;
      return '${rb.toStringAsFixed(rb.truncateToDouble() == rb ? 0 : 1)} Rb';
    }
    return val.toStringAsFixed(0);
  }
}
