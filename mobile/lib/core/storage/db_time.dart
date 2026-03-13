class DbTime {
  static String format(DateTime value) => value.toUtc().toIso8601String();

  static DateTime? parse(String? value) {
    if (value == null || value.isEmpty) {
      return null;
    }
    return DateTime.parse(value).toUtc();
  }
}
