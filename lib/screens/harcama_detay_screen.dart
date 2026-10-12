import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../services/firestore_service.dart';
import '../models/harcama.dart';
import '../models/islem.dart';
import '../services/pdf_service.dart';
import '../services/word_service.dart';

class HarcamaDetayScreen extends StatefulWidget {
  final String harcamaId;
  const HarcamaDetayScreen({super.key, required this.harcamaId});

  @override
  State<HarcamaDetayScreen> createState() => _HarcamaDetayScreenState();
}

class _HarcamaDetayScreenState extends State<HarcamaDetayScreen> {
  Harcama? _harcama;
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
      final h = await FirestoreService.harcamaGetir(widget.harcamaId);
      setState(() {
        _harcama = h;
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

  String _tarihKisa(String iso) {
    if (iso.isEmpty) return '-';
    try {
      final d = DateTime.parse(iso);
      return '${d.day.toString().padLeft(2, '0')} ${_ayKisa(d.month)} ${d.year}';
    } catch (_) {
      return iso;
    }
  }

  String _ayAdi(int ay) {
    const aylar = ['', 'Ocak', 'Şubat', 'Mart', 'Nisan', 'Mayıs', 'Haziran',
      'Temmuz', 'Ağustos', 'Eylül', 'Ekim', 'Kasım', 'Aralık'];
    return aylar[ay];
  }

  String _ayKisa(int ay) {
    const aylar = ['', 'Oca', 'Şub', 'Mar', 'Nis', 'May', 'Haz',
      'Tem', 'Ağu', 'Eyl', 'Eki', 'Kas', 'Ara'];
    return aylar[ay];
  }

  // ============ FORM AYARLARI MODAL ============
  Future<void> _formAyarlari() async {
    if (_harcama == null) return;

    final adCtrl = TextEditingController(text: _harcama!.ad);
    final tryCtrl = TextEditingController(text: _harcama!.acilisTry.toString());
    final usdCtrl = TextEditingController(text: _harcama!.acilisUsd.toString());
    DateTime gidis = DateTime.tryParse(_harcama!.tarih) ?? DateTime.now();
    DateTime donus = DateTime.tryParse(_harcama!.donusTarih) ?? DateTime.now();

    final onay = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: const Color(0xFF0D1117),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModal) => Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
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
                const Text('FORM AYARLARI', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Color(0xFF58A6FF))),
                const SizedBox(height: 4),
                const Text('DÜZENLE', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 2, color: Color(0xFF8B949E))),
                const SizedBox(height: 20),
                _modalInput('FORM ADI', adCtrl),
                const SizedBox(height: 12),
                _tarihSecici('GİDİŞ TARİHİ', gidis, (d) => setModal(() => gidis = d)),
                const SizedBox(height: 12),
                _tarihSecici('DÖNÜŞ TARİHİ', donus, (d) => setModal(() => donus = d)),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(child: _modalInput('AVANS ₺', tryCtrl, sayisal: true)),
                    const SizedBox(width: 12),
                    Expanded(child: _modalInput('AVANS \$', usdCtrl, sayisal: true)),
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
                        child: const Text('KAYDET', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900)),
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
      _snack('Form adı gerekli');
      return;
    }

    try {
      final guncellenmis = Harcama(
        id: _harcama!.id,
        ad: ad,
        tarih: gidis.toIso8601String().substring(0, 10),
        donusTarih: donus.toIso8601String().substring(0, 10),
        acilisTry: double.tryParse(tryCtrl.text) ?? 0,
        acilisUsd: double.tryParse(usdCtrl.text) ?? 0,
        islemler: _harcama!.islemler,
        olusturma: _harcama!.olusturma,
      );

      await FirestoreService.harcamaKaydet(guncellenmis);
      await _yukle();
    } catch (e) {
      _snack('Kayıt hatası: $e');
    }
  }

  Future<void> _pdfAl() async {
    if (_harcama == null) return;

    try {
      final isim = await _profilIsimGetir();
      await PdfService.harcamaPdf(
        harcama: _harcama!,
        adSoyad: isim,
      );
    } catch (e) {
      _snack('PDF hatası: $e');
    }
  }

  Future<void> _wordAl() async {
    if (_harcama == null) return;

    // Şablon seç
    final sonuc = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['docx'],
    );

    if (sonuc.isEmpty) return;

    final sablonYolu = sonuc.first.path;
    if (sablonYolu == null) {
      _snack('Şablon dosyası okunamadı');
      return;
    }

    try {
      // Geçici klasör
      final dir = await getTemporaryDirectory();

      // Word dosyalarını oluştur
      final yollar = await WordService.doldurForm(
        sablonYolu: sablonYolu,
        harcama: _harcama!,
        ciktiKlasoru: dir.path,
      );

      // Paylaş
      if (yollar.isNotEmpty) {
        final xFiles = yollar.map((y) => XFile(y)).toList();
        await SharePlus.instance.share(
          ShareParams(
            files: xFiles,
            subject: '${_harcama!.ad} - Harcama Raporu',
          ),
        );
      }
    } catch (e) {
      _snack('Word hatası: $e');
    }
  }

  Future<String> _profilIsimGetir() async {
    try {
      final p = await FirestoreService.profilGetir();
      if (p == null) return '-';
      final isim = (p['isim'] ?? '').toString();
      final soy = (p['soyisim'] ?? '').toString();
      final tam = '$isim $soy'.trim();
      return tam.isEmpty ? '-' : tam;
    } catch (_) {
      return '-';
    }
  }

  // ============ İŞLEM EKLE / DÜZENLE MODAL ============
  Future<void> _islemModal({int? duzenleIdx}) async {
    final duzenle = duzenleIdx != null ? _harcama!.islemler[duzenleIdx] : null;

    String tip = duzenle?.tip ?? 'gelir';
    String para = duzenle?.para ?? 'try';
    String? seciliKod = duzenle?.kod;

    final tutarCtrl = TextEditingController(text: duzenle != null && duzenle.tip != 'bozma' ? duzenle.tutar.toString() : '');
    final bozmaUsdCtrl = TextEditingController(text: duzenle?.bozmaUsd?.toString() ?? '');
    final bozmaKurCtrl = TextEditingController(text: duzenle?.bozmaKur?.toString() ?? '');
    final aciklamaCtrl = TextEditingController(text: duzenle?.aciklama ?? '');
    DateTime tarih = duzenle != null ? (DateTime.tryParse(duzenle.tarih) ?? DateTime.now()) : DateTime.now();

    final onay = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: const Color(0xFF0D1117),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModal) {
          return Padding(
            padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
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
                  Text(
                    duzenle == null ? 'YENİ İŞLEM' : 'İŞLEMİ DÜZENLE',
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Color(0xFF58A6FF)),
                  ),
                  const SizedBox(height: 4),
                  const Text('GELİR · GİDER · DÖVİZ', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 2, color: Color(0xFF8B949E))),
                  const SizedBox(height: 20),

                  Row(
                    children: [
                      Expanded(child: _tipButon('GELİR', 'gelir', tip, const Color(0xFF16A34A), (v) => setModal(() => tip = v))),
                      const SizedBox(width: 6),
                      Expanded(child: _tipButon('GİDER', 'gider', tip, const Color(0xFFDC2626), (v) => setModal(() => tip = v))),
                      const SizedBox(width: 6),
                      Expanded(child: _tipButon('DÖVİZ', 'bozma', tip, const Color(0xFFD97706), (v) => setModal(() => tip = v))),
                    ],
                  ),
                  const SizedBox(height: 16),

                  if (tip != 'bozma') ...[
                    const Text('PARA BİRİMİ', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800, letterSpacing: 1, color: Color(0xFF8B949E))),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Expanded(child: _paraButon('₺ TL', 'try', para, const Color(0xFF2F81F7), (v) => setModal(() => para = v))),
                        const SizedBox(width: 6),
                        Expanded(child: _paraButon('\$ USD', 'usd', para, const Color(0xFF16A34A), (v) => setModal(() => para = v))),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _modalInput('TUTAR', tutarCtrl, sayisal: true, prefix: para == 'try' ? '₺' : '\$', renk: para == 'try' ? const Color(0xFF58A6FF) : const Color(0xFF4ADE80)),
                    const SizedBox(height: 16),
                  ],

                  if (tip == 'gider') ...[
                    const Text('HARCAMA KODU', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800, letterSpacing: 1, color: Color(0xFF8B949E))),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        _kodButon('00', 'Diğer', seciliKod, (v) => setModal(() => seciliKod = v)),
                        _kodButon('01', 'Konaklama', seciliKod, (v) => setModal(() => seciliKod = v)),
                        _kodButon('02', 'Ulaşım', seciliKod, (v) => setModal(() => seciliKod = v)),
                        _kodButon('03', 'Yemek', seciliKod, (v) => setModal(() => seciliKod = v)),
                        _kodButon('06', 'Yakıt', seciliKod, (v) => setModal(() => seciliKod = v)),
                      ],
                    ),
                    const SizedBox(height: 16),
                  ],

                  if (tip == 'bozma') ...[
                    _modalInput('BOZULACAK DOLAR', bozmaUsdCtrl, sayisal: true, prefix: '\$', renk: const Color(0xFF4ADE80)),
                    const SizedBox(height: 12),
                    _modalInput('DOLAR KURU (1\$ = ? ₺)', bozmaKurCtrl, sayisal: true, prefix: '₺', renk: const Color(0xFFFBBF24)),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFD97706).withOpacity(0.08),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFD97706).withOpacity(0.3)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('ALINACAK TL', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1.5, color: Color(0xFFFBBF24))),
                          const SizedBox(height: 4),
                          Text(
                            '₺${_fmt((double.tryParse(bozmaUsdCtrl.text) ?? 0) * (double.tryParse(bozmaKurCtrl.text) ?? 0), dec: 2)}',
                            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Color(0xFFFBBF24)),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  _tarihSecici('TARİH', tarih, (d) => setModal(() => tarih = d)),
                  const SizedBox(height: 12),

                  _modalInput('AÇIKLAMA', aciklamaCtrl, maxLines: 2, hint: 'Örn: Otel, Yemek, Taksi...'),
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
                          child: Text(
                            duzenle == null ? 'KAYDET' : 'GÜNCELLE',
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );

    if (onay != true) return;

    try {
      Islem yeniIslem;

      if (tip == 'bozma') {
        final usd = double.tryParse(bozmaUsdCtrl.text) ?? 0;
        final kur = double.tryParse(bozmaKurCtrl.text) ?? 0;
        if (usd <= 0) { _snack('Dolar tutarı gerekli'); return; }
        if (kur <= 0) { _snack('Dolar kuru gerekli'); return; }

        yeniIslem = Islem(
          tip: 'bozma',
          tarih: tarih.toIso8601String().substring(0, 10),
          aciklama: aciklamaCtrl.text.trim(),
          bozmaUsd: usd,
          bozmaKur: kur,
        );
      } else {
        final tutar = double.tryParse(tutarCtrl.text) ?? 0;
        if (tutar <= 0) { _snack('Tutar gerekli'); return; }
        if (tip == 'gider' && seciliKod == null) { _snack('Harcama kodu seçin'); return; }

        yeniIslem = Islem(
          tip: tip,
          para: para,
          tutar: tutar,
          tarih: tarih.toIso8601String().substring(0, 10),
          aciklama: aciklamaCtrl.text.trim(),
          kod: tip == 'gider' ? seciliKod : null,
        );
      }

      final liste = List<Islem>.from(_harcama!.islemler);
      if (duzenleIdx != null) {
        liste[duzenleIdx] = yeniIslem;
      } else {
        liste.add(yeniIslem);
      }

      final guncellenmis = Harcama(
        id: _harcama!.id,
        ad: _harcama!.ad,
        tarih: _harcama!.tarih,
        donusTarih: _harcama!.donusTarih,
        acilisTry: _harcama!.acilisTry,
        acilisUsd: _harcama!.acilisUsd,
        islemler: liste,
        olusturma: _harcama!.olusturma,
      );

      await FirestoreService.harcamaKaydet(guncellenmis);
      await _yukle();
    } catch (e) {
      _snack('Hata: $e');
    }
  }

  Widget _tipButon(String yazi, String deger, String secili, Color renk, Function(String) onSec) {
    final aktif = deger == secili;
    return GestureDetector(
      onTap: () => onSec(deger),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          gradient: aktif
              ? LinearGradient(colors: [renk, renk.withOpacity(0.6)])
              : null,
          color: aktif ? null : const Color(0xFF010409),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: aktif ? renk : const Color(0xFF30363D)),
        ),
        child: Text(
          yazi,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w900,
            letterSpacing: 1,
            color: aktif ? Colors.white : const Color(0xFF8B949E),
          ),
        ),
      ),
    );
  }

  Widget _paraButon(String yazi, String deger, String secili, Color renk, Function(String) onSec) {
    final aktif = deger == secili;
    return GestureDetector(
      onTap: () => onSec(deger),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: aktif ? renk : const Color(0xFF010409),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: aktif ? renk : const Color(0xFF30363D)),
        ),
        child: Text(
          yazi,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w900,
            color: aktif ? Colors.white : const Color(0xFF8B949E),
          ),
        ),
      ),
    );
  }

  Widget _kodButon(String kod, String ad, String? secili, Function(String) onSec) {
    final aktif = kod == secili;
    return GestureDetector(
      onTap: () => onSec(kod),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: aktif ? const Color(0xFFDC2626) : const Color(0xFF010409),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: aktif ? const Color(0xFFDC2626) : const Color(0xFF21262D)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(kod, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: aktif ? Colors.white : const Color(0xFF8B949E))),
            Text(ad, style: TextStyle(fontSize: 8, color: aktif ? Colors.white : const Color(0xFF6E7681))),
          ],
        ),
      ),
    );
  }

  Widget _modalInput(String baslik, TextEditingController ctrl,
      {bool sayisal = false, String? prefix, Color? renk, int maxLines = 1, String? hint}) {
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
          Row(
            children: [
              if (prefix != null) ...[
                Text(prefix, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: renk ?? const Color(0xFF58A6FF))),
                const SizedBox(width: 4),
              ],
              Expanded(
                child: TextField(
                  controller: ctrl,
                  keyboardType: sayisal ? const TextInputType.numberWithOptions(decimal: true) : TextInputType.text,
                  maxLines: maxLines,
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: renk ?? const Color(0xFF58A6FF)),
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                    hintText: hint,
                    hintStyle: const TextStyle(color: Color(0xFF6E7681), fontSize: 13),
                  ),
                ),
              ),
            ],
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

  void _snack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> _islemSilOnay(int idx) async {
    final onay = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF0D1117),
        title: const Text('İşlem silinsin mi?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('İPTAL', style: TextStyle(color: Color(0xFF8B949E)))),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('SİL', style: TextStyle(color: Color(0xFFF87171)))),
        ],
      ),
    );

    if (onay != true) return;

    try {
      final liste = List<Islem>.from(_harcama!.islemler)..removeAt(idx);
      final guncellenmis = Harcama(
        id: _harcama!.id,
        ad: _harcama!.ad,
        tarih: _harcama!.tarih,
        donusTarih: _harcama!.donusTarih,
        acilisTry: _harcama!.acilisTry,
        acilisUsd: _harcama!.acilisUsd,
        islemler: liste,
        olusturma: _harcama!.olusturma,
      );
      await FirestoreService.harcamaKaydet(guncellenmis);
      await _yukle();
    } catch (e) {
      _snack('Hata: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF010409),
      body: SafeArea(
        child: _yukleniyor
            ? const Center(child: CircularProgressIndicator(color: Color(0xFF58A6FF)))
            : _hata != null
                ? Center(child: Text(_hata!, style: const TextStyle(color: Color(0xFFF87171))))
                : _harcama == null
                    ? const Center(child: Text('Form bulunamadı', style: TextStyle(color: Colors.white)))
                    : _icerik(),
      ),
    );
  }

  Widget _icerik() {
    final h = _harcama!;
    final b = h.bakiyeHesapla();

    return RefreshIndicator(
      onRefresh: _yukle,
      color: const Color(0xFF58A6FF),
      backgroundColor: const Color(0xFF161B22),
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ÜST BAR
          Row(
            children: [
              GestureDetector(
                onTap: () => Navigator.pop(context, true),
                child: Container(
                  width: 40, height: 40,
                  decoration: BoxDecoration(
                    color: const Color(0xFF161B22),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFF30363D)),
                  ),
                  child: const Icon(Icons.arrow_back, color: Color(0xFF58A6FF)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      h.ad,
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Colors.white),
                    ),
                    Text(
                      h.donusTarih.isNotEmpty
                          ? '${_tarihGoster(h.tarih)} → ${_tarihGoster(h.donusTarih)}'
                          : _tarihGoster(h.tarih),
                      style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 1, color: Color(0xFF58A6FF)),
                    ),
                  ],
                ),
              ),
              GestureDetector(
                onTap: _formAyarlari,
                child: Container(
                  width: 40, height: 40,
                  decoration: BoxDecoration(
                    color: const Color(0xFF161B22),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFF30363D)),
                  ),
                  child: const Icon(Icons.settings, color: Color(0xFF8B949E), size: 20),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // BAKİYE KARTLARI
          Row(
            children: [
              Expanded(child: _bakiyeKart('₺ BAKİYE', '₺${_fmt(b.tryBal)}', Colors.white, const Color(0xFF2F81F7))),
              const SizedBox(width: 12),
              Expanded(child: _bakiyeKart('\$ BAKİYE', '\$${_fmt(b.usdBal, dec: 2)}', const Color(0xFF4ADE80), const Color(0xFF16A34A))),
            ],
          ),
          const SizedBox(height: 12),

          // İSTATİSTİK
          Row(
            children: [
              Expanded(child: _statKart('TOP. GELİR', '₺${_fmt(b.topGelir)}', const Color(0xFF4ADE80))),
              const SizedBox(width: 8),
              Expanded(child: _statKart('TOP. GİDER', '₺${_fmt(b.topGider)}', const Color(0xFFF87171))),
              const SizedBox(width: 8),
              Expanded(child: _statKart('İŞLEM', '${h.islemler.length}', const Color(0xFF58A6FF))),
            ],
          ),
          const SizedBox(height: 16),

          // İŞLEM EKLE
          SizedBox(
            height: 54,
            child: ElevatedButton.icon(
              onPressed: () => _islemModal(),
              icon: const Icon(Icons.add),
              label: const Text('YENİ İŞLEM EKLE', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, letterSpacing: 1)),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF16A34A),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // PDF BUTONU
          SizedBox(
            height: 54,
            child: ElevatedButton.icon(
              onPressed: _pdfAl,
              icon: const Icon(Icons.picture_as_pdf),
              label: const Text(
                'PDF RAPOR OLUŞTUR',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, letterSpacing: 1),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFDB2777),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // WORD BUTONU
          SizedBox(
            height: 54,
            child: ElevatedButton.icon(
              onPressed: _wordAl,
              icon: const Icon(Icons.description),
              label: const Text(
                'WORD RAPORU OLUŞTUR',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, letterSpacing: 1),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2B579A),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
            ),
          ),
          const SizedBox(height: 20),

          // İŞLEM GEÇMİŞİ BAŞLIK
          const Text('İŞLEM GEÇMİŞİ', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 2, color: Color(0xFF8B949E))),
          const SizedBox(height: 12),

          if (h.islemler.isEmpty)
            _bosDurum()
          else
            ...List.generate(h.islemler.length, (idx) {
              final gercekIdx = h.islemler.length - 1 - idx;
              return _islemKart(h.islemler[gercekIdx], gercekIdx);
            }),
        ],
      ),
    );
  }

  Widget _bakiyeKart(String baslik, String deger, Color renk, Color kenarRenk) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [kenarRenk.withOpacity(0.12), kenarRenk.withOpacity(0.04)],
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: kenarRenk.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(baslik, style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w800, letterSpacing: 1.5, color: Color(0xFF8B949E))),
          const SizedBox(height: 4),
          Text(deger, style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, letterSpacing: -0.5, color: renk)),
        ],
      ),
    );
  }

  Widget _statKart(String baslik, String deger, Color renk) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF161B22).withOpacity(0.6),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF30363D)),
      ),
      child: Column(
        children: [
          Text(baslik, textAlign: TextAlign.center, style: const TextStyle(fontSize: 8, fontWeight: FontWeight.w800, letterSpacing: 0.5, color: Color(0xFF8B949E))),
          const SizedBox(height: 4),
          Text(deger, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: renk)),
        ],
      ),
    );
  }

  Widget _islemKart(Islem i, int idx) {
    Color renk;
    String tipAd;
    String tutarTxt;
    String? ekBilgi;

    if (i.tip == 'gelir') {
      renk = const Color(0xFF4ADE80);
      tipAd = '➕ GELİR';
      final sembol = i.para == 'usd' ? '\$' : '₺';
      tutarTxt = '+$sembol${_fmt(i.tutar, dec: 2)}';
      ekBilgi = i.aciklama.isNotEmpty ? i.aciklama : null;
    } else if (i.tip == 'gider') {
      renk = const Color(0xFFF87171);
      tipAd = '➖ GİDER';
      final sembol = i.para == 'usd' ? '\$' : '₺';
      tutarTxt = '-$sembol${_fmt(i.tutar, dec: 2)}';
      if (i.kod != null) {
        ekBilgi = '${i.kod} - ${i.aciklama.isNotEmpty ? i.aciklama : 'Diğer'}';
      } else {
        ekBilgi = i.aciklama.isNotEmpty ? i.aciklama : null;
      }
    } else {
      renk = const Color(0xFFFBBF24);
      tipAd = '💱 DÖVİZ';
      final usd = i.bozmaUsd ?? 0;
      final kur = i.bozmaKur ?? 0;
      tutarTxt = '-\$${_fmt(usd, dec: 2)} → +₺${_fmt(usd * kur)}';
      ekBilgi = 'Kur: 1\$ = ${_fmt(kur, dec: 2)}₺${i.aciklama.isNotEmpty ? ' · ${i.aciklama}' : ''}';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF0D1117),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF21262D)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(tipAd, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1, color: renk)),
                    const SizedBox(height: 2),
                    Text(_tarihKisa(i.tarih), style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Color(0xFF8B949E))),
                  ],
                ),
              ),
              Text(tutarTxt, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: renk)),
            ],
          ),
          if (ekBilgi != null) ...[
            const SizedBox(height: 6),
            Text(ekBilgi, style: TextStyle(fontSize: 11, color: renk.withOpacity(0.8), fontWeight: FontWeight.w700)),
          ],
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              _kucukButon('DÜZENLE', const Color(0xFF58A6FF), () => _islemModal(duzenleIdx: idx)),
              const SizedBox(width: 8),
              _kucukButon('SİL', const Color(0xFFF87171), () => _islemSilOnay(idx)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _kucukButon(String yazi, Color renk, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: renk.withOpacity(0.1),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: renk.withOpacity(0.3)),
        ),
        child: Text(yazi, style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 0.5, color: renk)),
      ),
    );
  }

  Widget _bosDurum() {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: const Color(0xFF161B22).withOpacity(0.5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF30363D)),
      ),
      child: const Column(
        children: [
          Text('📝', style: TextStyle(fontSize: 40)),
          SizedBox(height: 8),
          Text('Henüz işlem yok', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF8B949E))),
        ],
      ),
    );
  }
}