import 'dart:io';
import 'dart:math' as math;
import 'package:docx_dart/docx_dart.dart';
import '../models/harcama.dart';
import '../models/islem.dart';

class WordService {
  // ============ YARDIMCI ============
  static String _tlFormat(double n) {
    final s = n.toStringAsFixed(2);
    final parts = s.split('.');
    final intPart = parts[0].replaceAllMapped(
      RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
      (m) => '${m[1]}.',
    );
    return '$intPart,${parts[1]}';
  }

  /// Yukarı yuvarlar ve binlik ayraç ekler.
  /// 12415.25 → 12.416
  static String _tlFormatTam(double n) {
    final yuvarlanmis = n.ceil(); // HER ZAMAN YUKARI
    return yuvarlanmis.toString().replaceAllMapped(
      RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
      (m) => '${m[1]}.',
    );
  }

  static String _tarihFormat(String t) {
    if (t.isEmpty) return '';
    try {
      final d = DateTime.parse(t);
      return '${d.day.toString().padLeft(2, '0')}.${d.month.toString().padLeft(2, '0')}.${d.year}';
    } catch (_) {
      return t;
    }
  }

  // ============ HÜCRE YAZMA (FONT BOYUTU AYARLANABİLİR) ============
  static void _hucreYaz(dynamic cell, String text, {int fontSize = 11}) {
    try {
      final paragraphs = cell.paragraphs as List;
      if (paragraphs.isEmpty) {
        cell.text = text;
        return;
      }

      final p = paragraphs.first;

      // Mevcut run'ları temizle
      try {
        final runs = p.runs as List;
        for (var i = runs.length - 1; i >= 0; i--) {
          try {
            runs[i].element.element.parent?.children.remove(
                  runs[i].element.element,
                );
          } catch (_) {}
        }
      } catch (_) {}

      // Yeni run ekle ve font boyutunu ayarla
      try {
        final run = p.addRun(text);
        try {
          run.font.size = Pt(fontSize.toDouble());
        } catch (_) {}
      } catch (_) {
        cell.text = text;
      }
    } catch (e) {
      try {
        cell.text = text;
      } catch (_) {}
    }
  }

  // ============ İŞLEM SATIRLARI ============
  static List<Map<String, dynamic>> _harcamaSatirlariOlustur(Harcama harcama) {
    final satirlar = <Map<String, dynamic>>[];
    final islemler = List<Islem>.from(harcama.islemler);

    islemler.sort((a, b) {
      final ta = DateTime.tryParse(a.tarih) ?? DateTime(1900);
      final tb = DateTime.tryParse(b.tarih) ?? DateTime(1900);
      return ta.compareTo(tb);
    });

    for (var i = 0; i < islemler.length; i++) {
      final isl = islemler[i];
      final no = i + 1;
      final tarih = _tarihFormat(isl.tarih);
      final aciklama = isl.aciklama;

      if (isl.tip == 'gider') {
        final kod = isl.kod ?? '00';
        final para = isl.para ?? 'try';
        final tutar = isl.tutar;
        // TL kuruşlu, USD tam
        final tutarStr = para == 'try'
            ? '${_tlFormat(tutar)}₺'
            : '${_tlFormatTam(tutar)}\$';
        satirlar.add({
          'no': no,
          'tarih': tarih,
          'kod': kod,
          'musteri': '',
          'konu': aciklama,
          'tutar': tutarStr,
        });
      } else if (isl.tip == 'gelir') {
        final para = isl.para ?? 'try';
        final tutar = isl.tutar;
        final tutarStr = para == 'try'
            ? '+${_tlFormat(tutar)}₺'
            : '+${_tlFormatTam(tutar)}\$';
        satirlar.add({
          'no': no,
          'tarih': tarih,
          'kod': '00',
          'musteri': '',
          'konu': aciklama.isNotEmpty ? aciklama : 'Gelir',
          'tutar': tutarStr,
        });
      } else if (isl.tip == 'bozma') {
        final usd = isl.bozmaUsd ?? 0;
        final kur = isl.bozmaKur ?? 0;
        final tl = usd * kur;
        final aciklamaTxt = aciklama.isNotEmpty ? aciklama : 'Döviz Bozdurma';
        final konu = '$aciklamaTxt - ${_tlFormatTam(usd)}\$';
        final tutarStr = '+${_tlFormat(tl)}₺';
        satirlar.add({
          'no': no,
          'tarih': tarih,
          'kod': '00',
          'musteri': '',
          'konu': konu,
          'tutar': tutarStr,
        });
      }
    }

    return satirlar;
  }

