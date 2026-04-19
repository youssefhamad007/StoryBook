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

  // ── System UI ──────────────────────────────────────────────────────────
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );

  // ── Environment Variables ──────────────────────────────────────────────
  await dotenv.load(fileName: ".env");

  // ── Supabase ───────────────────────────────────────────────────────────
  await Supabase.initialize(
    url: dotenv.get('SUPABASE_URL'),
    anonKey: dotenv.get('SUPABASE_ANON_KEY'),
  );

  // ── Local Database (Drift) ─────────────────────────────────────────────
  final appDatabase = AppDatabase();

  // ── Sync Engine ────────────────────────────────────────────────────────
  final syncEngineService = SyncEngineService(
    db: appDatabase,
    supabase: Supabase.instance.client,
  );

  // ── Connectivity Listener ──────────────────────────────────────────────
  final connectivitySyncService = ConnectivitySyncService(
    syncEngineService: syncEngineService,
  );
  connectivitySyncService.startListening();

  // ── Launch App ─────────────────────────────────────────────────────────
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
