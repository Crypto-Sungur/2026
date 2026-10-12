import 'package:flutter/material.dart';
import 'hesap_screen.dart';
import 'harcama_liste_screen.dart';
import 'rapor_screen.dart';
import 'ayarlar_screen.dart';
import 'veri_screen.dart';

class AnaSayfa extends StatefulWidget {
  const AnaSayfa({super.key});

  @override
  State<AnaSayfa> createState() => _AnaSayfaState();
}

class _AnaSayfaState extends State<AnaSayfa> {
  int _seciliIndex = 0;

  final List<Widget> _sayfalar = const [
    HesapScreen(),
    HarcamaListeScreen(),
    RaporScreen(),
    AyarlarScreen(),
    VeriScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _seciliIndex,
        children: _sayfalar,
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: Color(0xFF0D1117),
          border: Border(
            top: BorderSide(color: Color(0xFF30363D), width: 1),
          ),
        ),
        child: BottomNavigationBar(
          currentIndex: _seciliIndex,
          onTap: (i) => setState(() => _seciliIndex = i),
          backgroundColor: const Color(0xFF0D1117),
          selectedItemColor: const Color(0xFF58A6FF),
          unselectedItemColor: const Color(0xFF8B949E),
          type: BottomNavigationBarType.fixed,
          selectedFontSize: 10,
          unselectedFontSize: 9,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.calculate_outlined),
              activeIcon: Icon(Icons.calculate),
              label: 'HESAP',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.receipt_long_outlined),
              activeIcon: Icon(Icons.receipt_long),
              label: 'HARCAMA',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.bar_chart_outlined),
              activeIcon: Icon(Icons.bar_chart),
              label: 'RAPOR',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_outline),
              activeIcon: Icon(Icons.person),
              label: 'AYARLAR',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.storage_outlined),
              activeIcon: Icon(Icons.storage),
              label: 'VERİ',
            ),
          ],
        ),
      ),
    );
  }
}