  // ============ BAKİYE ============
  static Map<String, double> _bakiyeHesapla(Harcama harcama) {
    double kalanTry = harcama.acilisTry;
    double kalanUsd = harcama.acilisUsd;

    for (final isl in harcama.islemler) {
      if (isl.tip == 'gider') {
        if (isl.para == 'try') {
          kalanTry -= isl.tutar;
        } else {
          kalanUsd -= isl.tutar;
        }
      } else if (isl.tip == 'gelir') {
        if (isl.para == 'try') {
          kalanTry += isl.tutar;
        } else {
          kalanUsd += isl.tutar;
        }
      } else if (isl.tip == 'bozma') {
        final usd = isl.bozmaUsd ?? 0;
        final kur = isl.bozmaKur ?? 0;
        kalanUsd -= usd;
        kalanTry += usd * kur;
      }
    }

    return {'try': kalanTry, 'usd': kalanUsd};
  }

  static String _iadeAciklamaOlustur(double kalanTry, double kalanUsd) {
    if (kalanTry.abs() < 0.01 && kalanUsd.abs() < 0.01) return '';

    final parcalar = <String>[];
    // TL yukarı yuvarlanmış
    if (kalanTry.abs() >= 0.01) {
      parcalar.add('${_tlFormatTam(kalanTry.abs())}₺');
    }
    // USD yukarı yuvarlanmış
    if (kalanUsd.abs() >= 0.01) {
      parcalar.add('${_tlFormatTam(kalanUsd.abs())}\$');
    }
    if (parcalar.isEmpty) return '';

    final metin = parcalar.join(' ');
    if (kalanTry.abs() >= 0.01) {
      return metin + (kalanTry > 0 ? ' şirkete iade edilmiştir.' : ' personele geri ödenecektir.');
    } else {
      return metin + (kalanUsd > 0 ? ' şirkete iade edilmiştir.' : ' personele geri ödenecektir.');
    }
  }

  // ============ ANA FONKSİYON ============
  static Future<List<String>> doldurForm({
    required String sablonYolu,
    required Harcama harcama,
    required String ciktiKlasoru,
  }) async {
    final ciktiYollari = <String>[];
    final islemSayisi = harcama.islemler.length;
    final parcaSayisi = islemSayisi <= 16 ? 1 : ((islemSayisi + 15) ~/ 16);

    for (var pi = 0; pi < parcaSayisi; pi++) {
      final baslangic = pi * 16;
      final bitis = math.min(baslangic + 16, islemSayisi);

      final parca = Harcama(
        id: harcama.id,
        ad: harcama.ad,
        tarih: harcama.tarih,
        donusTarih: harcama.donusTarih,
        acilisTry: harcama.acilisTry,
        acilisUsd: harcama.acilisUsd,
        islemler: harcama.islemler.sublist(baslangic, bitis),
        olusturma: harcama.olusturma,
      );

      final bytes = await File(sablonYolu).readAsBytes();
      final doc = loadDocxDocument(bytes);

      _doldur(
        doc: doc,
        harcama: parca,
        sonParca: pi == parcaSayisi - 1,
        genelHarcama: harcama,
      );

      final ad = harcama.ad.replaceAll('/', '-').replaceAll('\\', '-');
      final dosyaAdi = parcaSayisi == 1
          ? '$ad.docx'
          : '${ad}_file${pi + 1}.docx';
      final ciktiYolu = '$ciktiKlasoru/$dosyaAdi';

      doc.save(ciktiYolu);

      ciktiYollari.add(ciktiYolu);
    }

    return ciktiYollari;
  }

