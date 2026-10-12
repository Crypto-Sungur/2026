import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

class DeviceService {
  static const String _keyDeviceId = 'sungur_device_id';
  static String? _cachedId;

  /// Cihaz için benzersiz bir ID döndürür.
  /// İlk çağrıda üretir ve SharedPreferences'e kaydeder.
  /// Sonraki çağrılarda aynı ID'yi döndürür.
  static Future<String> getDeviceId() async {
    if (_cachedId != null) return _cachedId!;

    final prefs = await SharedPreferences.getInstance();
    String? id = prefs.getString(_keyDeviceId);

    if (id == null || id.isEmpty) {
      id = await _generateDeviceId();
      await prefs.setString(_keyDeviceId, id);
    }

    _cachedId = id;
    return id;
  }

  /// Cihaz bilgilerinden benzersiz bir ID üretir.
  /// Aynı cihazda her zaman aynı ID'yi verir.
  static Future<String> _generateDeviceId() async {
    final deviceInfo = DeviceInfoPlugin();
    String raw = '';

    try {
      if (Platform.isAndroid) {
        final androidInfo = await deviceInfo.androidInfo;
        // Android ID cihaza özel, fabrika sıfırlamada değişir
        raw = 'android_${androidInfo.id}_${androidInfo.model}_${androidInfo.brand}';
      } else if (Platform.isIOS) {
        final iosInfo = await deviceInfo.iosInfo;
        // identifierForVendor iOS cihaza özel
        raw = 'ios_${iosInfo.identifierForVendor}_${iosInfo.model}';
      } else if (Platform.isWindows) {
        final winInfo = await deviceInfo.windowsInfo;
        raw = 'windows_${winInfo.deviceId}_${winInfo.computerName}';
      } else if (Platform.isMacOS) {
        final macInfo = await deviceInfo.macOsInfo;
        raw = 'macos_${macInfo.systemGUID}_${macInfo.computerName}';
      } else if (Platform.isLinux) {
        final linuxInfo = await deviceInfo.linuxInfo;
        raw = 'linux_${linuxInfo.machineId}_${linuxInfo.name}';
      } else {
        raw = 'unknown_${DateTime.now().millisecondsSinceEpoch}';
      }
    } catch (e) {
      // Hata olursa rastgele UUID üret
      raw = 'fallback_${const Uuid().v4()}';
    }

    // Raw string'i kısaltıp güvenli hale getir (Firestore key kuralları)
    return _sanitize(raw);
  }

  /// Firestore'da doküman ID olarak kullanılabilecek hale getirir.
  /// Sadece harf, rakam, tire ve alt çizgi bırakır.
  static String _sanitize(String input) {
    return input
        .replaceAll(RegExp(r'[^a-zA-Z0-9_\-]'), '_')
        .replaceAll(RegExp(r'_+'), '_')
        .substring(0, input.length > 100 ? 100 : input.length);
  }

  /// Kullanıcının cihaz ID'sini sıfırlar (test için).
  static Future<void> resetDeviceId() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyDeviceId);
    _cachedId = null;
  }

  /// Kısa ID gösterir (UI'da göstermek için).
  static Future<String> getShortDeviceId() async {
    final id = await getDeviceId();
    if (id.length <= 12) return id;
    return '${id.substring(0, 6)}...${id.substring(id.length - 6)}';
  }
}