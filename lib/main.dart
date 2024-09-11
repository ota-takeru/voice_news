import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:workmanager/workmanager.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'features/news/services/news_service.dart';
import 'features/settings/services/flutter_tts_service.dart';
import 'themes/app_colors.dart';
import 'features/news/screen/start_screen.dart';

const String taskName = "updateNews";

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    switch (task) {
      case taskName:
        final newsService = NewsService();
        await newsService.fetchNews();
        await scheduleNextUpdate();
        break;
    }
    return Future.value(true);
  });
}

Future<void> scheduleNextUpdate() async {
  final now = DateTime.now();
  final nextRun =
      DateTime(now.year, now.month, now.day, 2, 0).add(const Duration(days: 1));
  final delay = nextRun.difference(now);

  await Workmanager().registerOneOffTask(
    taskName,
    taskName,
    initialDelay: delay,
    constraints: Constraints(
      networkType: NetworkType.connected,
      requiresBatteryNotLow: true,
    ),
  );
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Workmanager().initialize(callbackDispatcher, isInDebugMode: false);

    final prefs = await SharedPreferences.getInstance();
    final lastScheduled = prefs.getInt('lastScheduled') ?? 0;
    final newsService = NewsService();
    if (DateTime.now().millisecondsSinceEpoch - lastScheduled >
        const Duration(hours: 23).inMilliseconds) {
      await scheduleNextUpdate();
      await newsService.fetchNews(); // アプリ起動時にニュースをフェッチ
      await prefs.setInt(
          'lastScheduled', DateTime.now().millisecondsSinceEpoch);
    } else if (DateTime.now()
            .difference(DateTime.fromMillisecondsSinceEpoch(lastScheduled))
            .inDays >=
        1) {
      // ローカルデータが1日以上前の場合、ニュースをフェッチ
      await newsService.fetchNews();
    }
  } catch (e) {
    print('Workmanagerの初期化エラー: $e');
  }

  runApp(
    const ProviderScope(
      child: NewsApp(),
    ),
  );
}

class NewsApp extends StatelessWidget {
  const NewsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '音声ニュース',
      theme: ThemeData(
        primaryColor: AppColors.primary,
        scaffoldBackgroundColor: AppColors.background,
        appBarTheme: const AppBarTheme(
            backgroundColor: AppColors.secondary,
            foregroundColor: AppColors.text),
        textTheme: const TextTheme(
          bodyLarge: TextStyle(color: AppColors.text),
          bodyMedium: TextStyle(color: AppColors.text),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ButtonStyle(
            backgroundColor: WidgetStateProperty.all(AppColors.primary),
            foregroundColor: WidgetStateProperty.all(Colors.white),
            elevation: WidgetStateProperty.all(4.0),
            shadowColor:
                WidgetStateProperty.all(AppColors.primary.withOpacity(0.5)),
          ),
        ),
      ),
      home: const StartScreen(),
    );
  }
}
