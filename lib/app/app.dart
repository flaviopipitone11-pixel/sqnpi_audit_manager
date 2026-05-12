import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'router.dart';

class SqnpiAuditManagerApp extends ConsumerWidget {
  const SqnpiAuditManagerApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);

    return MaterialApp.router(
      title: 'SQNPI Audit Manager',
      debugShowCheckedModeBanner: false,
      scrollBehavior: const AppScrollBehavior(),
      locale: const Locale('it', 'IT'),
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('it', 'IT')],
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF2D6A4F),
          primary: const Color(0xFF2D6A4F),
          secondary: const Color(0xFF1B4332),
          surface: Colors.white,
          surfaceContainer: const Color(0xFFF8F9FA),
        ),
        appBarTheme: const AppBarTheme(
          centerTitle: false,
          elevation: 0,
          scrolledUnderElevation: 0,
          backgroundColor: Colors.white,
          foregroundColor: Color(0xFF1B4332),
          titleTextStyle: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1B4332),
          ),
        ),
        navigationRailTheme: const NavigationRailThemeData(
          backgroundColor: Colors.white,
          selectedIconTheme: IconThemeData(color: Color(0xFF2D6A4F)),
          unselectedIconTheme: IconThemeData(color: Colors.grey),
          selectedLabelTextStyle: TextStyle(
            color: Color(0xFF2D6A4F),
            fontWeight: FontWeight.bold,
          ),
          unselectedLabelTextStyle: TextStyle(color: Colors.grey),
        ),
        cardTheme: CardThemeData(
          color: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: Colors.grey.shade200),
          ),
        ),
        dividerTheme: DividerThemeData(
          color: Colors.grey.shade200,
          thickness: 1,
        ),
      ),
      routerConfig: router,
    );
  }
}

class AppScrollBehavior extends MaterialScrollBehavior {
  const AppScrollBehavior();

  @override
  Set<PointerDeviceKind> get dragDevices => {
    PointerDeviceKind.touch,
    PointerDeviceKind.mouse,
    PointerDeviceKind.trackpad,
    PointerDeviceKind.stylus,
  };
}
