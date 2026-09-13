import 'package:flutter/material.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/seraph_header.dart';

class TimezoneConverterPage extends StatefulWidget {
  const TimezoneConverterPage({super.key});

  @override
  State<TimezoneConverterPage> createState() => _TimezoneConverterPageState();
}

class _TimezoneConverterPageState extends State<TimezoneConverterPage> {
  static const _zones = {
    'WIB - Jakarta': 'Asia/Jakarta',
    'WITA - Makassar': 'Asia/Makassar',
    'WIT - Jayapura': 'Asia/Jayapura',
    'London': 'Europe/London',
    'New York': 'America/New_York',
    'Los Angeles': 'America/Los_Angeles',
    'Tokyo': 'Asia/Tokyo',
    'Seoul': 'Asia/Seoul',
    'Singapore': 'Asia/Singapore',
    'Dubai': 'Asia/Dubai',
    'Sydney': 'Australia/Sydney',
    'Paris': 'Europe/Paris',
    'UTC': 'UTC',
  };

  String _fromZone = 'WIB - Jakarta';
  DateTime _selectedDateTime = DateTime.now();
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    tzdata.initializeTimeZones();
    _initialized = true;
  }

  Future<void> _pickDateTime() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDateTime,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(context: context, initialTime: TimeOfDay.fromDateTime(_selectedDateTime));
    if (time == null) return;
    setState(() {
      _selectedDateTime = DateTime(date.year, date.month, date.day, time.hour, time.minute);
    });
  }

  String _formatDateTime(tz.TZDateTime dt) {
    final days = ['Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab', 'Min'];
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun', 'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'];
    final hh = dt.hour.toString().padLeft(2, '0');
    final mm = dt.minute.toString().padLeft(2, '0');
    return '${days[dt.weekday - 1]}, ${dt.day} ${months[dt.month - 1]} ${dt.year} • $hh:$mm';
  }

  @override
  Widget build(BuildContext context) {
    if (!_initialized) return const Center(child: CircularProgressIndicator(color: AppColors.cyan));

    final fromLocation = tz.getLocation(_zones[_fromZone]!);
    final fromTz = tz.TZDateTime(
      fromLocation,
      _selectedDateTime.year,
      _selectedDateTime.month,
      _selectedDateTime.day,
      _selectedDateTime.hour,
      _selectedDateTime.minute,
    );

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 22, 20, 40),
      children: [
        const SeraphHeader(title: 'Timezone', accent: 'Converter', subtitle: 'Bandingin jam di berbagai kota'),
        Row(
          children: [
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                decoration: BoxDecoration(color: AppColors.bg, border: Border.all(color: AppColors.line), borderRadius: BorderRadius.circular(8)),
                child: DropdownButton<String>(
                  value: _fromZone,
                  isExpanded: true,
                  underline: const SizedBox(),
                  dropdownColor: AppColors.panel,
                  style: const TextStyle(color: AppColors.ink, fontSize: 12.5),
                  items: _zones.keys.map((z) => DropdownMenuItem(value: z, child: Text(z))).toList(),
                  onChanged: (v) => setState(() => _fromZone = v!),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        OutlinedButton.icon(
          onPressed: _pickDateTime,
          icon: const Icon(Icons.calendar_today, size: 15, color: AppColors.cyan),
          label: Text(_formatDateTime(fromTz), style: const TextStyle(color: AppColors.ink, fontSize: 12)),
          style: OutlinedButton.styleFrom(side: const BorderSide(color: AppColors.line), padding: const EdgeInsets.symmetric(vertical: 14)),
        ),
        const SizedBox(height: 20),
        const Text('DI KOTA LAIN', style: TextStyle(color: AppColors.gray, fontSize: 10, letterSpacing: 1)),
        const SizedBox(height: 8),
        for (final entry in _zones.entries)
          if (entry.key != _fromZone) _zoneCard(entry.key, entry.value, fromTz),
      ],
    );
  }

  Widget _zoneCard(String label, String ianaName, tz.TZDateTime fromTz) {
    final targetLocation = tz.getLocation(ianaName);
    final targetTz = tz.TZDateTime.from(fromTz, targetLocation);
    final offsetHours = (targetTz.timeZoneOffset.inMinutes - fromTz.timeZoneOffset.inMinutes) / 60;
    final offsetLabel = offsetHours == 0 ? 'sama' : (offsetHours > 0 ? '+$offsetHours jam' : '$offsetHours jam');

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: AppColors.panel, border: Border.all(color: AppColors.line), borderRadius: BorderRadius.circular(10)),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(color: AppColors.ink, fontWeight: FontWeight.w600, fontSize: 12.5)),
                const SizedBox(height: 2),
                Text('selisih $offsetLabel', style: const TextStyle(color: AppColors.gray, fontSize: 10)),
              ],
            ),
          ),
          Text(_formatDateTime(targetTz), style: const TextStyle(color: AppColors.cyan, fontSize: 11.5, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
