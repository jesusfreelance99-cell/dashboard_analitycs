import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'dashboard_provider.dart';
import 'dashboard_shell_widget.dart';

class DashboardResumeScreen extends StatelessWidget {
  const DashboardResumeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => DashboardProvider(),
      child: const DashboardShell(),
    );
  }
}
