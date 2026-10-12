import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'firebase_options.dart';
import 'screens/ana_sayfa.dart';
import 'screens/giris_screen.dart';
import 'screens/splash_screen.dart';
import 'services/auth_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const SungurApp());
}

class SungurApp extends StatelessWidget {
  const SungurApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SUNGUR 2026',
      debugShowCheckedModeBanner: false,
      locale: const Locale('tr', 'TR'),
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('tr', 'TR'),
        Locale('en', 'US'),
      ],
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF010409),
        primaryColor: const Color(0xFF2F81F7),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF2F81F7),
          surface: Color(0xFF0D1117),
        ),
        useMaterial3: true,
      ),
      home: const SplashGate(),
    );
  }
}

class SplashGate extends StatefulWidget {
  const SplashGate({super.key});

  @override
  State<SplashGate> createState() => _SplashGateState();
}

class _SplashGateState extends State<SplashGate> {
  bool _splashBitti = false;

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 3000), () {
      if (mounted) setState(() => _splashBitti = true);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_splashBitti) {
      return const SplashScreen();
    }

    return StreamBuilder<User?>(
      stream: AuthService.authStateChanges,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            backgroundColor: Color(0xFF010409),
            body: Center(
              child: CircularProgressIndicator(color: Color(0xFF58A6FF)),
            ),
          );
        }

        if (snapshot.hasData) {
          return const AnaSayfa();
        }

        return const GirisScreen();
      },
    );
  }
}