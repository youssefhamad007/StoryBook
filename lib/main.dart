import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app.dart';
import 'database/app_database.dart';
import 'providers/auth_provider.dart';
import 'providers/stories_provider.dart';
import 'services/connectivity_sync_service.dart';
import 'services/sync_engine_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );

  // ── Load environment variables ──────────────────────────────────────────
  await dotenv.load(fileName: '.env');

  // ── Initialize Supabase ─────────────────────────────────────────────────
  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL']!,
    anonKey: dotenv.env['SUPABASE_ANON_KEY']!,
  );
  log('Supabase initialized successfully.', name: 'Main');

  // ── Initialize local database & sync engine ─────────────────────────────
  final appDatabase = AppDatabase();
  final syncEngine = SyncEngineService(
    db: appDatabase,
    supabase: Supabase.instance.client,
  );

  // ── Start connectivity listener (auto-sync on reconnect) ────────────────
  final connectivitySync = ConnectivitySyncService(
    syncEngineService: syncEngine,
  );
  connectivitySync.startListening();

  // ── Run the app ─────────────────────────────────────────────────────────
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()..checkAuthState()),
        ChangeNotifierProvider(create: (_) => StoriesProvider()..loadStories()),
      ],
      child: const StorybookApp(),
    ),
  );
}
