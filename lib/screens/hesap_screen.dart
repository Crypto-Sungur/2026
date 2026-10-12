import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/firestore_service.dart';
import '../models/kayit.dart';

class HesapScreen extends StatefulWidget {
  const HesapScreen({super.key});

  @override
  State<HesapScreen> createState() => _HesapScreenState();
}

class _HesapScreenState extends State<HesapScreen> {
  final _maasCtrl = TextEditingController(text: '28075');
  final _besCtrl = TextEditingController(text: '0');
  final _besManuelCtrl = TextEditingController(text: '0');
  final _izinCtrl = TextEditingController(text: '0');
  final _mesaiCtrl = TextEditingController(text: '0');
  final _sehirDisiCtrl = TextEditingController(text: '0');
  final _yurtDisiCtrl = TextEditingController(text: '0');
  final _ozelGunCtrl = TextEditingController(text: '0');

  int _ay = DateTime.now().month;
  int _yil = DateTime.now().year;
  String _maasMod = 'profil'; // manuel / profil
  String _besMod = 'manuel'; // yuzde / manuel

  bool _hesaplandi = false;
  bool _kaydediliyor = false;
  String? _kayitMesaj;

  Map<String, dynamic>? _sonuc;

  static const _ayAdlari = [
    '', 'Ocak', 'Şubat', 'Mart', 'Nisan', 'Mayıs', 'Haziran',
    'Temmuz', 'Ağustos', 'Eylül', 'Ekim', 'Kasım', 'Aralık'
  ];

  @override
  void initState() {
    super.initState();
    _ayarlardanMaasYukle();
  }

  Future<void> _ayarlardanMaasYukle() async {
  try {
    final profil = await FirestoreService.profilGetir();
    if (profil != null && profil['maas'] != null) {
      final maas = profil['maas'].toString();
      if (maas.isNotEmpty && mounted) {
        setState(() {
          _maasCtrl.text = maas;
        });
        return;
      }
    }
    // Ayarlar'da maaş yoksa varsayılan 28075
    if (mounted) {
      setState(() {
        _maasCtrl.text = '28075';
      });
    }
  } catch (_) {
    if (mounted) {
      setState(() {
        _maasCtrl.text = '28075';
      });
    }
  }
}

  @override
  void dispose() {
    _maasCtrl.dispose();
    _besCtrl.dispose();
    _besManuelCtrl.dispose();
    _izinCtrl.dispose();
    _mesaiCtrl.dispose();
    _sehirDisiCtrl.dispose();
    _yurtDisiCtrl.dispose();
    _ozelGunCtrl.dispose();
    super.dispose();
  }

  double _p(TextEditingController c) => double.tryParse(c.text) ?? 0;

