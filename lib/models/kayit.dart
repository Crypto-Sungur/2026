class Kayit {
  final double maas;
  final int ay;
  final int yil;
  final double besOran;
  final double besManuel;
  final String besMod; // 'yuzde' veya 'manuel'
  final double izin;
  final double mesaiS;
  final double sDisi;
  final double yDisi;
  final double ozelGun;
  final int gunSayisi;
  final double gunluk;
  final double saatlik;
  final double ayFarki;
  final double sehirDisiEk;
  final double yurtDisiEk;
  final double mesaiEk;
  final double ozelGunEk;
  final double hakedis;
  final double besKesinti;
  final double netToplam;
  final double toplamEkstra;
  final String maasMod; // 'manuel' veya 'profil'
  final String kayitTarihi;
  final String ayAdi;

  Kayit({
    required this.maas,
    required this.ay,
    required this.yil,
    required this.besOran,
    required this.besManuel,
    required this.besMod,
    required this.izin,
    required this.mesaiS,
    required this.sDisi,
    required this.yDisi,
    required this.ozelGun,
    required this.gunSayisi,
    required this.gunluk,
    required this.saatlik,
    required this.ayFarki,
    required this.sehirDisiEk,
    required this.yurtDisiEk,
    required this.mesaiEk,
    required this.ozelGunEk,
    required this.hakedis,
    required this.besKesinti,
    required this.netToplam,
    required this.toplamEkstra,
    required this.maasMod,
    required this.kayitTarihi,
    required this.ayAdi,
  });

  Map<String, dynamic> toMap() {
    return {
      'maas': maas,
      'ay': ay,
      'yil': yil,
      'besOran': besOran,
      'besManuel': besManuel,
      'besMod': besMod,
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
      'maasMod': maasMod,
      'kayitTarihi': kayitTarihi,
      'ayAdi': ayAdi,
    };
  }

  factory Kayit.fromMap(Map<String, dynamic> map) {
    double d(dynamic v) => (v ?? 0).toDouble();
    int i(dynamic v) => (v ?? 0).toInt();

    return Kayit(
      maas: d(map['maas']),
      ay: i(map['ay']),
      yil: i(map['yil']),
      besOran: d(map['besOran']),
      besManuel: d(map['besManuel']),
      besMod: map['besMod'] ?? 'yuzde',
      izin: d(map['izin']),
      mesaiS: d(map['mesaiS']),
      sDisi: d(map['sDisi']),
      yDisi: d(map['yDisi']),
      ozelGun: d(map['ozelGun']),
      gunSayisi: i(map['gunSayisi']),
      gunluk: d(map['gunluk']),
      saatlik: d(map['saatlik']),
      ayFarki: d(map['ayFarki']),
      sehirDisiEk: d(map['sehirDisiEk']),
      yurtDisiEk: d(map['yurtDisiEk']),
      mesaiEk: d(map['mesaiEk']),
      ozelGunEk: d(map['ozelGunEk']),
      hakedis: d(map['hakedis']),
      besKesinti: d(map['besKesinti']),
      netToplam: d(map['netToplam']),
      toplamEkstra: d(map['toplamEkstra']),
      maasMod: map['maasMod'] ?? 'manuel',
      kayitTarihi: map['kayitTarihi'] ?? '',
      ayAdi: map['ayAdi'] ?? '',
    );
  }
}