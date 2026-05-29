import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/zeni_app.dart';
import 'core/supabase/zeni_supabase.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await ZeniSupabaseBootstrap.initialize();

  runApp(const ProviderScope(child: ZeniApp()));
}
