import 'package:flutter/material.dart';
import 'package:minhas_viagens/screens/splash_screen.dart';
import 'package:firebase_core/firebase_core.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const MaterialApp(
    title: 'Minhas viagens',
    home: SplashScreen(),
    debugShowCheckedModeBanner: false,
  ));
}