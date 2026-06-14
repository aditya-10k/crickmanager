import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';

import 'services/api_service.dart';
import 'screens/login_screen.dart';
import 'screens/main_menu_screen.dart';
import 'screens/draft_room_screen.dart';
import 'screens/lineup_screen.dart';
import 'screens/simulation_screen.dart';
import 'screens/season_completed_screen.dart';
import 'theme/app_theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    ChangeNotifierProvider(
      create: (_) => GameProvider(),
      child: const CricManagerApp(),
    ),
  );
}

class CricManagerApp extends StatelessWidget {
  const CricManagerApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CricManager',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: AppTheme.background,
        colorScheme: const ColorScheme.dark(
          primary: AppTheme.neonPink,
          secondary: AppTheme.wkColor,
          background: AppTheme.background,
          surface: AppTheme.surfaceCard,
        ),
        textTheme: GoogleFonts.interTextTheme(ThemeData.dark().textTheme),
        progressIndicatorTheme: const ProgressIndicatorThemeData(
          color: AppTheme.neonPink,
        ),
      ),
      home: const GameStateRouter(),
    );
  }
}

class GameStateRouter extends StatelessWidget {
  const GameStateRouter({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final state = context.select<GameProvider, String>((p) => p.gameState);

    switch (state) {
      case 'login':
        return const LoginScreen();
      case 'menu':
        return const MainMenuScreen();
      case 'draft':
        return const DraftRoomScreen();
      case 'lineup':
        return const LineupScreen();
      case 'sim':
        return const SimulationScreen();
      case 'complete':
        return const SeasonCompletedScreen();
      default:
        return const LoginScreen();
    }
  }
}
