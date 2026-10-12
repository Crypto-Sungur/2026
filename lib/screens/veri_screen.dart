import 'package:flutter/material.dart';

class VeriScreen extends StatelessWidget {
  const VeriScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF010409),
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                RichText(
                  textAlign: TextAlign.center,
                  text: const TextSpan(
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w900,
                      fontStyle: FontStyle.italic,
                      letterSpacing: -1.5,
                      color: Colors.white,
                    ),
                    children: [
                      TextSpan(text: 'VERİ'),
                      TextSpan(text: ' YÖNETİMİ', style: TextStyle(color: Color(0xFF2F81F7))),
                    ],
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  '',
                  style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 3, color: Color(0xFF2F81F7)),
                ),
                const SizedBox(height: 60),
                Container(
                  padding: const EdgeInsets.all(40),
                  decoration: BoxDecoration(
                    color: const Color(0xFF161B22).withOpacity(0.5),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: const Color(0xFF30363D)),
                  ),
                  child: const Column(
                    children: [
                      Text('🚧', style: TextStyle(fontSize: 60)),
                      SizedBox(height: 16),
                      Text(
                        'YAKINDA',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 4,
                          color: Color(0xFF58A6FF),
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Bu özellik yapım aşamasında',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 12, color: Color(0xFF8B949E)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}