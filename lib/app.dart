import 'package:flutter/material.dart';

import 'screens/root_shell.dart';
import 'theme/senisafe_theme.dart';

class SeniSafeApp extends StatelessWidget {
  const SeniSafeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '颐安 SeniSafe',
      debugShowCheckedModeBanner: false,
      theme: SeniSafeTheme.light(),
      home: const RootShell(),
    );
  }
}
