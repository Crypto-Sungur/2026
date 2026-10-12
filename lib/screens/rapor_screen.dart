import 'package:flutter/material.dart';
import '../services/firestore_service.dart';
import '../models/kayit.dart';
import '../services/pdf_service.dart';

class RaporScreen extends StatefulWidget {
  const RaporScreen({super.key});

  @override
  State<RaporScreen> createState() => _RaporScreenState();
}

class _RaporScreenState extends State<RaporScreen> {
  List<Kayit> _kayitlar = [];
  bool _yukleniyor = true;
  String? _hata;
  int? _seciliYil; // null = TÜMÜ

  static const _ayAdlari = [
    '', 'Ocak', 'Şubat', 'Mart', 'Nisan', 'Mayıs', 'Haziran',
    'Temmuz', 'Ağustos', 'Eylül', 'Ekim', 'Kasım', 'Aralık'
  ];

  @override
  void initState() {
    super.initState();
    _yukle();
  }

  Future<void> _yukle() async {
    setState(() {
      _yukleniyor = true;
      _hata = null;
    });

    try {
      final liste = await FirestoreService.tumKayitlariGetir();
      setState(() {
        _kayitlar = liste;
        _yukleniyor = false;
      });
    } catch (e) {
      setState(() {
        _hata = 'Veri yüklenemedi: $e';
        _yukleniyor = false;
      });
    }
  }

  List<int> get _yillar {
    final set = _kayitlar.map((k) => k.yil).toSet().toList();
    set.sort((a, b) => b.compareTo(a));
    return set;
  }

  List<Kayit> get _filtrelenmis {
    if (_seciliYil == null) return _kayitlar;
    return _kayitlar.where((k) => k.yil == _seciliYil).toList();
  }

  double get _toplamNet => _filtrelenmis.fold(0, (s, k) => s + k.netToplam);
  double get _toplamBes => _filtrelenmis.fold(0, (s, k) => s + k.besKesinti);
  double get _toplamEkstra => _filtrelenmis.fold(0, (s, k) => s + k.toplamEkstra);
  double get _ortalama => _filtrelenmis.isEmpty ? 0 : _toplamNet / _filtrelenmis.length;

  String _fmt(num n, {int dec = 0}) {
    final s = n.toStringAsFixed(dec);
    final parts = s.split('.');
    final intPart = parts[0].replaceAllMapped(
      RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
      (m) => '${m[1]}.',
    );
    return parts.length > 1 ? '$intPart,${parts[1]}' : intPart;
  }

  Future<void> _silOnay(Kayit k) async {
    final onay = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF0D1117),
        title: Text('${_ayAdlari[k.ay]} ${k.yil}'),
        content: const Text('Bu kayıt silinsin mi?'),
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

