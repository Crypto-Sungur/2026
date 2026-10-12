import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../models/kayit.dart';
import '../models/harcama.dart';

class PdfService {
  static const _ayAdlari = [
    '', 'Ocak', 'Şubat', 'Mart', 'Nisan', 'Mayıs', 'Haziran',
    'Temmuz', 'Ağustos', 'Eylül', 'Ekim', 'Kasım', 'Aralık'
  ];

  static pw.Font? _regular;
  static pw.Font? _bold;

  /// Fontları yükle (bir kere)
  static Future<void> _fontlariYukle() async {
    if (_regular != null && _bold != null) return;

    final regularData = await rootBundle.load('assets/fonts/Roboto-Regular.ttf');
    final boldData = await rootBundle.load('assets/fonts/Roboto-Bold.ttf');

    _regular = pw.Font.ttf(regularData);
    _bold = pw.Font.ttf(boldData);
  }

  static String _fmt(num n, {int dec = 2}) {
    final s = n.toStringAsFixed(dec);
    final parts = s.split('.');
    final intPart = parts[0].replaceAllMapped(
      RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
      (m) => '${m[1]}.',
    );
    return parts.length > 1 ? '$intPart,${parts[1]}' : intPart;
  }

  // ============ RAPOR PDF ============
  static Future<void> raporPdf({
    required List<Kayit> kayitlar,
    required String adSoyad,
    required String? seciliYil,
  }) async {
    await _fontlariYukle();

    final pdf = pw.Document();

    final toplamNet = kayitlar.fold<double>(0, (s, k) => s + k.netToplam);
    final toplamBes = kayitlar.fold<double>(0, (s, k) => s + k.besKesinti);
    final toplamHakedis = kayitlar.fold<double>(0, (s, k) => s + k.hakedis);
    final toplamEkstra = kayitlar.fold<double>(0, (s, k) => s + k.toplamEkstra);
    final simdi = DateTime.now().toIso8601String().substring(0, 19).replaceAll('T', ' ');
    final baslik = seciliYil == null
        ? 'GENEL RAPOR (TÜM YILLAR)'
        : '$seciliYil YILI RAPORU';

    final tema = pw.ThemeData.withFont(
      base: _regular,
      bold: _bold,
    );

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        theme: tema,
        build: (context) => [
          // BAŞLIK
          pw.Center(
            child: pw.Column(
              children: [
                pw.RichText(
                  text: pw.TextSpan(
                    style: pw.TextStyle(fontSize: 28, fontWeight: pw.FontWeight.bold),
                    children: [
                      const pw.TextSpan(text: 'SUNGUR'),
                      pw.TextSpan(
                        text: ' 2026',
                        style: pw.TextStyle(color: PdfColor.fromHex('#1F6FEB')),
                      ),
                    ],
                  ),
                ),
                pw.SizedBox(height: 4),
                pw.Text(
                  'AYLIK ÇALIŞMA VE KAZANÇ RAPORU',
                  style: const pw.TextStyle(fontSize: 11, letterSpacing: 2),
                ),
              ],
            ),
          ),
          pw.SizedBox(height: 8),
          pw.Divider(color: PdfColor.fromHex('#1F6FEB'), thickness: 2),
          pw.SizedBox(height: 8),
          pw.Center(
            child: pw.Text(
              baslik,
              style: pw.TextStyle(
                fontSize: 13,
                fontWeight: pw.FontWeight.bold,
                color: PdfColor.fromHex('#1F6FEB'),
                letterSpacing: 1.5,
              ),
            ),
          ),
          pw.SizedBox(height: 16),

          // BİLGİ
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text('Personel: $adSoyad', style: const pw.TextStyle(fontSize: 11)),
              pw.Text('Rapor Tarihi: $simdi', style: const pw.TextStyle(fontSize: 11)),
            ],
          ),
          pw.SizedBox(height: 16),

          // ÖZET
          pw.Row(
            children: [
              _ozetKutu('TOPLAM NET', '₺${_fmt(toplamNet)}'),
              pw.SizedBox(width: 8),
              _ozetKutu('TOPLAM HAKEDİŞ', '₺${_fmt(toplamHakedis)}'),
              pw.SizedBox(width: 8),
              _ozetKutu('TOPLAM BES', '₺${_fmt(toplamBes)}'),
              pw.SizedBox(width: 8),
              _ozetKutu('TOPLAM EKSTRA', '₺${_fmt(toplamEkstra)}'),
            ],
          ),
          pw.SizedBox(height: 20),

          // TABLO BAŞLIK
          pw.Text(
            'AYLIK DETAY',
            style: pw.TextStyle(
              fontSize: 13,
              fontWeight: pw.FontWeight.bold,
              color: PdfColor.fromHex('#1F6FEB'),
              letterSpacing: 2,
            ),
          ),
          pw.SizedBox(height: 6),
          pw.Divider(color: PdfColor.fromHex('#1F6FEB')),