  static void _doldur({
    required Document doc,
    required Harcama harcama,
    required bool sonParca,
    required Harcama genelHarcama,
  }) {
    // TABLO 1 → Dönüş tarihi
    if (doc.tables.length > 1) {
      final t1 = doc.tables[1];
      if (t1.rows.length > 3 && t1.rows[3].cells.length > 3) {
        final donus = _tarihFormat(harcama.donusTarih);
        _hucreYaz(t1.rows[3].cells[3], donus.isNotEmpty ? ': $donus' : ':');
      }
    }

    // TABLO 3 → İşlem satırları
    if (doc.tables.length > 3) {
      final t3 = doc.tables[3];
      final satirlar = _harcamaSatirlariOlustur(harcama);

      for (var idx = 0; idx < satirlar.length && idx < 16; idx++) {
        final sat = satirlar[idx];
        final rowIdx = idx + 1;
        if (rowIdx >= t3.rows.length) break;
        final row = t3.rows[rowIdx];
        if (row.cells.length < 7) continue;

        _hucreYaz(row.cells[0], '${sat['no']}', fontSize: 9);
        _hucreYaz(row.cells[1], '${sat['tarih']}', fontSize: 9);
        _hucreYaz(row.cells[2], '${sat['kod']}', fontSize: 9);
        _hucreYaz(row.cells[3], '${sat['musteri']}', fontSize: 9);
        _hucreYaz(row.cells[4], '${sat['konu']}', fontSize: 9);
        _hucreYaz(row.cells[6], '${sat['tutar']}', fontSize: 9);
      }

      if (sonParca) {
        final bakiye = _bakiyeHesapla(genelHarcama);

        // ============ Satır 17: Harcamalar Toplamı ============
        // Format: "00.000₺ 0.000$"
        if (t3.rows.length > 17 && t3.rows[17].cells.length > 6) {
          double tgTry = 0;
          double tgUsd = 0;
          for (final isl in genelHarcama.islemler) {
            if (isl.tip == 'gider') {
              if (isl.para == 'try') {
                tgTry += isl.tutar;
              } else {
                tgUsd += isl.tutar;
              }
            }
          }
          final parcalar = <String>[];
          if (tgTry > 0) parcalar.add('-${_tlFormatTam(tgTry)}₺');
          if (tgUsd > 0) parcalar.add('-${_tlFormatTam(tgUsd)}\$');
          _hucreYaz(
            t3.rows[17].cells[6],
            parcalar.join(' '),  // ← Tek boşluk
            fontSize: 9,
          );
        }

        // ============ Satır 18: Alınan Avans ============
        // Format: "00.000₺ 0.000$"
        if (t3.rows.length > 18 && t3.rows[18].cells.length > 6) {
          final avansTry = genelHarcama.acilisTry;
          final avansUsd = genelHarcama.acilisUsd;
          _hucreYaz(
            t3.rows[18].cells[6],
            '${_tlFormatTam(avansTry)}₺ ${_tlFormatTam(avansUsd)}\$',  // ← Tek boşluk
            fontSize: 9,
          );
        }

        // ============ Satır 19: İade Edilecek ============
        // Format: "00.000₺ 0.000$"
        if (t3.rows.length > 19 && t3.rows[19].cells.length > 6) {
          final parcalar = <String>[];
          if (bakiye['try']!.abs() >= 0.01) {
            parcalar.add('${_tlFormatTam(bakiye['try']!.abs())}₺');
          }
          if (bakiye['usd']!.abs() >= 0.01) {
            parcalar.add('${_tlFormatTam(bakiye['usd']!.abs())}\$');
          }
          _hucreYaz(
            t3.rows[19].cells[6],
            parcalar.join(' '),  // ← Tek boşluk
            fontSize: 9,
          );
        }

        // ============ Tablo 5 → Açıklama ============
        if (doc.tables.length > 5) {
          final t5 = doc.tables[5];
          if (t5.rows.length > 1 && t5.rows[1].cells.length > 4) {
            final aciklama = _iadeAciklamaOlustur(bakiye['try']!, bakiye['usd']!);
            if (aciklama.isNotEmpty) {
              _hucreYaz(t5.rows[1].cells[4], aciklama, fontSize: 9);
            }
          }
        }
      }
    }
  }
}