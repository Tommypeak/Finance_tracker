import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum DateFormatType { ddMMyyyy, yyyyMMdd }

class SettingsState extends ChangeNotifier {
  static const _kThemeMode = 'themeMode'; // 0 system, 1 light, 2 dark
  static const _kCurrency = 'currency';   // "₸", "$", etc
  static const _kDateFmt = 'dateFormat';  // "ddMMyyyy" | "yyyyMMdd"

  ThemeMode _themeMode = ThemeMode.light;
  String _currencySymbol = '₸';
  DateFormatType _dateFormat = DateFormatType.ddMMyyyy;

  ThemeMode get themeMode => _themeMode;
  String get currencySymbol => _currencySymbol;
  DateFormatType get dateFormat => _dateFormat;

  String get dateFormatPattern =>
      _dateFormat == DateFormatType.ddMMyyyy
          ? 'dd.MM.yyyy'
          : 'yyyy-MM-dd';

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();

    final tm = prefs.getInt(_kThemeMode);
    if (tm != null) {
      _themeMode =
          ThemeMode.values[tm.clamp(0, ThemeMode.values.length - 1)];
    }

    _currencySymbol = prefs.getString(_kCurrency) ?? '₸';

    final df = prefs.getString(_kDateFmt);
    if (df == 'yyyyMMdd') _dateFormat = DateFormatType.yyyyMMdd;
    if (df == 'ddMMyyyy') _dateFormat = DateFormatType.ddMMyyyy;

    notifyListeners();
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_kThemeMode, ThemeMode.values.indexOf(mode));
  }

  Future<void> setCurrencySymbol(String symbol) async {
    _currencySymbol = symbol;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kCurrency, symbol);
  }

  Future<void> setDateFormat(DateFormatType fmt) async {
    _dateFormat = fmt;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _kDateFmt,
      fmt == DateFormatType.yyyyMMdd ? 'yyyyMMdd' : 'ddMMyyyy',
    );
  }
}
