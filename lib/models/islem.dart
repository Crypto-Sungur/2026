class Islem {
  final String tip; // 'gelir', 'gider', 'bozma'
  final String? para; // 'try', 'usd'
  final double tutar;
  final String tarih; // ISO format: '2026-01-15'
  final String aciklama;
  final String? kod; // harcama kodu (sadece gider için)
  final double? bozmaUsd; // döviz bozma için
  final double? bozmaKur; // döviz bozma için

  Islem({
    required this.tip,
    this.para,
    this.tutar = 0,
    required this.tarih,
    this.aciklama = '',
    this.kod,
    this.bozmaUsd,
    this.bozmaKur,
  });

  Map<String, dynamic> toMap() {
    return {
      'tip': tip,
      if (para != null) 'para': para,
      'tutar': tutar,
      'tarih': tarih,
      'aciklama': aciklama,
      if (kod != null) 'kod': kod,
      if (bozmaUsd != null) 'bozmaUsd': bozmaUsd,
      if (bozmaKur != null) 'bozmaKur': bozmaKur,
    };
  }

  factory Islem.fromMap(Map<String, dynamic> map) {
    return Islem(
      tip: map['tip'] ?? 'gelir',
      para: map['para'],
      tutar: (map['tutar'] ?? 0).toDouble(),
      tarih: map['tarih'] ?? '',
      aciklama: map['aciklama'] ?? '',
      kod: map['kod'],
      bozmaUsd: map['bozmaUsd'] != null ? (map['bozmaUsd']).toDouble() : null,
      bozmaKur: map['bozmaKur'] != null ? (map['bozmaKur']).toDouble() : null,
    );
  }

  /// Görüntüleme için tutar metni
  String get tutarGoster {
    final sembol = para == 'usd' ? '\$' : '₺';
    final isaret = tip == 'gider' ? '-' : (tip == 'gelir' ? '+' : '');
    return '$isaret$sembol${tutar.toStringAsFixed(2)}';
  }
}