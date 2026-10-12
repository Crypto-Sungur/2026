import 'package:flutter/material.dart';
import '../services/auth_service.dart';

class GirisScreen extends StatefulWidget {
  const GirisScreen({super.key});

  @override
  State<GirisScreen> createState() => _GirisScreenState();
}

class _GirisScreenState extends State<GirisScreen> {
  final _emailCtrl = TextEditingController();
  final _sifreCtrl = TextEditingController();
  final _sifreTekrarCtrl = TextEditingController();

  bool _kayitModu = false;
  bool _yukleniyor = false;
  bool _sifreGizli = true;
  String? _mesaj;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _sifreCtrl.dispose();
    _sifreTekrarCtrl.dispose();
    super.dispose();
  }

  Future<void> _girisYap() async {
    final email = _emailCtrl.text.trim();
    final sifre = _sifreCtrl.text;

    if (email.isEmpty || sifre.isEmpty) {
      setState(() => _mesaj = '⚠️ E-posta ve şifre gerekli');
      return;
    }

    setState(() {
      _yukleniyor = true;
      _mesaj = null;
    });

    try {
      await AuthService.girisYap(email: email, sifre: sifre);
    } catch (e) {
      setState(() {
        _yukleniyor = false;
        _mesaj = '❌ ${AuthService.hataMesaji(e)}';
      });
    }
  }

  Future<void> _kayitOl() async {
    final email = _emailCtrl.text.trim();
    final sifre = _sifreCtrl.text;
    final sifreTekrar = _sifreTekrarCtrl.text;

    if (email.isEmpty || sifre.isEmpty) {
      setState(() => _mesaj = '⚠️ E-posta ve şifre gerekli');
      return;
    }
    if (sifre != sifreTekrar) {
      setState(() => _mesaj = '⚠️ Şifreler uyuşmuyor');
      return;
    }
    if (sifre.length < 6) {
      setState(() => _mesaj = '⚠️ Şifre en az 6 karakter olmalı');
      return;
    }

    setState(() {
      _yukleniyor = true;
      _mesaj = null;
    });

    try {
      await AuthService.kayitOl(email: email, sifre: sifre);
    } catch (e) {
      setState(() {
        _yukleniyor = false;
        _mesaj = '❌ ${AuthService.hataMesaji(e)}';
      });
    }
  }

  Future<void> _googleGiris() async {
    setState(() {
      _yukleniyor = true;
      _mesaj = null;
    });

    try {
      final sonuc = await AuthService.googleIleGiris();
      if (sonuc == null) {
        setState(() => _yukleniyor = false);
      }
    } catch (e) {
      setState(() {
        _yukleniyor = false;
        _mesaj = '❌ ${AuthService.hataMesaji(e)}';
      });
    }
  }

  Future<void> _sifreSifirla() async {
    final email = _emailCtrl.text.trim();
    if (email.isEmpty) {
      setState(() => _mesaj = '⚠️ Önce e-posta adresini gir');
      return;
    }

    try {
      await AuthService.sifreSifirla(email);
      setState(() => _mesaj = '✅ Şifre sıfırlama e-postası gönderildi');
    } catch (e) {
      setState(() => _mesaj = '❌ ${AuthService.hataMesaji(e)}');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF010409),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _baslik(),
                const SizedBox(height: 40),
                _kart(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _baslik() {
    return Column(
      children: [
        RichText(
          textAlign: TextAlign.center,
          text: const TextSpan(
            style: TextStyle(
              fontSize: 44,
              fontWeight: FontWeight.w900,
              fontStyle: FontStyle.italic,
              letterSpacing: -2,
              color: Colors.white,
            ),
            children: [
              TextSpan(text: 'SUNGUR'),
              TextSpan(text: ' 2026', style: TextStyle(color: Color(0xFF2F81F7))),
            ],
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'SUNGUR VERI ANALIZI & RAPORLAMA',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 9,
            fontWeight: FontWeight.bold,
            letterSpacing: 3,
            color: Color(0xFF2F81F7),
          ),
        ),
      ],
    );
  }

  Widget _kart() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF161B22).withOpacity(0.85),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFF30363D)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            _kayitModu ? 'KAYIT OL' : 'GİRİŞ YAP',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              letterSpacing: 2,
              color: Color(0xFF58A6FF),
            ),
          ),
          const SizedBox(height: 24),

          _input('E-POSTA', _emailCtrl, Icons.email_outlined, email: true),
          const SizedBox(height: 12),
          _input('ŞİFRE', _sifreCtrl, Icons.lock_outline, sifre: true),
          if (_kayitModu) ...[
            const SizedBox(height: 12),
            _input('ŞİFRE TEKRAR', _sifreTekrarCtrl, Icons.lock_outline, sifre: true),
          ],

          if (!_kayitModu) ...[
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: _yukleniyor ? null : _sifreSifirla,
                child: const Text(
                  'Şifremi Unuttum',
                  style: TextStyle(fontSize: 12, color: Color(0xFF58A6FF)),
                ),
              ),
            ),
          ],

          const SizedBox(height: 16),

          SizedBox(
            height: 54,
            child: ElevatedButton(
              onPressed: _yukleniyor ? null : (_kayitModu ? _kayitOl : _girisYap),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2F81F7),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              child: _yukleniyor
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : Text(
                      _kayitModu ? 'KAYIT OL' : 'GİRİŞ YAP',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, letterSpacing: 1.5),
                    ),
            ),
          ),

          const SizedBox(height: 16),
          Row(
            children: const [
              Expanded(child: Divider(color: Color(0xFF30363D))),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 12),
                child: Text('VEYA', style: TextStyle(fontSize: 10, color: Color(0xFF6E7681), fontWeight: FontWeight.bold)),
              ),
              Expanded(child: Divider(color: Color(0xFF30363D))),
            ],
          ),
          const SizedBox(height: 16),

          SizedBox(
            height: 54,
            child: OutlinedButton.icon(
              onPressed: _yukleniyor ? null : _googleGiris,
              icon: const Icon(Icons.g_mobiledata, size: 28, color: Colors.white),
              label: const Text(
                'GOOGLE İLE DEVAM ET',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 1),
              ),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Color(0xFF30363D)),
                backgroundColor: const Color(0xFF0D1117),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ),

          const SizedBox(height: 16),
          TextButton(
            onPressed: _yukleniyor
                ? null
                : () => setState(() {
                      _kayitModu = !_kayitModu;
                      _mesaj = null;
                    }),
            child: Text(
              _kayitModu
                  ? 'Zaten hesabın var mı? Giriş yap'
                  : 'Hesabın yok mu? Kayıt ol',
              style: const TextStyle(fontSize: 12, color: Color(0xFF58A6FF)),
            ),
          ),

          if (_mesaj != null) ...[
            const SizedBox(height: 12),
            Text(
              _mesaj!,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: _mesaj!.startsWith('✅')
                    ? const Color(0xFF4ADE80)
                    : const Color(0xFFF87171),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _input(String baslik, TextEditingController ctrl, IconData ikon,
      {bool sifre = false, bool email = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF0D1117),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF30363D)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            baslik,
            style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w800, letterSpacing: 1, color: Color(0xFF8B949E)),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(ikon, size: 18, color: const Color(0xFF58A6FF)),
              const SizedBox(width: 10),
              Expanded(
                child: TextField(
                  controller: ctrl,
                  obscureText: sifre && _sifreGizli,
                  keyboardType: email ? TextInputType.emailAddress : TextInputType.text,
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFF58A6FF)),
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ),
              if (sifre)
                GestureDetector(
                  onTap: () => setState(() => _sifreGizli = !_sifreGizli),
                  child: Icon(
                    _sifreGizli ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                    size: 18,
                    color: const Color(0xFF8B949E),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}