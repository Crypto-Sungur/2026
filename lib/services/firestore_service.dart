import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/kayit.dart';
import '../models/harcama.dart';
import 'device_service.dart';
import 'auth_service.dart';

class FirestoreService {
  static final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ============ KULLANICI (DEVICE) KÖK YOLU ============
 static Future<DocumentReference> _userDoc() async {
  final user = AuthService.currentUser;
  if (user != null) {
    return _db.collection('users').doc(user.uid);
  }
  final deviceId = await DeviceService.getDeviceId();
  return _db.collection('users').doc(deviceId);
}

  // ============ PROFİL ============
  static Future<void> profilKaydet({
    required String isim,
    required String soyisim,
    required String maas,
  }) async {
    final userDoc = await _userDoc();
    await userDoc.collection('profil').doc('bilgi').set({
      'isim': isim,
      'soyisim': soyisim,
      'maas': maas,
      'guncelleme': FieldValue.serverTimestamp(),
    });
  }

  static Future<Map<String, dynamic>?> profilGetir() async {
    final userDoc = await _userDoc();
    final doc = await userDoc.collection('profil').doc('bilgi').get();
    if (!doc.exists) return null;
    return doc.data();
  }

  // ============ AYARLAR ============
  static Future<void> ayarlarKaydet(Map<String, dynamic> ayarlar) async {
    final userDoc = await _userDoc();
    await userDoc.collection('ayarlar').doc('ana').set({
      ...ayarlar,
      'guncelleme': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  static Future<Map<String, dynamic>?> ayarlarGetir() async {
    final userDoc = await _userDoc();
    final doc = await userDoc.collection('ayarlar').doc('ana').get();
    if (!doc.exists) return null;
    return doc.data();
  }

  // ============ KAYITLAR (Maaş Dönemleri) ============
  static Future<void> kayitKaydet(Kayit kayit) async {
    final userDoc = await _userDoc();
    final key = '${kayit.yil}_${kayit.ay.toString().padLeft(2, '0')}';
    await userDoc.collection('kayitlar').doc(key).set(kayit.toMap());
  }

  static Future<List<Kayit>> tumKayitlariGetir() async {
    final userDoc = await _userDoc();
    final snapshot = await userDoc
        .collection('kayitlar')
        .orderBy('yil', descending: true)
        .get();

    final kayitlar = snapshot.docs
        .map((doc) => Kayit.fromMap(doc.data()))
        .toList();

    // Ay bazında da sırala (yıl aynıysa ay büyükten küçüğe)
    kayitlar.sort((a, b) {
      if (a.yil != b.yil) return b.yil.compareTo(a.yil);
      return b.ay.compareTo(a.ay);
    });

    return kayitlar;
  }

  static Future<void> kayitSil(int yil, int ay) async {
    final userDoc = await _userDoc();
    final key = '${yil}_${ay.toString().padLeft(2, '0')}';
    await userDoc.collection('kayitlar').doc(key).delete();
  }

  // ============ HARCAMALAR ============
  static Future<void> harcamaKaydet(Harcama harcama) async {
    final userDoc = await _userDoc();
    await userDoc.collection('harcamalar').doc(harcama.id).set(harcama.toMap());
  }

  static Future<List<Harcama>> tumHarcamalariGetir() async {
    final userDoc = await _userDoc();
    final snapshot = await userDoc
        .collection('harcamalar')
        .orderBy('tarih', descending: true)
        .get();

    return snapshot.docs
        .map((doc) => Harcama.fromMap(doc.data()))
        .toList();
  }

  static Future<Harcama?> harcamaGetir(String id) async {
    final userDoc = await _userDoc();
    final doc = await userDoc.collection('harcamalar').doc(id).get();
    if (!doc.exists) return null;
    return Harcama.fromMap(doc.data()!);
  }

  static Future<void> harcamaSil(String id) async {
    final userDoc = await _userDoc();
    await userDoc.collection('harcamalar').doc(id).delete();
  }

  // ============ TÜM VERİYİ SİL ============
  static Future<void> tumVerileriSil() async {
    final userDoc = await _userDoc();

    // Alt koleksiyonları sil
    for (final coll in ['kayitlar', 'harcamalar', 'profil', 'ayarlar']) {
      final snapshot = await userDoc.collection(coll).get();
      for (final doc in snapshot.docs) {
        await doc.reference.delete();
      }
    }
  }

  // ============ VERİ İSTATİSTİKLERİ ============
  static Future<Map<String, int>> istatistikGetir() async {
    final userDoc = await _userDoc();

    final kayitSnap = await userDoc.collection('kayitlar').get();
    final harcamaSnap = await userDoc.collection('harcamalar').get();

    return {
      'kayitSayisi': kayitSnap.docs.length,
      'harcamaSayisi': harcamaSnap.docs.length,
    };
  }

  // ============ YEDEK / GERİ YÜKLE ============
  static Future<Map<String, dynamic>> yedekAl() async {
    final userDoc = await _userDoc();

    final profil = await userDoc.collection('profil').doc('bilgi').get();
    final ayarlar = await userDoc.collection('ayarlar').doc('ana').get();
    final kayitlarSnap = await userDoc.collection('kayitlar').get();
    final harcamalarSnap = await userDoc.collection('harcamalar').get();

    return {
      'uygulama': 'SUNGUR2026',
      'surum': 4,
      'tarih': DateTime.now().toIso8601String(),
      'profil': profil.data() ?? {},
      'ayarlar': ayarlar.data() ?? {},
      'kayitlar': {
        for (final doc in kayitlarSnap.docs) doc.id: doc.data(),
      },
      'harcamalar': {
        for (final doc in harcamalarSnap.docs) doc.id: doc.data(),
      },
    };
  }

  static Future<void> yedekYukle(Map<String, dynamic> veri) async {
    // Önce mevcut verileri sil
    await tumVerileriSil();

    final userDoc = await _userDoc();

    // Profil
    if (veri['profil'] != null && (veri['profil'] as Map).isNotEmpty) {
      await userDoc.collection('profil').doc('bilgi').set(
        Map<String, dynamic>.from(veri['profil']),
      );
    }

    // Ayarlar
    if (veri['ayarlar'] != null && (veri['ayarlar'] as Map).isNotEmpty) {
      await userDoc.collection('ayarlar').doc('ana').set(
        Map<String, dynamic>.from(veri['ayarlar']),
      );
    }

    // Kayıtlar
    if (veri['kayitlar'] != null) {
      final kayitlar = Map<String, dynamic>.from(veri['kayitlar']);
      for (final entry in kayitlar.entries) {
        await userDoc.collection('kayitlar').doc(entry.key).set(
          Map<String, dynamic>.from(entry.value),
        );
      }
    }

    // Harcamalar
    if (veri['harcamalar'] != null) {
      final harcamalar = Map<String, dynamic>.from(veri['harcamalar']);
      for (final entry in harcamalar.entries) {
        await userDoc.collection('harcamalar').doc(entry.key).set(
          Map<String, dynamic>.from(entry.value),
        );
      }
    }
  }
}