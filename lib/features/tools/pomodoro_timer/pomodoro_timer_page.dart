import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/seraph_header.dart';

enum _Phase { work, shortBreak, longBreak }

class PomodoroTimerPage extends StatefulWidget {
  const PomodoroTimerPage({super.key});

  @override
  State<PomodoroTimerPage> createState() => _PomodoroTimerPageState();
}

class _PomodoroTimerPageState extends State<PomodoroTimerPage> {
  static const _workMinutes = 25;
  static const _shortBreakMinutes = 5;
  static const _longBreakMinutes = 15;

  _Phase _phase = _Phase.work;
  int _remainingSeconds = _workMinutes * 60;
  bool _running = false;
  int _completedSessions = 0;
  Timer? _timer;

  final _notif = FlutterLocalNotificationsPlugin();
  bool _notifInit = false;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _initNotif() async {
    if (_notifInit) return;
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    await _notif.initialize(const InitializationSettings(android: androidInit));
    await _notif
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
    _notifInit = true;
  }

  Future<void> _notify(String title, String body) async {
    await _initNotif();
    const details = AndroidNotificationDetails('pomodoro_channel', 'Pomodoro Timer',
        channelDescription: 'Notifikasi selesai sesi Pomodoro', importance: Importance.max, priority: Priority.high);
    await _notif.show(1, title, body, const NotificationDetails(android: details));
  }

  void _start() {
    setState(() => _running = true);
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingSeconds <= 1) {
        _onPhaseComplete();
      } else {
        setState(() => _remainingSeconds--);
      }
    });
  }

  void _pause() {
    _timer?.cancel();
    setState(() => _running = false);
  }

  void _reset() {
    _timer?.cancel();
    setState(() {
      _running = false;
      _remainingSeconds = _durationFor(_phase) * 60;
    });
  }

  int _durationFor(_Phase phase) {
    switch (phase) {
      case _Phase.work:
        return _workMinutes;
      case _Phase.shortBreak:
        return _shortBreakMinutes;
      case _Phase.longBreak:
        return _longBreakMinutes;
    }
  }

  void _onPhaseComplete() {
    _timer?.cancel();
    if (_phase == _Phase.work) {
      _completedSessions++;
      final isLongBreak = _completedSessions % 4 == 0;
      _notify('Waktunya istirahat!', isLongBreak ? 'Istirahat panjang 15 menit.' : 'Istirahat sebentar 5 menit.');
      setState(() {
        _phase = isLongBreak ? _Phase.longBreak : _Phase.shortBreak;
        _remainingSeconds = _durationFor(_phase) * 60;
        _running = false;
      });
    } else {
      _notify('Waktunya fokus!', 'Sesi kerja 25 menit dimulai lagi.');
      setState(() {
        _phase = _Phase.work;
        _remainingSeconds = _durationFor(_phase) * 60;
        _running = false;
      });
    }
  }

  String get _phaseLabel {
    switch (_phase) {
      case _Phase.work:
        return 'FOKUS';
      case _Phase.shortBreak:
        return 'ISTIRAHAT SEBENTAR';
      case _Phase.longBreak:
        return 'ISTIRAHAT PANJANG';
    }
  }

  Color get _phaseColor => _phase == _Phase.work ? AppColors.cyan : Colors.orangeAccent;

  @override
  Widget build(BuildContext context) {
    final minutes = (_remainingSeconds ~/ 60).toString().padLeft(2, '0');
    final seconds = (_remainingSeconds % 60).toString().padLeft(2, '0');

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 22, 20, 40),
      children: [
        const SeraphHeader(title: 'Pomodoro', accent: 'Timer', subtitle: 'Timer fokus kerja & istirahat'),
        Text(_phaseLabel,
            textAlign: TextAlign.center,
            style: TextStyle(color: _phaseColor, fontWeight: FontWeight.w800, fontSize: 12, letterSpacing: 2)),
        const SizedBox(height: 20),
        Center(
          child: Container(
            width: 220,
            height: 220,
            decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: _phaseColor, width: 3)),
            alignment: Alignment.center,
            child: Text('$minutes:$seconds',
                style: const TextStyle(color: AppColors.ink, fontSize: 44, fontWeight: FontWeight.w800)),
          ),
        ),
        const SizedBox(height: 28),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton(
              iconSize: 42,
              icon: Icon(_running ? Icons.pause_circle : Icons.play_circle, color: AppColors.cyan),
              onPressed: _running ? _pause : _start,
            ),
            const SizedBox(width: 20),
            IconButton(iconSize: 36, icon: const Icon(Icons.restart_alt, color: AppColors.gray), onPressed: _reset),
          ],
        ),
        const SizedBox(height: 20),
        Center(
          child: Text('$_completedSessions sesi kerja selesai hari ini',
              style: const TextStyle(color: AppColors.gray, fontSize: 11.5)),
        ),
      ],
    );
  }
}
