import 'package:flutter/material.dart';
import '../services/firestore_service.dart';
import '../services/auth_service.dart';

class AyarlarScreen extends StatefulWidget {
  const AyarlarScreen({super.key});

  @override
  State<AyarlarScreen> createState() => _AyarlarScreenState();
}

class _AyarlarScreenState extends State<AyarlarScreen> {
  final _isimCtrl = TextEditingController();
  final _soyisimCtrl = TextEditingController();
  final _maasCtrl = TextEditingController();

  bool _yukleniyor = true;
  bool _kaydediliyor = false;
  String? _mesaj;

  @override
  void initState() {
    super.initState();
    _yukle();
  }

  @override
  void dispose() {
    _isimCtrl.dispose();
    _soyisimCtrl.dispose();
    _maasCtrl.dispose();
    super.dispose();
  }

  Future<void> _yukle() async {
    setState(() => _yukleniyor = true);

    try {
      final profil = await FirestoreService.profilGetir();

      setState(() {
        if (profil != null) {
          _isimCtrl.text = profil['isim'] ?? '';
          _soyisimCtrl.text = profil['soyisim'] ?? '';
          _maasCtrl.text = profil['maas'] ?? '';
        }
        _yukleniyor = false;
      });
    } catch (e) {
      setState(() {
        _mesaj = '❌ Yükleme hatası: $e';
        _yukleniyor = false;
      });
    }
  }