  void _hesapla() {
    final maas = _p(_maasCtrl);
    final besOran = _p(_besCtrl);
    final besManuel = _p(_besManuelCtrl);
    final izin = _p(_izinCtrl);
    final mesaiS = _p(_mesaiCtrl);
    final sDisi = _p(_sehirDisiCtrl);
    final yDisi = _p(_yurtDisiCtrl);
    final ozelGun = _p(_ozelGunCtrl);

    final aylar31 = [1, 3, 5, 7, 8, 10, 12];
    int gunSayisi;
    if (_ay == 2) {
      gunSayisi = (_yil % 4 == 0 && (_yil % 100 != 0 || _yil % 400 == 0)) ? 29 : 28;
    } else {
      gunSayisi = aylar31.contains(_ay) ? 31 : 30;
    }

    final gunluk = maas / 30;
    final saatlik = gunluk / 8;
    double ayFarki = 0;
    if (gunSayisi == 31) ayFarki = gunluk;

    final sehirDisiEk = sDisi * (gunluk * 0.5);
    final yurtDisiEk = yDisi * (gunluk * 1.0);
    final mesaiEk = mesaiS * (saatlik * 1.5);
    final ozelGunEk = ozelGun * gunluk;

    final hakedis = maas + ayFarki - (izin * gunluk) +
        sehirDisiEk + yurtDisiEk + mesaiEk + ozelGunEk;

    final besKesinti = _besMod == 'manuel'
        ? besManuel
        : hakedis * (besOran / 100);

    final netToplam = hakedis - besKesinti;
    final toplamEkstra = sehirDisiEk + yurtDisiEk + mesaiEk + ozelGunEk + ayFarki;

    setState(() {
      _sonuc = {
        'maas': maas,
        'ay': _ay,
        'yil': _yil,
        'besOran': besOran,
        'besManuel': besManuel,
        'besMod': _besMod,
        'izin': izin,
        'mesaiS': mesaiS,
        'sDisi': sDisi,
        'yDisi': yDisi,
        'ozelGun': ozelGun,
        'gunSayisi': gunSayisi,
        'gunluk': gunluk,
        'saatlik': saatlik,
        'ayFarki': ayFarki,
        'sehirDisiEk': sehirDisiEk,
        'yurtDisiEk': yurtDisiEk,
        'mesaiEk': mesaiEk,
        'ozelGunEk': ozelGunEk,
        'hakedis': hakedis,
        'besKesinti': besKesinti,
        'netToplam': netToplam,
        'toplamEkstra': toplamEkstra,
        'maasMod': _maasMod,
      };
      _hesaplandi = true;
      _kayitMesaj = null;
    });
  }

  Future<void> _kaydet() async {
    if (_sonuc == null) return;

    setState(() => _kaydediliyor = true);

    try {
      final kayit = Kayit(
        maas: _sonuc!['maas'],
        ay: _sonuc!['ay'],
        yil: _sonuc!['yil'],
        besOran: _sonuc!['besOran'],
        besManuel: _sonuc!['besManuel'],
        besMod: _sonuc!['besMod'],
        izin: _sonuc!['izin'],
        mesaiS: _sonuc!['mesaiS'],
        sDisi: _sonuc!['sDisi'],
        yDisi: _sonuc!['yDisi'],
        ozelGun: _sonuc!['ozelGun'],
        gunSayisi: _sonuc!['gunSayisi'],
        gunluk: _sonuc!['gunluk'],
        saatlik: _sonuc!['saatlik'],
        ayFarki: _sonuc!['ayFarki'],
        sehirDisiEk: _sonuc!['sehirDisiEk'],
        yurtDisiEk: _sonuc!['yurtDisiEk'],
        mesaiEk: _sonuc!['mesaiEk'],
        ozelGunEk: _sonuc!['ozelGunEk'],
        hakedis: _sonuc!['hakedis'],
        besKesinti: _sonuc!['besKesinti'],
        netToplam: _sonuc!['netToplam'],
        toplamEkstra: _sonuc!['toplamEkstra'],
        maasMod: _sonuc!['maasMod'],
        kayitTarihi: DateTime.now().toIso8601String(),
        ayAdi: _ayAdlari[_ay],
      );

      await FirestoreService.kayitKaydet(kayit);

      setState(() {
        _kaydediliyor = false;
        _kayitMesaj = '✅ ${_yil} / ${_ayAdlari[_ay]} kaydedildi!';
      });

      Future.delayed(const Duration(seconds: 3), () {
        if (mounted) setState(() => _kayitMesaj = null);
      });
    } catch (e) {
      setState(() {
        _kaydediliyor = false;
        _kayitMesaj = '❌ Hata: $e';
      });
    }
  }

