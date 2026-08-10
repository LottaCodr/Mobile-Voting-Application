import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';

import 'app.dart';
import 'core/app_config.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Makes the semantics tree available to assistive technologies on web too.
  SemanticsBinding.instance.ensureSemantics();
  await SupabaseBootstrap.initialize();
  runApp(const MyApp());
}
