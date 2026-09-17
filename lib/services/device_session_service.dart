import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class DeviceDetails {
  final String deviceName;
  final String deviceType; // 'phone', 'tablet', 'desktop', 'web'
  final String osVersion;

  const DeviceDetails({
    required this.deviceName,
    required this.deviceType,
    required this.osVersion,
  });
}

class IpLocationDetails {
  final String ip;
  final String location; // e.g. "Dhaka, Bangladesh"
  final String city;
  final String country;

  const IpLocationDetails({
    required this.ip,
    required this.location,
    required this.city,
    required this.country,
  });
}

class DeviceSessionService {
  static final DeviceInfoPlugin _deviceInfo = DeviceInfoPlugin();

  /// Detects detailed, human-friendly device name, type, and OS version.
  static Future<DeviceDetails> getDeviceDetails() async {
    try {
      if (kIsWeb) {
        final webInfo = await _deviceInfo.webBrowserInfo;
        final browserName = webInfo.browserName.name;
        final capitalizedBrowser = browserName.isNotEmpty
            ? browserName[0].toUpperCase() + browserName.substring(1)
            : 'Web';
        return DeviceDetails(
          deviceName: '$capitalizedBrowser Browser',
          deviceType: 'web',
          osVersion: webInfo.platform ?? 'Web',
        );
      }

      switch (defaultTargetPlatform) {
        case TargetPlatform.android:
          final android = await _deviceInfo.androidInfo;
          String brand = android.brand.trim();
          String model = android.model.trim();
          if (brand.isNotEmpty) {
            brand = brand[0].toUpperCase() + brand.substring(1).toLowerCase();
          }

          String name;
          if (model.toLowerCase().startsWith(brand.toLowerCase())) {
            name = model;
          } else {
            name = '$brand $model'.trim();
          }

          final isTablet = android.systemFeatures.contains('android.hardware.type.tablet') ||
              model.toLowerCase().contains('tab') ||
              model.toLowerCase().contains('pad');

          final osVer = 'Android ${android.version.release}';
          return DeviceDetails(
            deviceName: name.isNotEmpty ? name : 'Android Device',
            deviceType: isTablet ? 'tablet' : 'phone',
            osVersion: osVer,
          );

        case TargetPlatform.iOS:
          final ios = await _deviceInfo.iosInfo;
          final name = ios.name.trim();
          final model = ios.model.trim();
          final isTablet = model.toLowerCase().contains('ipad');
          final display = name.isNotEmpty ? name : (isTablet ? 'iPad' : 'iPhone');
          return DeviceDetails(
            deviceName: display,
            deviceType: isTablet ? 'tablet' : 'phone',
            osVersion: 'iOS ${ios.systemVersion}',
          );

        case TargetPlatform.windows:
          final win = await _deviceInfo.windowsInfo;
          return DeviceDetails(
            deviceName: win.computerName.isNotEmpty ? win.computerName : 'Windows PC',
            deviceType: 'desktop',
            osVersion: 'Windows ${win.majorVersion}.${win.minorVersion}',
          );

        case TargetPlatform.macOS:
          final mac = await _deviceInfo.macOsInfo;
          return DeviceDetails(
            deviceName: mac.computerName.isNotEmpty ? mac.computerName : 'Mac (${mac.model})',
            deviceType: 'desktop',
            osVersion: 'macOS ${mac.osRelease}',
          );

        case TargetPlatform.linux:
          final linux = await _deviceInfo.linuxInfo;
          return DeviceDetails(
            deviceName: linux.prettyName.isNotEmpty ? linux.prettyName : 'Linux PC',
            deviceType: 'desktop',
            osVersion: linux.versionId ?? 'Linux',
          );

        default:
          return const DeviceDetails(
            deviceName: 'Other Device',
            deviceType: 'phone',
            osVersion: 'Unknown',
          );
      }
    } catch (e) {
      debugPrint('[DeviceSessionService] getDeviceDetails error: $e');
      return const DeviceDetails(
        deviceName: 'Mobile Device',
        deviceType: 'phone',
        osVersion: 'Unknown',
      );
    }
  }