    if (onay == true) {
      try {
        await FirestoreService.kayitSil(k.yil, k.ay);
        await _yukle();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Silme hatası: $e')),
          );
        }
      }
    }
  }

  void _detayGoster(Kayit k) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF0D1117),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.9,
        minChildSize: 0.4,
        expand: false,
        builder: (_, scrollCtrl) => ListView(
          controller: scrollCtrl,
          padding: const EdgeInsets.all(24),
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFF30363D),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              '${_ayAdlari[k.ay]} ${k.yil}',
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w900,
                color: Color(0xFF58A6FF),
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'DÖNEM DETAYI',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w800,
                letterSpacing: 2,
                color: Color(0xFF8B949E),
              ),
            ),
            const SizedBox(height: 20),
            _detaySatir('Maaş', '₺${_fmt(k.maas, dec: 2)}'),
            _detaySatir('Maaş Modu', k.maasMod == 'profil' ? 'Profil' : 'Manuel'),
            _detaySatir('Yevmiye', '₺${_fmt(k.gunluk, dec: 2)}'),
            _detaySatir('Ay Gün Sayısı', '${k.gunSayisi} gün'),
            _detaySatir('31. Gün Farkı', '+₺${_fmt(k.ayFarki, dec: 2)}'),
            _detaySatir('Şehir Dışı', '+₺${_fmt(k.sehirDisiEk, dec: 2)}'),
            _detaySatir('Yurt Dışı', '+₺${_fmt(k.yurtDisiEk, dec: 2)}'),
            _detaySatir('Mesai', '+₺${_fmt(k.mesaiEk, dec: 2)}'),
            _detaySatir('Özel Gün', '+₺${_fmt(k.ozelGunEk, dec: 2)}'),
            _detaySatir('Hakediş', '₺${_fmt(k.hakedis, dec: 2)}'),
            _detaySatir('BES Kesintisi', '-₺${_fmt(k.besKesinti, dec: 2)}', renk: const Color(0xFFF87171)),
            const Divider(color: Color(0xFF30363D), height: 30),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'NET TOPLAM',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF58A6FF),
                  ),
                ),
                Text(
                  '₺${_fmt(k.netToplam, dec: 2)}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _detaySatir(String sol, String sag, {Color? renk}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(sol, style: const TextStyle(fontSize: 12, color: Color(0xFF8B949E))),
          Text(
            sag,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w900,
              color: renk ?? Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF010409),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _yukle,
          color: const Color(0xFF58A6FF),
          backgroundColor: const Color(0xFF161B22),
          child: _yukleniyor
              ? const Center(child: CircularProgressIndicator(color: Color(0xFF58A6FF)))
              : _hata != null
                  ? _hataWidget()
                  : ListView(
                      padding: const EdgeInsets.all(16),
                      children: [
                        const SizedBox(height: 20),
                        _baslik(),
                        const SizedBox(height: 20),
                        _yilCipleri(),
                        const SizedBox(height: 16),
                        _ozetKutu(),
                        const SizedBox(height: 16),
                        _pdfButonu(),
                        const SizedBox(height: 20),
                        if (_filtrelenmis.isEmpty)
                          _bosDurum()
                        else
                          ..._filtrelenmis.map((k) => _kayitKarti(k)),
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
              TextSpan(text: 'GEÇMİŞ'),
              TextSpan(text: ' RAPORLAR', style: TextStyle(color: Color(0xFF2F81F7))),
            ],
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'KAYITLI DÖNEMLER',
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

  Widget _yilCipleri() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _yilCip('TÜMÜ', _seciliYil == null, () => setState(() => _seciliYil = null)),
          ..._yillar.map((y) => Padding(
                padding: const EdgeInsets.only(left: 8),
                child: _yilCip('$y', _seciliYil == y, () => setState(() => _seciliYil = y)),
              )),
        ],
      ),
    );
  }

  Widget _yilCip(String yazi, bool aktif, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: aktif ? const Color(0xFF2F81F7) : const Color(0xFF0D1117),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: aktif ? const Color(0xFF2F81F7) : const Color(0xFF30363D),
          ),
        ),
        child: Text(
          yazi,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w900,
            letterSpacing: 1,
            color: aktif ? Colors.white : const Color(0xFF8B949E),
          ),
        ),
      ),
    );
  }

  Future<void> _pdfAl() async {
  if (_filtrelenmis.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Rapor için kayıt yok')),
    );
    return;
  }

  try {
    final isim = await _profilIsimGetir();
    await PdfService.raporPdf(
      kayitlar: _filtrelenmis,
      adSoyad: isim,
      seciliYil: _seciliYil?.toString(),
    );
  } catch (e) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('PDF hatası: $e')),
      );
    }
  }
}

