import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'themes/app_colors.dart';
import 'features/news/screen/start_screen.dart';

void main() {
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
      title: 'ニュースアプリ',
      theme: ThemeData(
        primaryColor: AppColors.primary,
        scaffoldBackgroundColor: AppColors.background,
        appBarTheme: const AppBarTheme(
          backgroundColor: AppColors.primary, // AppBarの背景色を設定
          foregroundColor: Colors.white, // AppBar内のテキストやアイコンの色を設定
        ),
        textTheme: const TextTheme(
          bodyLarge: TextStyle(color: AppColors.text),
          bodyMedium: TextStyle(color: AppColors.text),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ButtonStyle(
            backgroundColor: const WidgetStatePropertyAll(AppColors.primary),
            foregroundColor: const WidgetStatePropertyAll(Colors.white),
            elevation: const WidgetStatePropertyAll(4.0),
            shadowColor:
                WidgetStatePropertyAll(AppColors.primary.withOpacity(0.5)),
          ),
        ),
      ),
      home: const StartScreen(),
    );
  }
}