  String _fmt(num n, {int dec = 0}) {
    final s = n.toStringAsFixed(dec);
    final parts = s.split('.');
    final intPart = parts[0].replaceAllMapped(
      RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
      (m) => '${m[1]}.',
    );
    return parts.length > 1 ? '$intPart,${parts[1]}' : intPart;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF010409),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 20),
              _baslik(),
              const SizedBox(height: 20),
              _formKarti(),
              const SizedBox(height: 16),
              _hesaplaButonu(),
              if (_hesaplandi && _sonuc != null) ...[
                const SizedBox(height: 20),
                _sonucKarti(),
              ],
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
              fontSize: 42,
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
          'MAAS HESAPLAMA',
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

  Widget _formKarti() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF161B22).withOpacity(0.85),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFF30363D)),
      ),
      child: Column(
        children: [
          // MAAŞ
          _featureBox(
            baslik: 'MAAŞ',
            baslikRenk: const Color(0xFF58A6FF),
            prefix: '₺',
            controller: _maasCtrl,
            segmentler: ['Manuel', 'Profil'],
            seciliSegment: _maasMod == 'manuel' ? 0 : 1,
            onSegment: (i) async {
              setState(() => _maasMod = i == 0 ? 'manuel' : 'profil');
              if (_maasMod == 'profil') {
                await _ayarlardanMaasYukle();
              }
            },
            gizli: _maasMod == 'profil',
          ),
          const SizedBox(height: 12),

          // AY / YIL
          Row(
            children: [
              Expanded(child: _dropdownAy()),
              const SizedBox(width: 12),
              Expanded(child: _dropdownYil()),
            ],
          ),
          const SizedBox(height: 12),

          // BES
          _featureBox(
            baslik: 'BES KESİNTİSİ',
            baslikRenk: const Color(0xFFF472B6),
            prefix: _besMod == 'yuzde' ? '%' : '₺',
            controller: _besMod == 'yuzde' ? _besCtrl : _besManuelCtrl,
            segmentler: ['%', '₺'],
            seciliSegment: _besMod == 'yuzde' ? 0 : 1,
            onSegment: (i) => setState(() => _besMod = i == 0 ? 'yuzde' : 'manuel'),
            renk: const Color(0xFFF472B6),
          ),
          const SizedBox(height: 12),

          // İKİLİ GRID
          Row(
            children: [
              Expanded(child: _sayiKutu('İZİN (GÜN)', _izinCtrl, const Color(0xFFF87171))),
              const SizedBox(width: 12),
              Expanded(child: _sayiKutu('MESAİ (SAAT)', _mesaiCtrl, const Color(0xFF4ADE80))),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _sayiKutu('ŞEHİR DIŞI (GÜN)', _sehirDisiCtrl, const Color(0xFF58A6FF))),
              const SizedBox(width: 12),
              Expanded(child: _sayiKutu('YURT DIŞI (GÜN)', _yurtDisiCtrl, const Color(0xFFFBBF24))),
            ],
          ),
          const SizedBox(height: 12),
          _sayiKutu('ÖZEL GÜN (BAYRAM VB.)', _ozelGunCtrl, const Color(0xFFA78BFA)),
        ],
      ),
    );
  }

  Widget _featureBox({
    required String baslik,
    required Color baslikRenk,
    required String prefix,
    required TextEditingController controller,
    required List<String> segmentler,
    required int seciliSegment,
    required Function(int) onSegment,
    Color renk = const Color(0xFF58A6FF),
    bool gizli = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF0D1117),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF30363D)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                baslik,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1,
                  color: baslikRenk,
                ),
              ),
              _segmentKucuk(segmentler, seciliSegment, onSegment),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFF010409),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFF21262D)),
            ),
            child: Row(
              children: [
                Text(
                  prefix,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: renk,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: gizli
                      ? Text(
                          '•' * (controller.text.length > 0 ? controller.text.length : 6),
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            color: renk,
                            letterSpacing: 4,
                          ),
                        )
                      : TextField(
                          controller: controller,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]'))],
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            color: renk,
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
          ),
        ],
      ),
    );
  }

  Widget _segmentKucuk(List<String> secenekler, int secili, Function(int) onTap) {
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: const Color(0xFF010409),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFF30363D)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(secenekler.length, (i) {
          final aktif = i == secili;
          return GestureDetector(
            onTap: () => onTap(i),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: aktif ? const Color(0xFF2F81F7) : Colors.transparent,
                borderRadius: BorderRadius.circular(7),
              ),
              child: Text(
                secenekler[i],
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                  color: aktif ? Colors.white : const Color(0xFF8B949E),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _dropdownAy() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFF0D1117),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF30363D)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<int>(
          value: _ay,
          isExpanded: true,
          dropdownColor: const Color(0xFF0D1117),
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Color(0xFF58A6FF),
          ),
          items: List.generate(12, (i) => i + 1).map((m) {
            return DropdownMenuItem(
              value: m,
              child: Text(_ayAdlari[m]),
            );
          }).toList(),
          onChanged: (v) => setState(() => _ay = v!),
        ),
      ),
    );
  }

  Widget _dropdownYil() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFF0D1117),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF30363D)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<int>(
          value: _yil,
          isExpanded: true,
          dropdownColor: const Color(0xFF0D1117),
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Color(0xFF58A6FF),
          ),
          items: List.generate(7, (i) => 2024 + i).map((y) {
            return DropdownMenuItem(value: y, child: Text('$y'));
          }).toList(),
          onChanged: (v) => setState(() => _yil = v!),
        ),
      ),
    );
  }

  Widget _sayiKutu(String baslik, TextEditingController ctrl, Color renk) {
    return Container(
      padding: const EdgeInsets.all(12),
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
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.5,
              color: renk,
            ),
          ),
          const SizedBox(height: 6),
          TextField(
            controller: ctrl,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w900,
              color: renk,
            ),
            decoration: const InputDecoration(
              border: InputBorder.none,
              isDense: true,
              contentPadding: EdgeInsets.zero,
            ),
          ),
        ],
      ),
    );
  }

  Widget _hesaplaButonu() {
    return SizedBox(
      height: 60,
      child: ElevatedButton(
        onPressed: _hesapla,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF2F81F7),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          elevation: 8,
        ),
        child: const Text(
          'HESAPLA',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w900,
            letterSpacing: 2,
          ),
        ),
      ),
    );
  }

  Widget _sonucKarti() {
    final s = _sonuc!;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF161B22).withOpacity(0.85),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFF2F81F7), width: 2),
      ),
      child: Column(
        children: [
          const Text(
            'NET HAKEDİŞ',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              letterSpacing: 2,
              color: Color(0xFF8B949E),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '₺${_fmt(s['netToplam'])}',
            style: const TextStyle(
              fontSize: 42,
              fontWeight: FontWeight.w900,
              letterSpacing: -2,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 20),
          const Divider(color: Color(0xFF30363D)),
          const SizedBox(height: 12),
          _satir('Yevmiye (Sabit 30):', '₺${_fmt(s['gunluk'], dec: 2)}', Colors.white),
          const SizedBox(height: 8),
          _satir('Ekstra Toplam:', '+₺${_fmt(s['toplamEkstra'])}', const Color(0xFF4ADE80)),
          const SizedBox(height: 8),
          _satir(
            'BES Kesintisi (${s['besMod'] == 'manuel' ? '₺' : '%'}):',
            '-₺${_fmt(s['besKesinti'])}',
            const Color(0xFFF87171),
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 54,
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _kaydediliyor ? null : _kaydet,
              icon: _kaydediliyor
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.save),
              label: Text(
                _kaydediliyor
                    ? 'KAYDEDİLİYOR...'
                    : 'KAYDET ($_yil / ${_ayAdlari[_ay]})',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF16A34A),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
            ),
          ),
          if (_kayitMesaj != null) ...[
            const SizedBox(height: 12),
            Text(
              _kayitMesaj!,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: _kayitMesaj!.startsWith('✅')
                    ? const Color(0xFF4ADE80)
                    : const Color(0xFFF87171),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _satir(String sol, String sag, Color renk) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          sol,
          style: const TextStyle(fontSize: 12, color: Color(0xFF8B949E)),
        ),
        Text(
          sag,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w900,
            color: renk,
          ),
        ),
      ],
    );
  }
}