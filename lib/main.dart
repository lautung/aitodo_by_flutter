import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/task_provider.dart';
import 'providers/task_group_provider.dart';
import 'providers/pomodoro_provider.dart';
import 'providers/theme_provider.dart';
import 'providers/tag_provider.dart';
import 'providers/priority_provider.dart';
import 'providers/ai_mode_provider.dart';
import 'providers/notification_settings_provider.dart';
import 'providers/sync_provider.dart';
import 'screens/home_screen.dart';
import 'widgets/compliance_gate.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => TaskProvider()..initialize()),
        ChangeNotifierProvider(
          create: (_) => TaskGroupProvider()..initialize(),
        ),
        ChangeNotifierProvider(
          create: (_) {
            final provider = PomodoroProvider();
            unawaited(provider.initialize());
            return provider;
          },
        ),
        ChangeNotifierProvider(create: (_) => TagProvider()),
        ChangeNotifierProvider(create: (_) => PriorityProvider()),
        ChangeNotifierProvider(create: (_) => AiModeProvider()),
        ChangeNotifierProvider(create: (_) => NotificationSettingsProvider()),
        ChangeNotifierProvider(create: (_) => SyncProvider()),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          ThemeData buildTheme(Brightness brightness) {
            final colorScheme = ColorScheme.fromSeed(
              seedColor: themeProvider.seedColor,
              brightness: brightness,
            );
            final isDark = brightness == Brightness.dark;

            return ThemeData(
              colorScheme: colorScheme,
              useMaterial3: true,
              scaffoldBackgroundColor: colorScheme.surface,
              appBarTheme: AppBarTheme(
                centerTitle: false,
                elevation: 0,
                scrolledUnderElevation: 0,
                backgroundColor: colorScheme.surface,
                foregroundColor: colorScheme.onSurface,
                titleTextStyle: TextStyle(
                  color: colorScheme.onSurface,
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                ),
              ),
              cardTheme: CardThemeData(
                elevation: 0,
                color: colorScheme.surfaceContainerLowest,
                margin: EdgeInsets.zero,
                shape: RoundedRectangleBorder(
                  side: BorderSide(color: colorScheme.outlineVariant),
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              dialogTheme: DialogThemeData(
                backgroundColor: colorScheme.surface,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              bottomSheetTheme: BottomSheetThemeData(
                backgroundColor: colorScheme.surface,
                modalBackgroundColor: colorScheme.surface,
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                ),
              ),
              navigationBarTheme: NavigationBarThemeData(
                height: 72,
                elevation: 0,
                backgroundColor: colorScheme.surface,
                indicatorColor: colorScheme.primaryContainer.withValues(
                  alpha: isDark ? 0.35 : 0.55,
                ),
                labelTextStyle: WidgetStateProperty.resolveWith(
                  (states) => TextStyle(
                    fontSize: 12,
                    fontWeight: states.contains(WidgetState.selected)
                        ? FontWeight.w700
                        : FontWeight.w500,
                  ),
                ),
              ),
              tabBarTheme: TabBarThemeData(
                dividerColor: Colors.transparent,
                indicatorSize: TabBarIndicatorSize.tab,
                labelColor: colorScheme.primary,
                unselectedLabelColor: colorScheme.onSurfaceVariant,
                labelStyle: const TextStyle(fontWeight: FontWeight.w800),
                unselectedLabelStyle: const TextStyle(
                  fontWeight: FontWeight.w600,
                ),
              ),
              snackBarTheme: SnackBarThemeData(
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              inputDecorationTheme: InputDecorationTheme(
                filled: true,
                fillColor: colorScheme.surfaceContainerLowest,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: colorScheme.outlineVariant),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
            );
          }

          return MaterialApp(
            title: 'AiTODO',
            debugShowCheckedModeBanner: false,
            themeMode: themeProvider.themeMode,
            theme: buildTheme(Brightness.light),
            darkTheme: buildTheme(Brightness.dark),
            home: const ComplianceGate(child: HomeScreen()),
          );
        },
      ),
    );
  }
}