Future<String> _profilIsimGetir() async {
  try {
    final p = await FirestoreService.profilGetir();
    if (p == null) return 'SUNGUR 2026';
    final isim = (p['isim'] ?? '').toString();
    final soy = (p['soyisim'] ?? '').toString();
    final tam = '$isim $soy'.trim();
    return tam.isEmpty ? 'SUNGUR 2026' : tam;
  } catch (_) {
    return 'SUNGUR 2026';
  }
}

  Widget _ozetKutu() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF2F81F7).withOpacity(0.08),
            const Color(0xFFDB2777).withOpacity(0.08),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF2F81F7).withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _seciliYil == null ? 'TOPLAM NET (TÜM YILLAR)' : '$_seciliYil TOPLAM NET',
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 2,
                        color: Color(0xFF8B949E),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '₺${_fmt(_toplamNet)}',
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -1.5,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text(
                    'DÖNEM',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 2,
                      color: Color(0xFF8B949E),
                    ),
                  ),
                  Text(
                    '${_filtrelenmis.length}',
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF58A6FF),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(color: Color(0xFF30363D)),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _miniStat('ORT. NET', '₺${_fmt(_ortalama)}', Colors.white)),
              Expanded(child: _miniStat('TOP. BES', '₺${_fmt(_toplamBes)}', const Color(0xFFF472B6))),
              Expanded(child: _miniStat('TOP. EKSTRA', '₺${_fmt(_toplamEkstra)}', const Color(0xFF4ADE80))),
            ],
          ),
        ],
      ),
    );
  }

  Widget _pdfButonu() {
  return SizedBox(
    height: 54,
    width: double.infinity,
    child: ElevatedButton.icon(
      onPressed: _pdfAl,
      icon: const Icon(Icons.picture_as_pdf),
      label: const Text(
        'PDF OLARAK İNDİR',
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w900,
          letterSpacing: 1.5,
        ),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFFDB2777),
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    ),
  );
}

  Widget _miniStat(String baslik, String deger, Color renk) {
    return Column(
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
        Text(
          deger,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w900,
            color: renk,
          ),
        ),
      ],
    );
  }

  Widget _kayitKarti(Kayit k) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF0D1117),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF30363D)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _ayAdlari[k.ay],
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1,
                      color: Color(0xFF58A6FF),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${k.yil} · Maaş ₺${_fmt(k.maas)}',
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF8B949E),
                    ),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text(
                    'NET',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF8B949E),
                    ),
                  ),
                  Text(
                    '₺${_fmt(k.netToplam)}',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.5,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(color: Color(0xFF21262D), height: 1),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _miniKart('YEVMİYE', '₺${_fmt(k.gunluk)}', Colors.white)),
              Expanded(child: _miniKart('EKSTRA', '+₺${_fmt(k.toplamEkstra)}', const Color(0xFF4ADE80))),
              Expanded(child: _miniKart('BES', '-₺${_fmt(k.besKesinti)}', const Color(0xFFF472B6))),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              _kucukButon('DETAY', const Color(0xFF58A6FF), () => _detayGoster(k)),
              const SizedBox(width: 8),
              _kucukButon('SİL', const Color(0xFFF87171), () => _silOnay(k)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _miniKart(String baslik, String deger, Color renk) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          baslik,
          style: const TextStyle(
            fontSize: 8,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.5,
            color: Color(0xFF8B949E),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          deger,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w900,
            color: renk,
          ),
        ),
      ],
    );
  }

  Widget _kucukButon(String yazi, Color renk, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: renk.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: renk.withOpacity(0.3)),
        ),
        child: Text(
          yazi,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w900,
            letterSpacing: 1,
            color: renk,
          ),
        ),
      ),
    );
  }

  Widget _bosDurum() {
    return Container(
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        color: const Color(0xFF161B22).withOpacity(0.5),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF30363D)),
      ),
      child: const Column(
        children: [
          Text('📭', style: TextStyle(fontSize: 48)),
          SizedBox(height: 12),
          Text(
            'Bu yıl için kayıt yok',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Color(0xFF8B949E),
            ),
          ),
          SizedBox(height: 8),
          Text(
            'HESAP sekmesinden hesaplayıp kaydet',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 11,
              color: Color(0xFF6E7681),
            ),
          ),
        ],
      ),
    );
  }

  Widget _hataWidget() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: Color(0xFFF87171), size: 60),
            const SizedBox(height: 16),
            Text(
              _hata!,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Color(0xFFF87171)),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _yukle,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2F81F7),
              ),
              child: const Text('TEKRAR DENE'),
            ),
          ],
        ),
      ),
    );
  }
}