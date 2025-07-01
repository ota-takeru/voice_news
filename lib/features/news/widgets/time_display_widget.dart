import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/time_provider.dart';

class TimeDisplayWidget extends ConsumerWidget {
  const TimeDisplayWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final formattedDate = ref.watch(formattedDateProvider);
    final weekday = ref.watch(weekdayProvider);
    final formattedTime = ref.watch(formattedTimeProvider);

    return Column(
      children: [
        Text(
          '$formattedDate ($weekday)',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.blueGrey,
          ),
        ),
        Text(
          formattedTime,
          style: const TextStyle(
            fontSize: 36,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }
}
