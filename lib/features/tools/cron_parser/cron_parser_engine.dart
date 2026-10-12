class CronParseException implements Exception {
  final String message;
  CronParseException(this.message);
  @override
  String toString() => message;
}

/// Parser cron expression standar 5 field: menit jam tanggal bulan hari.
/// Support: wildcard (*), angka spesifik, range (1-5), step (*/5), list (1,3,5).
class CronParserEngine {
  static const _dayNames = ['Minggu', 'Senin', 'Selasa', 'Rabu', 'Kamis', "Jum'at", 'Sabtu'];
  static const _monthNames = [
    'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
    'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'
  ];

  static String describe(String expression) {
    final parts = expression.trim().split(RegExp(r'\s+'));
    if (parts.length != 5) {
      throw CronParseException('Cron harus 5 field: menit jam tanggal bulan hari. Contoh: 0 8 * * 1-5');
    }
    final minute = parts[0];
    final hour = parts[1];
    final dayOfMonth = parts[2];
    final month = parts[3];
    final dayOfWeek = parts[4];

    final timePart = _describeTime(minute, hour);
    final datePart = _describeDate(dayOfMonth, month, dayOfWeek);

    return datePart.isEmpty ? timePart : '$timePart, $datePart';
  }

  static String _describeTime(String minute, String hour) {
    if (minute == '*' && hour == '*') return 'Tiap menit';
    if (minute.startsWith('*/') && hour == '*') {
      return 'Tiap ${minute.substring(2)} menit';
    }
    if (hour == '*') {
      return 'Tiap jam di menit ke-$minute';
    }
    if (minute == '*') {
      return 'Tiap menit di jam ${_describeField(hour, isHour: true)}';
    }
    final hh = hour.padLeft(2, '0');
    final mm = minute.padLeft(2, '0');
    if (RegExp(r'^\d+$').hasMatch(hour) && RegExp(r'^\d+$').hasMatch(minute)) {
      return 'Jam $hh:$mm';
    }
    return 'Jam ${_describeField(hour, isHour: true)}, menit ke-${_describeField(minute)}';
  }

  static String _describeDate(String dayOfMonth, String month, String dayOfWeek) {
    final parts = <String>[];

    if (dayOfMonth != '*') {
      parts.add('tanggal ${_describeField(dayOfMonth)}');
    }
    if (month != '*') {
      parts.add('bulan ${_describeMonthField(month)}');
    }
    if (dayOfWeek != '*') {
      parts.add('hari ${_describeDayOfWeekField(dayOfWeek)}');
    }

    if (parts.isEmpty) return 'setiap hari';
    return parts.join(', ');
  }

  static String _describeField(String field, {bool isHour = false}) {
    if (field.contains(',')) {
      return field.split(',').join(', ');
    }
    if (field.contains('-')) {
      final range = field.split('-');
      return '${range[0]} sampai ${range[1]}';
    }
    if (field.startsWith('*/')) {
      return 'kelipatan ${field.substring(2)}';
    }
    return field;
  }

  static String _describeMonthField(String field) {
    if (RegExp(r'^\d+$').hasMatch(field)) {
      final idx = int.parse(field) - 1;
      if (idx >= 0 && idx < 12) return _monthNames[idx];
    }
    if (field.contains(',')) {
      return field.split(',').map((f) => _describeMonthField(f)).join(', ');
    }
    if (field.contains('-')) {
      final r = field.split('-');
      return '${_describeMonthField(r[0])} sampai ${_describeMonthField(r[1])}';
    }
    return field;
  }

  static String _describeDayOfWeekField(String field) {
    if (RegExp(r'^\d+$').hasMatch(field)) {
      final idx = int.parse(field) % 7;
      return _dayNames[idx];
    }
    if (field.contains(',')) {
      return field.split(',').map((f) => _describeDayOfWeekField(f)).join(', ');
    }
    if (field.contains('-')) {
      final r = field.split('-');
      return '${_describeDayOfWeekField(r[0])} sampai ${_describeDayOfWeekField(r[1])}';
    }
    return field;
  }
}
