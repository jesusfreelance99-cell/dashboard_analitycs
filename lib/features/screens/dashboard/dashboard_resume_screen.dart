import 'package:flutter/material.dart';

///pantalla para ver el resumen del dashboard
class DashboardResumeScreen extends StatelessWidget {
  const DashboardResumeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Scaffold(body: Center(child: Text('Hola Mundo')));
  }
}