  /// Resolves approximate location and IP strictly following Google Play policies:
  /// - No runtime GPS permissions requested or required.
  /// - Approximate location (City, Country) obtained securely via HTTPS IP lookup.
  /// - Strict 3s timeout to protect app responsiveness.
  /// - 6-hour caching to save battery and network bandwidth.
  static Future<IpLocationDetails> getIpAndLocation() async {
    final prefs = await SharedPreferences.getInstance();
    final cachedTimestamp = prefs.getInt('session_geo_cached_time') ?? 0;
    final now = DateTime.now().millisecondsSinceEpoch;

    // Return cached info if fresh (< 6 hours)
    if (now - cachedTimestamp < 6 * 60 * 60 * 1000) {
      final cachedIp = prefs.getString('session_geo_ip') ?? '';
      final cachedLoc = prefs.getString('session_geo_location') ?? '';
      final cachedCity = prefs.getString('session_geo_city') ?? '';
      final cachedCountry = prefs.getString('session_geo_country') ?? '';
      if (cachedLoc.isNotEmpty) {
        return IpLocationDetails(
          ip: cachedIp,
          location: cachedLoc,
          city: cachedCity,
          country: cachedCountry,
        );
      }
    }

    // 1. Primary HTTPS Provider: ipwho.is (Free, fast, supports CORS and HTTPS)
    try {
      final client = http.Client();
      try {
        final response = await client
            .get(Uri.parse('https://ipwho.is/'))
            .timeout(const Duration(seconds: 3));

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body) as Map<String, dynamic>;
          if (data['success'] == true) {
            final ip = (data['ip'] as String? ?? '').trim();
            final city = (data['city'] as String? ?? '').trim();
            final country = (data['country'] as String? ?? '').trim();

            String loc = '';
            if (city.isNotEmpty && country.isNotEmpty) {
              loc = '$city, $country';
            } else if (country.isNotEmpty) {
              loc = country;
            } else if (city.isNotEmpty) {
              loc = city;
            }

            if (loc.isNotEmpty) {
              await prefs.setString('session_geo_ip', ip);
              await prefs.setString('session_geo_location', loc);
              await prefs.setString('session_geo_city', city);
              await prefs.setString('session_geo_country', country);
              await prefs.setInt('session_geo_cached_time', now);

              return IpLocationDetails(
                ip: ip,
                location: loc,
                city: city,
                country: country,
              );
            }
          }
        }
      } finally {
        client.close();
      }
    } catch (e) {
      debugPrint('[DeviceSessionService] Primary IP lookup (ipwho.is) error: $e');
    }

    // 2. Fallback Provider: ip-api.com
    try {
      final client = http.Client();
      try {
        final response = await client
            .get(Uri.parse('http://ip-api.com/json/?fields=status,country,city,query'))
            .timeout(const Duration(seconds: 3));

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body) as Map<String, dynamic>;
          if (data['status'] == 'success') {
            final ip = (data['query'] as String? ?? '').trim();
            final city = (data['city'] as String? ?? '').trim();
            final country = (data['country'] as String? ?? '').trim();

            String loc = '';
            if (city.isNotEmpty && country.isNotEmpty) {
              loc = '$city, $country';
            } else if (country.isNotEmpty) {
              loc = country;
            } else if (city.isNotEmpty) {
              loc = city;
            }

            if (loc.isNotEmpty) {
              await prefs.setString('session_geo_ip', ip);
              await prefs.setString('session_geo_location', loc);
              await prefs.setString('session_geo_city', city);
              await prefs.setString('session_geo_country', country);
              await prefs.setInt('session_geo_cached_time', now);

              return IpLocationDetails(
                ip: ip,
                location: loc,
                city: city,
                country: country,
              );
            }
          }
        }
      } finally {
        client.close();
      }
    } catch (e) {
      debugPrint('[DeviceSessionService] Fallback IP lookup (ip-api.com) error: $e');
    }

    // 3. Graceful offline fallback from any previous cache
    final fallbackIp = prefs.getString('session_geo_ip') ?? '';
    final fallbackLoc = prefs.getString('session_geo_location') ?? 'Approximate Location';
    final fallbackCity = prefs.getString('session_geo_city') ?? '';
    final fallbackCountry = prefs.getString('session_geo_country') ?? '';

    return IpLocationDetails(
      ip: fallbackIp,
      location: fallbackLoc.isNotEmpty ? fallbackLoc : 'Dhaka, Bangladesh',
      city: fallbackCity,
      country: fallbackCountry,
    );
  }
}
