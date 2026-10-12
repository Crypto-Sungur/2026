import 'islem.dart';

class Harcama {
  final String id;
  final String ad;
  final String tarih; // '2026-01-15'
  final String donusTarih; // '2026-01-20'
  final double acilisTry;
  final double acilisUsd;
  final List<Islem> islemler;
  final String olusturma; // ISO timestamp

  Harcama({
    required this.id,
    required this.ad,
    required this.tarih,
    required this.donusTarih,
    this.acilisTry = 0,
    this.acilisUsd = 0,
    this.islemler = const [],
    required this.olusturma,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'ad': ad,
      'tarih': tarih,
      'donusTarih': donusTarih,
      'acilisTry': acilisTry,
      'acilisUsd': acilisUsd,
      'islemler': islemler.map((i) => i.toMap()).toList(),
      'olusturma': olusturma,
    };
  }

  factory Harcama.fromMap(Map<String, dynamic> map) {
    return Harcama(
      id: map['id'] ?? '',
      ad: map['ad'] ?? '',
      tarih: map['tarih'] ?? '',
      donusTarih: map['donusTarih'] ?? '',
      acilisTry: (map['acilisTry'] ?? 0).toDouble(),
      acilisUsd: (map['acilisUsd'] ?? 0).toDouble(),
      islemler: (map['islemler'] as List<dynamic>? ?? [])
          .map((e) => Islem.fromMap(Map<String, dynamic>.from(e)))
          .toList(),
      olusturma: map['olusturma'] ?? DateTime.now().toIso8601String(),
    );
  }

  /// Bakiye hesapla (HTML'deki harcamaBakiyeHesapla ile aynı)
  BakiyeSonuc bakiyeHesapla() {
    double tryBal = acilisTry;
    double usdBal = acilisUsd;
    double topGelir = 0;
    double topGider = 0;

    for (final i in islemler) {
      if (i.tip == 'gelir') {
        if (i.para == 'try') {
          tryBal += i.tutar;
        } else {
          usdBal += i.tutar;
        }
        if (i.para == 'try') topGelir += i.tutar;
      } else if (i.tip == 'gider') {
        if (i.para == 'try') {
          tryBal -= i.tutar;
        } else {
          usdBal -= i.tutar;
        }
        if (i.para == 'try') topGider += i.tutar;
      } else if (i.tip == 'bozma') {
        final usd = i.bozmaUsd ?? 0;
        final kur = i.bozmaKur ?? 0;
        usdBal -= usd;
        tryBal += usd * kur;
      }
    }

    return BakiyeSonuc(
      tryBal: tryBal,
      usdBal: usdBal,
      topGelir: topGelir,
      topGider: topGider,
    );
  }
}

class BakiyeSonuc {
  final double tryBal;
  final double usdBal;
  final double topGelir;
  final double topGider;

  BakiyeSonuc({
    required this.tryBal,
    required this.usdBal,
    required this.topGelir,
    required this.topGider,
  });
}