          // TABLO
          pw.TableHelper.fromTextArray(
            headers: ['Dönem', 'Maaş', 'Hakediş', 'Ekstra', 'BES', 'Net'],
            data: kayitlar
                .map((k) => [
                      '${_ayAdlari[k.ay]} ${k.yil}',
                      '₺${_fmt(k.maas)}',
                      '₺${_fmt(k.hakedis)}',
                      '+₺${_fmt(k.toplamEkstra)}',
                      '-₺${_fmt(k.besKesinti)}',
                      '₺${_fmt(k.netToplam)}',
                    ])
                .toList(),
            headerStyle: pw.TextStyle(
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.white,
              fontSize: 9,
            ),
            headerDecoration: pw.BoxDecoration(
              color: PdfColor.fromHex('#1F6FEB'),
            ),
            cellStyle: const pw.TextStyle(fontSize: 9),
            cellAlignment: pw.Alignment.centerRight,
            cellAlignments: {
              0: pw.Alignment.centerLeft,
            },
            rowDecoration: const pw.BoxDecoration(
              border: pw.Border(
                bottom: pw.BorderSide(color: PdfColors.grey300, width: 0.5),
              ),
            ),
          ),
          pw.SizedBox(height: 16),

          // FOOTER
          pw.Center(
            child: pw.Text(
              'Bu rapor SUNGUR 2026 uygulaması tarafından otomatik oluşturulmuştur.\n'
              'Toplam ${kayitlar.length} dönem kaydı içerir.',
              textAlign: pw.TextAlign.center,
              style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700),
            ),
          ),
        ],
      ),
    );

    await Printing.layoutPdf(
      onLayout: (format) async => pdf.save(),
      name: 'SUNGUR_2026_Rapor.pdf',
    );
  }

  static pw.Widget _ozetKutu(String baslik, String deger) {
    return pw.Expanded(
      child: pw.Container(
        padding: const pw.EdgeInsets.all(10),
        decoration: pw.BoxDecoration(
          color: PdfColor.fromHex('#F4F6FB'),
          border: pw.Border(
            left: pw.BorderSide(color: PdfColor.fromHex('#1F6FEB'), width: 3),
          ),
          borderRadius: pw.BorderRadius.circular(4),
        ),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(baslik, style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700)),
            pw.SizedBox(height: 4),
            pw.Text(deger, style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  // ============ HARCAMA PDF ============
  static Future<void> harcamaPdf({
    required Harcama harcama,
    required String adSoyad,
  }) async {
    await _fontlariYukle();

    final pdf = pw.Document();
    final b = harcama.bakiyeHesapla();
    final simdi = DateTime.now().toIso8601String().substring(0, 19).replaceAll('T', ' ');
    final tarihStr = _tarihGoster(harcama.tarih);
    final donusStr = harcama.donusTarih.isNotEmpty ? _tarihGoster(harcama.donusTarih) : '';

    final tema = pw.ThemeData.withFont(
      base: _regular,
      bold: _bold,
    );

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        theme: tema,
        build: (context) => [
          // BAŞLIK
          pw.Center(
            child: pw.Column(
              children: [
                pw.RichText(
                  text: pw.TextSpan(
                    style: pw.TextStyle(fontSize: 28, fontWeight: pw.FontWeight.bold),
                    children: [
                      const pw.TextSpan(text: 'SUNGUR'),
                      pw.TextSpan(
                        text: ' 2026',
                        style: pw.TextStyle(color: PdfColor.fromHex('#1F6FEB')),
                      ),
                    ],
                  ),
                ),
                pw.SizedBox(height: 4),
                pw.Text(
                  'HARCAMA RAPORU',
                  style: const pw.TextStyle(fontSize: 11, letterSpacing: 2),
                ),
              ],
            ),
          ),
          pw.SizedBox(height: 8),
          pw.Divider(color: PdfColor.fromHex('#1F6FEB'), thickness: 2),
          pw.SizedBox(height: 8),

          pw.Center(
            child: pw.Text(
              harcama.ad,
              style: pw.TextStyle(
                fontSize: 16,
                fontWeight: pw.FontWeight.bold,
                color: PdfColor.fromHex('#1F6FEB'),
              ),
            ),
          ),
          pw.Center(
            child: pw.Text(
              donusStr.isNotEmpty ? '$tarihStr - $donusStr' : tarihStr,
              style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
            ),
          ),
          pw.SizedBox(height: 16),

          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text('Personel: $adSoyad', style: const pw.TextStyle(fontSize: 11)),
              pw.Text('Rapor Tarihi: $simdi', style: const pw.TextStyle(fontSize: 11)),
            ],
          ),
          pw.SizedBox(height: 16),

          // ÖZET
          pw.Row(
            children: [
              _ozetKutu('AÇILIŞ ₺ AVANS', '₺${_fmt(harcama.acilisTry)}'),
              pw.SizedBox(width: 8),
              _ozetKutu('AÇILIŞ \$ AVANS', '\$${_fmt(harcama.acilisUsd)}'),
              pw.SizedBox(width: 8),
              _ozetKutu('KALAN ₺', '₺${_fmt(b.tryBal)}'),
              pw.SizedBox(width: 8),
              _ozetKutu('KALAN \$', '\$${_fmt(b.usdBal)}'),
            ],
          ),
          pw.SizedBox(height: 20),

          // İŞLEM BAŞLIK
          pw.Text(
            'İŞLEM DETAYI',
            style: pw.TextStyle(
              fontSize: 13,
              fontWeight: pw.FontWeight.bold,
              color: PdfColor.fromHex('#1F6FEB'),
              letterSpacing: 2,
            ),
          ),
          pw.SizedBox(height: 6),
          pw.Divider(color: PdfColor.fromHex('#1F6FEB')),

          if (harcama.islemler.isEmpty)
            pw.Padding(
              padding: const pw.EdgeInsets.all(20),
              child: pw.Center(
                child: pw.Text('İşlem kaydı yok', style: const pw.TextStyle(color: PdfColors.grey600)),
              ),
            )
          else
            pw.TableHelper.fromTextArray(
              headers: ['Tarih', 'Tip', 'Tutar', 'Detay'],
              data: harcama.islemler.map((i) {
                String tipTxt = '';
                String tutarTxt = '';
                String detay = '';

                if (i.tip == 'gelir') {
                  tipTxt = 'GELİR';
                  tutarTxt = '+${i.para == 'usd' ? '\$' : '₺'}${_fmt(i.tutar)}';
                  detay = i.aciklama.isNotEmpty ? i.aciklama : '-';
                } else if (i.tip == 'gider') {
                  tipTxt = 'GİDER';
                  tutarTxt = '-${i.para == 'usd' ? '\$' : '₺'}${_fmt(i.tutar)}';
                  detay = i.kod != null
                      ? '${i.kod} - ${i.aciklama.isNotEmpty ? i.aciklama : 'Diğer'}'
                      : (i.aciklama.isNotEmpty ? i.aciklama : '-');
                } else {
                  tipTxt = 'DÖVİZ';
                  final usd = i.bozmaUsd ?? 0;
                  final kur = i.bozmaKur ?? 0;
                  tutarTxt = '-\$${_fmt(usd)} → +₺${_fmt(usd * kur)}';
                  detay = 'Kur: 1\$ = ${_fmt(kur)}₺';
                }

                return [
                  _tarihKisa(i.tarih),
                  tipTxt,
                  tutarTxt,
                  detay,
                ];
              }).toList(),
              headerStyle: pw.TextStyle(
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.white,
                fontSize: 9,
              ),
              headerDecoration: pw.BoxDecoration(
                color: PdfColor.fromHex('#1F6FEB'),
              ),
              cellStyle: const pw.TextStyle(fontSize: 9),
              rowDecoration: const pw.BoxDecoration(
                border: pw.Border(
                  bottom: pw.BorderSide(color: PdfColors.grey300, width: 0.5),
                ),
              ),
            ),

          pw.SizedBox(height: 20),

          // ÖZET TABLO
          pw.Text(
            'ÖZET',
            style: pw.TextStyle(
              fontSize: 13,
              fontWeight: pw.FontWeight.bold,
              color: PdfColor.fromHex('#1F6FEB'),
              letterSpacing: 2,
            ),
          ),
          pw.SizedBox(height: 6),
          pw.Divider(color: PdfColor.fromHex('#1F6FEB')),
          pw.Container(
            padding: const pw.EdgeInsets.all(12),
            decoration: pw.BoxDecoration(
              color: PdfColor.fromHex('#1F6FEB'),
              borderRadius: pw.BorderRadius.circular(4),
            ),
            child: pw.Column(
              children: [
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('KALAN ₺ BAKİYE', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white)),
                    pw.Text('₺${_fmt(b.tryBal)}', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white)),
                  ],
                ),
                pw.SizedBox(height: 6),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('KALAN \$ BAKİYE', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white)),
                    pw.Text('\$${_fmt(b.usdBal)}', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white)),
                  ],
                ),
              ],
            ),
          ),

          pw.SizedBox(height: 20),
          pw.Center(
            child: pw.Text(
              'Bu rapor SUNGUR 2026 uygulaması tarafından otomatik oluşturulmuştur.\n'
              '${harcama.islemler.length} işlem kaydı içerir.',
              textAlign: pw.TextAlign.center,
              style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700),
            ),
          ),
        ],
      ),
    );

    await Printing.layoutPdf(
      onLayout: (format) async => pdf.save(),
      name: '${harcama.ad}_Rapor.pdf',
    );
  }

  static String _tarihGoster(String iso) {
    if (iso.isEmpty) return '-';
    try {
      final d = DateTime.parse(iso);
      return '${d.day.toString().padLeft(2, '0')} ${_ayAdlari[d.month]} ${d.year}';
    } catch (_) {
      return iso;
    }
  }

  static String _tarihKisa(String iso) {
    if (iso.isEmpty) return '-';
    try {
      final d = DateTime.parse(iso);
      final kisa = ['', 'Oca', 'Şub', 'Mar', 'Nis', 'May', 'Haz',
        'Tem', 'Ağu', 'Eyl', 'Eki', 'Kas', 'Ara'];
      return '${d.day.toString().padLeft(2, '0')} ${kisa[d.month]} ${d.year}';
    } catch (_) {
      return iso;
    }
  }
}