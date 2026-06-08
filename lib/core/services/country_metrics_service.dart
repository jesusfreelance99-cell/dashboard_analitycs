import 'package:cloud_firestore/cloud_firestore.dart';

class CountryEntry {
  final String name;
  final String flag;
  final int count;
  final double fraction;
  final String percent;

  const CountryEntry({
    required this.name,
    required this.flag,
    required this.count,
    required this.fraction,
    required this.percent,
  });
}

class CountryMetricsService {
  static final _db = FirebaseFirestore.instance;

  static Future<List<CountryEntry>>? _future;

  static Future<List<CountryEntry>> get future => _future ??= _load();

  static void refresh() => _future = null;

  static Future<List<CountryEntry>> _load() async {
    try {
      final snap = await _db.collection('users').limit(10000).get();
      final names = <String>[];

      for (final doc in snap.docs) {
        final data = doc.data();
        // address puede no existir o ser null
        final address = data['address'];
        if (address is! Map) {
          names.add('');
          continue;
        }
        final raw = address['country'];
        final name = (raw is String) ? raw.trim() : '';
        names.add(name);
      }

      return _aggregate(names);
    } catch (_) {
      return [];
    }
  }

  static List<CountryEntry> _aggregate(List<String> names) {
    final counts = <String, int>{};
    for (final name in names) {
      counts[name] = (counts[name] ?? 0) + 1;
    }

    final total = names.length;
    if (total == 0) return [];

    // Separa conocidos (con nombre) de desconocidos/vacíos
    final knownEntries = counts.entries
        .where((e) => e.key.isNotEmpty)
        .toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final unknownCount = counts[''] ?? 0;

    final top3 = knownEntries.take(3).toList();
    final othersCount =
        knownEntries.skip(3).fold(unknownCount, (acc, e) => acc + e.value);

    final result = <CountryEntry>[];
    for (final entry in top3) {
      result.add(CountryEntry(
        name: entry.key,
        flag: _flagForCountry(entry.key),
        count: entry.value,
        fraction: (entry.value / total).clamp(0.0, 1.0),
        percent: '${(entry.value / total * 100).toStringAsFixed(1)}%',
      ));
    }

    if (othersCount > 0) {
      result.add(CountryEntry(
        name: 'Otros',
        flag: '🌐',
        count: othersCount,
        fraction: (othersCount / total).clamp(0.0, 1.0),
        percent: '${(othersCount / total * 100).toStringAsFixed(1)}%',
      ));
    }

    return result;
  }

  static String _flagForCountry(String name) {
    // Normaliza para comparación sin tildes ni mayúsculas
    final key = _normalize(name);
    for (final entry in _countryFlags.entries) {
      if (key.contains(entry.key)) return entry.value;
    }
    return '🌐';
  }

  static String _normalize(String s) => s
      .toLowerCase()
      .replaceAll('á', 'a')
      .replaceAll('é', 'e')
      .replaceAll('í', 'i')
      .replaceAll('ó', 'o')
      .replaceAll('ú', 'u')
      .replaceAll('ü', 'u')
      .replaceAll('ñ', 'n');

  static const Map<String, String> _countryFlags = {
    'colombia': '🇨🇴',
    'mexico': '🇲🇽',
    'estados unidos': '🇺🇸',
    'united states': '🇺🇸',
    'espana': '🇪🇸',
    'spain': '🇪🇸',
    'argentina': '🇦🇷',
    'venezuela': '🇻🇪',
    'peru': '🇵🇪',
    'chile': '🇨🇱',
    'ecuador': '🇪🇨',
    'brasil': '🇧🇷',
    'brazil': '🇧🇷',
    'panama': '🇵🇦',
    'guatemala': '🇬🇹',
    'costa rica': '🇨🇷',
    'dominicana': '🇩🇴',
    'dominican': '🇩🇴',
    'bolivia': '🇧🇴',
    'honduras': '🇭🇳',
    'nicaragua': '🇳🇮',
    'salvador': '🇸🇻',
    'paraguay': '🇵🇾',
    'uruguay': '🇺🇾',
    'cuba': '🇨🇺',
    'puerto rico': '🇵🇷',
    'canada': '🇨🇦',
  };
}
