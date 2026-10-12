import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;
import '../../../core/storage/local_json_list_store.dart';
import 'checklist_models.dart';

/// Reset checklist yang aktif itu jalan dengan 2 lapis, biar tetep akurat
/// walau app lagi gak dibuka pas jam 12 malam:
///
/// 1. LAZY RESET (akurat, jadi sumber kebenaran): tiap kali halaman
///    Checklist dibuka, dicek apakah tanggal hari ini udah lewat dari
///    `lastResetDate` tiap grup aktif. Kalau iya, item-nya di-reset
///    SAAT ITU JUGA (bukan nunggu 24 jam dari kapan terakhir dicentang -
///    ini perbandingan TANGGAL KALENDER, jadi selalu pas jam 12 malam
///    kalender, bukan jam 12 malam dari waktu checklist terakhir disentuh).
/// 2. NOTIFIKASI TERJADWAL (best-effort, biar user dikasih tau walau
///    app ditutup): dijadwalin notifikasi berulang tiap jam 00:00 waktu
///    lokal device lewat flutter_local_notifications.
class ChecklistService {
  static const _store = LocalJsonListStore('checklist_groups.json');
  static final _notif = FlutterLocalNotificationsPlugin();
  static bool _notifInit = false;
  static bool _tzInit = false;

  static Future<List<ChecklistGroup>> load() async {
    final raw = await _store.load();
    return raw.map(ChecklistGroup.fromJson).toList();
  }

  static Future<void> save(List<ChecklistGroup> groups) =>
      _store.save(groups.map((g) => g.toJson()).toList());

  static String _todayKey() {
    final d = DateTime.now();
    return '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
  }

  /// Cek semua grup aktif, reset yang udah lewat tengah malam, dan kasih
  /// tau nama grup mana aja yang di-reset (buat ditampilin/dinotifikasiin).
  static Future<List<String>> resetIfNeeded(List<ChecklistGroup> groups) async {
    final today = _todayKey();
    final resetNames = <String>[];

    for (final group in groups) {
      if (!group.active) continue;
      if (group.lastResetDate == today) continue; // udah di-reset hari ini

      final isFirstTime = group.lastResetDate == null;
      for (final item in group.items) {
        item.done = false;
      }
      group.lastResetDate = today;
      if (!isFirstTime) resetNames.add(group.name); // gak usah notif pas pertama kali diaktifin
    }

    if (resetNames.isNotEmpty) {
      await save(groups);
      await _notifyReset(resetNames);
    }

    return resetNames;
  }

  static Future<void> _initNotif() async {
    if (_notifInit) return;
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    await _notif.initialize(const InitializationSettings(android: androidInit));
    await _notif
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
    _notifInit = true;
  }

  static Future<void> _notifyReset(List<String> groupNames) async {
    await _initNotif();
    const details = AndroidNotificationDetails(
      'checklist_reset_channel',
      'Checklist Reset',
      channelDescription: 'Notifikasi pas checklist aktif direset buat hari baru',
      importance: Importance.max,
      priority: Priority.high,
    );
    await _notif.show(
      2001,
      'Checklist direset untuk hari ini',
      groupNames.length == 1
          ? '"${groupNames.first}" udah direset, yuk mulai lagi dari awal.'
          : '${groupNames.join(', ')} udah direset, yuk mulai lagi dari awal.',
      const NotificationDetails(android: details),
    );
  }

  /// Dijadwalin SEKALI pas halaman Checklist pertama kali dibuka - bakal
  /// notif tiap jam 00:00 waktu lokal, walau app lagi ditutup (best-effort,
  /// beberapa HP yang agresif soal battery saver bisa nunda ini).
  static Future<void> scheduleMidnightReminder() async {
    await _initNotif();
    if (!_tzInit) {
      tzdata.initializeTimeZones();
      // Timezone package butuh lokasi eksplisit, device gak selalu kasih
      // nama IANA zone - jadi dicocokin dari UTC offset device sekarang
      // (akurat buat zona WIB/WITA/WIT yang semuanya offset genap per jam).
      final offsetHours = DateTime.now().timeZoneOffset.inHours;
      final etcName = offsetHours == 0 ? 'UTC' : 'Etc/GMT${offsetHours > 0 ? '-' : '+'}${offsetHours.abs()}';
      try {
        tz.setLocalLocation(tz.getLocation(etcName));
      } catch (_) {
        tz.setLocalLocation(tz.UTC); // fallback aman kalau zona gak ketemu
      }
      _tzInit = true;
    }

    final now = tz.TZDateTime.now(tz.local);
    var midnight = tz.TZDateTime(tz.local, now.year, now.month, now.day, 0, 0);
    if (midnight.isBefore(now)) {
      midnight = midnight.add(const Duration(days: 1));
    }

    const details = AndroidNotificationDetails(
      'checklist_reset_channel',
      'Checklist Reset',
      channelDescription: 'Notifikasi pas checklist aktif direset buat hari baru',
      importance: Importance.max,
      priority: Priority.high,
    );

    await _notif.zonedSchedule(
      2002,
      'Checklist harian direset',
      'Checklist aktif kamu udah direset buat hari ini. Buka app buat liat.',
      midnight,
      const NotificationDetails(android: details),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }
}
