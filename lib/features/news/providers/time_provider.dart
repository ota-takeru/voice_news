import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:async';

import 'package:intl/intl.dart';

final timeProvider = StateNotifierProvider<TimeNotifier, DateTime>((ref) {
  return TimeNotifier();
});

class TimeNotifier extends StateNotifier<DateTime> {
  late Timer _timer;

  TimeNotifier() : super(DateTime.now()) {
    _initializeTimer();
  }

  void _initializeTimer() {
    final now = DateTime.now();
    final nextMinute =
        DateTime(now.year, now.month, now.day, now.hour, now.minute + 1);
    final duration = nextMinute.difference(now);

    _timer = Timer(duration, () {
      _updateTime();
      _timer = Timer.periodic(const Duration(minutes: 1), (_) => _updateTime());
    });
  }

  void _updateTime() {
    state = DateTime.now();
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }
}

// 日付や時刻のフォーマット用のProvider
final formattedTimeProvider = Provider<String>((ref) {
  final currentTime = ref.watch(timeProvider);
  return DateFormat('HH:mm').format(currentTime);
});

final formattedDateProvider = Provider<String>((ref) {
  final currentTime = ref.watch(timeProvider);
  return DateFormat('yyyy年MM月dd日').format(currentTime);
});

final weekdayProvider = Provider<String>((ref) {
  final currentTime = ref.watch(timeProvider);
  const weekdays = ['月', '火', '水', '木', '金', '土', '日'];
  return weekdays[currentTime.weekday - 1];
});