  Future<void> _kaydet() async {
    final isim = _isimCtrl.text.trim();
    final soyisim = _soyisimCtrl.text.trim();
    final maas = _maasCtrl.text.trim();

    if (isim.isEmpty) {
      setState(() => _mesaj = '⚠️ İsim gerekli');
      return;
    }

    setState(() {
      _kaydediliyor = true;
      _mesaj = null;
    });

    try {
      await FirestoreService.profilKaydet(
        isim: isim,
        soyisim: soyisim,
        maas: maas,
      );

      setState(() {
        _kaydediliyor = false;
        _mesaj = '✅ Profil kaydedildi!';
      });

      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) setState(() => _mesaj = null);
      });
    } catch (e) {
      setState(() {
        _kaydediliyor = false;
        _mesaj = '❌ Kayıt hatası: $e';
      });
    }
  }

  Future<void> _cikisYap() async {
    final onay = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF0D1117),
        title: const Text('Çıkış Yap'),
        content: const Text('Hesabından çıkmak istediğine emin misin?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('İPTAL', style: TextStyle(color: Color(0xFF8B949E))),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('ÇIKIŞ YAP', style: TextStyle(color: Color(0xFFF87171))),
          ),
        ],
      ),
    );

    if (onay == true) {
      await AuthService.cikisYap();
    }
  }

  Future<void> _hesapSil() async {
    final onay = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF0D1117),
        title: const Text('HESABI SİL', style: TextStyle(color: Color(0xFFF87171))),
        content: const Text(
          'Hesabın ve tüm verilerin kalıcı olarak silinecek.\n\n'
          'Bu işlem geri alınamaz. Devam etmek istiyor musun?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('İPTAL', style: TextStyle(color: Color(0xFF8B949E))),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('SİL', style: TextStyle(color: Color(0xFFF87171))),
          ),
        ],
      ),
    );

    if (onay != true) return;

    setState(() => _yukleniyor = true);
    try {
      await FirestoreService.tumVerileriSil();
      await AuthService.hesapSil();
    } catch (e) {
      setState(() {
        _yukleniyor = false;
        _mesaj = '❌ Hata: $e';
      });
    }
  }

  Future<void> _tumVerileriSil() async {
    final onay = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF0D1117),
        title: const Text('TÜM VERİLER SİLİNECEK', style: TextStyle(color: Color(0xFFF87171))),
        content: const Text(
          'Profil, ayarlar, kayıtlı dönemler ve harcama formları dahil her şey silinecek. Bu işlem geri alınamaz.\n\nDevam etmek istiyor musun?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('İPTAL', style: TextStyle(color: Color(0xFF8B949E))),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('SİL', style: TextStyle(color: Color(0xFFF87171))),
          ),
        ],
      ),
    );

    if (onay != true) return;

    setState(() => _yukleniyor = true);

    try {
      await FirestoreService.tumVerileriSil();
      setState(() {
        _isimCtrl.clear();
        _soyisimCtrl.clear();
        _maasCtrl.clear();
        _yukleniyor = false;
        _mesaj = '🗑️ Tüm veriler silindi';
      });
    } catch (e) {
      setState(() {
        _yukleniyor = false;
        _mesaj = '❌ Silme hatası: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF010409),
      body: SafeArea(
        child: _yukleniyor
            ? const Center(child: CircularProgressIndicator(color: Color(0xFF58A6FF)))
            : SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 20),
                    _baslik(),
                    const SizedBox(height: 20),
                    _profilKarti(),
                    const SizedBox(height: 16),
                    _cikisKarti(),
                    const SizedBox(height: 12),
                    _hesapSilKarti(),
                    const SizedBox(height: 12),
                    _tehlikeKarti(),
                    const SizedBox(height: 24),
                  ],
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
              fontSize: 32,
              fontWeight: FontWeight.w900,
              fontStyle: FontStyle.italic,
              letterSpacing: -1.5,
              color: Colors.white,
            ),
            children: [
              TextSpan(text: 'KULLANICI'),
              TextSpan(text: ' AYARLARI', style: TextStyle(color: Color(0xFF2F81F7))),
            ],
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'PROFİL BİLGİLERİ',
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

  Widget _profilKarti() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF161B22).withOpacity(0.85),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFF30363D)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _inputKutu('İSİM', _isimCtrl, Icons.person_outline),
          const SizedBox(height: 12),
          _inputKutu('SOY İSİM', _soyisimCtrl, Icons.person_outline),
          const SizedBox(height: 12),
          _inputKutu('MAAŞ (NET)', _maasCtrl, Icons.attach_money, prefix: '₺', sayisal: true),
          const SizedBox(height: 20),
          SizedBox(
            height: 54,
            child: ElevatedButton.icon(
              onPressed: _kaydediliyor ? null : _kaydet,
              icon: _kaydediliyor
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.save),
              label: Text(
                _kaydediliyor ? 'KAYDEDİLİYOR...' : 'KAYDET',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.5,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2F81F7),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
            ),
          ),
          if (_mesaj != null) ...[
            const SizedBox(height: 12),
            Text(
              _mesaj!,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: _mesaj!.startsWith('✅') || _mesaj!.startsWith('🗑️')
                    ? const Color(0xFF4ADE80)
                    : const Color(0xFFF87171),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _inputKutu(String baslik, TextEditingController ctrl, IconData ikon,
      {String? prefix, bool sayisal = false}) {
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
            style: const TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w800,
              letterSpacing: 1,
              color: Color(0xFF8B949E),
            ),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(ikon, size: 18, color: const Color(0xFF58A6FF)),
              if (prefix != null) ...[
                const SizedBox(width: 4),
                Text(
                  prefix,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF58A6FF),
                  ),
                ),
              ],
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: ctrl,
                  keyboardType: sayisal
                      ? const TextInputType.numberWithOptions(decimal: true)
                      : TextInputType.text,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF58A6FF),
                  ),
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _cikisKarti() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF0D1117),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF30363D)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.logout, color: Color(0xFF58A6FF), size: 20),
              SizedBox(width: 8),
              Text(
                'ÇIKIŞ YAP',
                style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.5,
                    color: Color(0xFF58A6FF)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            'Hesabından çıkış yap. Verilerin bulutta güvende kalır.',
            style: TextStyle(fontSize: 11, color: Color(0xFF8B949E), height: 1.5),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 48,
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _cikisYap,
              icon: const Icon(Icons.logout, color: Color(0xFF58A6FF), size: 20),
              label: const Text(
                'ÇIKIŞ YAP',
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1,
                    color: Color(0xFF58A6FF)),
              ),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Color(0xFF58A6FF)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _hesapSilKarti() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF0D1117),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFF87171).withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.person_remove, color: Color(0xFFF87171), size: 20),
              SizedBox(width: 8),
              Text(
                'HESABI SİL',
                style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.5,
                    color: Color(0xFFF87171)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            'Hesabın ve tüm verilerin kalıcı olarak silinir. Bu işlem geri alınamaz.',
            style: TextStyle(fontSize: 11, color: Color(0xFF8B949E), height: 1.5),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 48,
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _hesapSil,
              icon: const Icon(Icons.person_remove, color: Color(0xFFF87171), size: 20),
              label: const Text(
                'HESABI SİL',
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1,
                    color: Color(0xFFF87171)),
              ),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Color(0xFFF87171)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _tehlikeKarti() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF0D1117),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFF87171).withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.warning_amber_rounded, color: Color(0xFFF87171), size: 20),
              const SizedBox(width: 8),
              const Text(
                'UYGULAMA VERİLERİ',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.5,
                  color: Color(0xFFF87171),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            'Tüm verilerini kalıcı olarak sil. Bu işlem geri alınamaz.',
            style: TextStyle(
              fontSize: 11,
              color: Color(0xFF8B949E),
              height: 1.5,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 48,
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _tumVerileriSil,
              icon: const Icon(Icons.delete_forever, color: Color(0xFFF87171), size: 20),
              label: const Text(
                'TÜM VERİLERİ SİL',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1,
                  color: Color(0xFFF87171),
                ),
              ),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Color(0xFFF87171)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}