import 'package:flutter/material.dart';
import '../services/firestore_service.dart';
import '../models/harcama.dart';
import 'harcama_detay_screen.dart';

class HarcamaListeScreen extends StatefulWidget {
  const HarcamaListeScreen({super.key});

  @override
  State<HarcamaListeScreen> createState() => _HarcamaListeScreenState();
}

class _HarcamaListeScreenState extends State<HarcamaListeScreen> {
  List<Harcama> _formlar = [];
  bool _yukleniyor = true;
  String? _hata;

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
      final liste = await FirestoreService.tumHarcamalariGetir();
      setState(() {
        _formlar = liste;
        _yukleniyor = false;
      });
    } catch (e) {
      setState(() {
        _hata = 'Yükleme hatası: $e';
        _yukleniyor = false;
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

  String _tarihGoster(String iso) {
    if (iso.isEmpty) return '-';
    try {
      final d = DateTime.parse(iso);
      return '${d.day.toString().padLeft(2, '0')} ${_ayAdi(d.month)} ${d.year}';
    } catch (_) {
      return iso;
    }
  }

  String _ayAdi(int ay) {
    const aylar = ['', 'Ocak', 'Şubat', 'Mart', 'Nisan', 'Mayıs', 'Haziran',
      'Temmuz', 'Ağustos', 'Eylül', 'Ekim', 'Kasım', 'Aralık'];
    return aylar[ay];
  }

  Future<void> _silOnay(Harcama h) async {
    final onay = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF0D1117),
        title: Text(h.ad),
        content: const Text('Bu form ve tüm işlemleri silinecek. Emin misin?'),
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
        await FirestoreService.harcamaSil(h.id);
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

  Future<void> _acDetay(Harcama h) async {
    final sonuc = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => HarcamaDetayScreen(harcamaId: h.id),
      ),
    );
    if (sonuc == true) {
      _yukle();
    }
  }

  Future<void> _yeniFormModal() async {
    final adCtrl = TextEditingController();
    final tryCtrl = TextEditingController(text: '0');
    final usdCtrl = TextEditingController(text: '0');
    DateTime gidis = DateTime.now();
    DateTime donus = DateTime.now();

    final onay = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: const Color(0xFF0D1117),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModal) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom,
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 40, height: 4,
                    decoration: BoxDecoration(
                      color: const Color(0xFF30363D),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'YENİ FORM',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1,
                    color: Color(0xFF58A6FF),
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'SEYAHAT / MASRAF',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 2,
                    color: Color(0xFF8B949E),
                  ),
                ),
                const SizedBox(height: 20),
                _modalInput('FORM ADI', adCtrl, 'Örn: Form-01'),
                const SizedBox(height: 12),
                _tarihSecici('GİDİŞ TARİHİ', gidis, (d) => setModal(() => gidis = d)),
                const SizedBox(height: 12),
                _tarihSecici('DÖNÜŞ TARİHİ', donus, (d) => setModal(() => donus = d)),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(child: _modalInput('AVANS ₺', tryCtrl, '0', sayisal: true)),
                    const SizedBox(width: 12),
                    Expanded(child: _modalInput('AVANS \$', usdCtrl, '0', sayisal: true)),
                  ],
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(ctx, false),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Color(0xFF30363D)),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text('İPTAL', style: TextStyle(color: Color(0xFF8B949E), fontWeight: FontWeight.w900)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(ctx, true),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF16A34A),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text('OLUŞTUR', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );

    if (onay != true) return;

    final ad = adCtrl.text.trim();
    if (ad.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Form adı gerekli')),
      );
      return;
    }

    try {
      final id = 'f${DateTime.now().millisecondsSinceEpoch}';
      final h = Harcama(
        id: id,
        ad: ad,
        tarih: gidis.toIso8601String().substring(0, 10),
        donusTarih: donus.toIso8601String().substring(0, 10),
        acilisTry: double.tryParse(tryCtrl.text) ?? 0,
        acilisUsd: double.tryParse(usdCtrl.text) ?? 0,
        islemler: const [],
        olusturma: DateTime.now().toIso8601String(),
      );

      await FirestoreService.harcamaKaydet(h);
      await _yukle();

      if (mounted) {
        _acDetay(h);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Kayıt hatası: $e')),
        );
      }
    }
  }

  Widget _modalInput(String baslik, TextEditingController ctrl, String hint, {bool sayisal = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF010409),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF30363D)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(baslik, style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w800, letterSpacing: 1, color: Color(0xFF8B949E))),
          const SizedBox(height: 4),
          TextField(
            controller: ctrl,
            keyboardType: sayisal ? const TextInputType.numberWithOptions(decimal: true) : TextInputType.text,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFF58A6FF)),
            decoration: InputDecoration(
              border: InputBorder.none,
              isDense: true,
              contentPadding: EdgeInsets.zero,
              hintText: hint,
              hintStyle: const TextStyle(color: Color(0xFF6E7681), fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  Widget _tarihSecici(String baslik, DateTime tarih, Function(DateTime) onSec) {
    return GestureDetector(
      onTap: () async {
        final secili = await showDatePicker(
          context: context,
          initialDate: tarih,
          firstDate: DateTime(2020),
          lastDate: DateTime(2100),
          locale: const Locale('tr', 'TR'), 
          builder: (ctx, child) => Theme(
            data: Theme.of(ctx).copyWith(
              colorScheme: const ColorScheme.dark(
                primary: Color(0xFF2F81F7),
                surface: Color(0xFF0D1117),
              ),
            ),
            child: child!,
          ),
        );
        if (secili != null) onSec(secili);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFF010409),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFF30363D)),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(baslik, style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w800, letterSpacing: 1, color: Color(0xFF8B949E))),
                  const SizedBox(height: 4),
                  Text(
                    '${tarih.day.toString().padLeft(2, '0')} ${_ayAdi(tarih.month)} ${tarih.year}',
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF58A6FF)),
                  ),
                ],
              ),
            ),
            const Icon(Icons.calendar_today, size: 18, color: Color(0xFF58A6FF)),
          ],
        ),
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
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              const SizedBox(height: 20),
              _baslik(),
              const SizedBox(height: 20),
              _yeniFormButonu(),
              const SizedBox(height: 16),
              if (_yukleniyor)
                const Padding(
                  padding: EdgeInsets.all(40),
                  child: Center(child: CircularProgressIndicator(color: Color(0xFF58A6FF))),
                )
              else if (_hata != null)
                _hataWidget()
              else if (_formlar.isEmpty)
                _bosDurum()
              else
                ..._formlar.map((h) => _formKarti(h)),
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
              TextSpan(text: 'HARCAMA'),
              TextSpan(text: ' FORMLARI', style: TextStyle(color: Color(0xFF2F81F7))),
            ],
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'SEYAHAT & MASRAF TAKİBİ',
          style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 3, color: Color(0xFF2F81F7)),
        ),
      ],
    );
  }

  Widget _yeniFormButonu() {
    return SizedBox(
      height: 56,
      child: ElevatedButton.icon(
        onPressed: _yeniFormModal,
        icon: const Icon(Icons.add),
        label: const Text(
          'YENİ FORM OLUŞTUR',
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900, letterSpacing: 1.5),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF2F81F7),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
      ),
    );
  }

  Widget _formKarti(Harcama h) {
    final b = h.bakiyeHesapla();
    final sonIslem = h.islemler.isNotEmpty ? _tarihGoster(h.islemler.last.tarih) : 'işlem yok';

    return GestureDetector(
      onTap: () => _acDetay(h),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF0D1117),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFF30363D)),
        ),
        child: Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        h.ad,
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.5,
                          color: Color(0xFF58A6FF),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        h.donusTarih.isNotEmpty
                            ? '${_tarihGoster(h.tarih)} → ${_tarihGoster(h.donusTarih)}'
                            : _tarihGoster(h.tarih),
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.5,
                          color: Color(0xFF8B949E),
                        ),
                      ),
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: () => _silOnay(h),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF87171).withOpacity(0.08),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFF87171).withOpacity(0.25)),
                    ),
                    child: const Text(
                      'SİL',
                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Color(0xFFF87171)),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Divider(color: Color(0xFF21262D), height: 1),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('₺ BAKİYE', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800, letterSpacing: 1, color: Color(0xFF8B949E))),
                      const SizedBox(height: 2),
                      Text(
                        '₺${_fmt(b.tryBal)}',
                        style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900, color: Colors.white),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      const Text('\$ BAKİYE', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800, letterSpacing: 1, color: Color(0xFF8B949E))),
                      const SizedBox(height: 2),
                      Text(
                        '\$${_fmt(b.usdBal, dec: 2)}',
                        style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900, color: Color(0xFF4ADE80)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Divider(color: Color(0xFF21262D), height: 1),
            const SizedBox(height: 8),
            Text(
              '${h.islemler.length} işlem · Son: $sonIslem',
              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Color(0xFF6E7681)),
            ),
          ],
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
          Text('🧾', style: TextStyle(fontSize: 48)),
          SizedBox(height: 12),
          Text(
            'Henüz harcama formu yok',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF8B949E)),
          ),
          SizedBox(height: 8),
          Text(
            'Yukarıdaki butondan yeni form oluştur',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 11, color: Color(0xFF6E7681)),
          ),
        ],
      ),
    );
  }

  Widget _hataWidget() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF0D1117),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF87171).withOpacity(0.3)),
      ),
      child: Column(
        children: [
          const Icon(Icons.error_outline, color: Color(0xFFF87171), size: 48),
          const SizedBox(height: 12),
          Text(_hata!, textAlign: TextAlign.center, style: const TextStyle(color: Color(0xFFF87171))),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _yukle,
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2F81F7)),
            child: const Text('TEKRAR DENE'),
          ),
        ],
      ),
    );
  }
}