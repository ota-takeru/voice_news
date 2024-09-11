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
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.blueGrey,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          formattedTime,
          style: const TextStyle(
            fontSize: 56,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }
}
