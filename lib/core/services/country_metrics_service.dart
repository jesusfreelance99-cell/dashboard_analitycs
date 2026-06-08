import 'package:cloud_firestore/cloud_firestore.dart';

class CountryEntry {
  final String name;
  final String flag;
  final String isoCode;
  final int count;
  final double fraction;
  final String percent;

  const CountryEntry({
    required this.name,
    required this.flag,
    required this.isoCode,
    required this.count,
    required this.fraction,
    required this.percent,
  });
}

class CountryMetricsService {
  static final _db = FirebaseFirestore.instance;

  static Map<String, int>? _rawCache;
  static Future<Map<String, int>>? _rawFuture;

  static Future<List<CountryEntry>>? _summaryFuture;
  static Future<List<CountryEntry>>? _allFuture;

  /// Top 3 + Otros — para el overview
  static Future<List<CountryEntry>> get future =>
      _summaryFuture ??= _raw().then((r) => _build(r, limit: 3));

  /// Todos ordenados por count — para la página de Usuarios
  static Future<List<CountryEntry>> get allFuture =>
      _allFuture ??= _raw().then((r) => _build(r, limit: 999));

  static List<CountryEntry> fromCounts(
    Map<String, int> counts, {
    int limit = 999,
  }) => _build(counts, limit: limit);

  static void refresh() {
    _rawCache = null;
    _rawFuture = null;
    _summaryFuture = null;
    _allFuture = null;
  }

  static Future<Map<String, int>> _raw() => _rawFuture ??= _fetchRaw();

  static Future<Map<String, int>> _fetchRaw() async {
    if (_rawCache != null) return _rawCache!;
    try {
      final snap = await _db.collection('users').limit(10000).get();
      final counts = <String, int>{};
      for (final doc in snap.docs) {
        final address = doc.data()['address'];
        final addr = address is Map
            ? address as Map<String, dynamic>
            : <String, dynamic>{};
        final name = (addr['country'] as String? ?? '').trim();
        counts[name] = (counts[name] ?? 0) + 1;
      }
      _rawCache = counts;
      return counts;
    } catch (_) {
      return {};
    }
  }

  static List<CountryEntry> _build(
    Map<String, int> counts, {
    required int limit,
  }) {
    final total = counts.values.fold(0, (a, b) => a + b);
    if (total == 0) return [];

    final known = counts.entries.where((e) => e.key.isNotEmpty).toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final unknownCount = counts[''] ?? 0;
    final top = known.take(limit).toList();
    final othersCount = known
        .skip(limit)
        .fold(unknownCount, (acc, e) => acc + e.value);

    final result = <CountryEntry>[];
    for (final e in top) {
      result.add(
        CountryEntry(
          name: e.key,
          flag: _flagFor(e.key),
          isoCode: _isoFor(e.key),
          count: e.value,
          fraction: (e.value / total).clamp(0.0, 1.0),
          percent: '${(e.value / total * 100).toStringAsFixed(1)}%',
        ),
      );
    }
    if (othersCount > 0) {
      result.add(
        CountryEntry(
          name: 'Otros',
          flag: '🌐',
          isoCode: '',
          count: othersCount,
          fraction: (othersCount / total).clamp(0.0, 1.0),
          percent: '${(othersCount / total * 100).toStringAsFixed(1)}%',
        ),
      );
    }
    return result;
  }

  static String _flagFor(String name) {
    final key = _norm(name);
    for (final entry in _flags.entries) {
      if (key.contains(entry.key)) return entry.value;
    }
    return '🌐';
  }

  static String _isoFor(String name) {
    final key = _norm(name);
    for (final entry in _isos.entries) {
      if (key.contains(entry.key)) return entry.value;
    }
    return '';
  }

  static const Map<String, String> _isos = {
    'colombia': 'CO',
    'mexico': 'MX',
    'estados unidos': 'US',
    'united states': 'US',
    'espana': 'ES',
    'spain': 'ES',
    'argentina': 'AR',
    'venezuela': 'VE',
    'peru': 'PE',
    'chile': 'CL',
    'ecuador': 'EC',
    'brasil': 'BR',
    'brazil': 'BR',
    'panama': 'PA',
    'guatemala': 'GT',
    'costa rica': 'CR',
    'dominicana': 'DO',
    'dominican': 'DO',
    'bolivia': 'BO',
    'honduras': 'HN',
    'nicaragua': 'NI',
    'salvador': 'SV',
    'paraguay': 'PY',
    'uruguay': 'UY',
    'cuba': 'CU',
    'puerto rico': 'PR',
    'canada': 'CA',
    'portugal': 'PT',
    'francia': 'FR',
    'france': 'FR',
    'alemania': 'DE',
    'germany': 'DE',
    'reino unido': 'GB',
    'united kingdom': 'GB',
    'italia': 'IT',
    'italy': 'IT',
    'irlanda': 'IE',
    'ireland': 'IE',
    'holanda': 'NL',
    'netherlands': 'NL',
    'belgica': 'BE',
    'belgium': 'BE',
    'suiza': 'CH',
    'switzerland': 'CH',
    'suecia': 'SE',
    'sweden': 'SE',
    'noruega': 'NO',
    'norway': 'NO',
    'australia': 'AU',
    'japon': 'JP',
    'japan': 'JP',
    'china': 'CN',
    'corea': 'KR',
    'korea': 'KR',
  };

  static String _norm(String s) => s
      .toLowerCase()
      .replaceAll('á', 'a')
      .replaceAll('é', 'e')
      .replaceAll('í', 'i')
      .replaceAll('ó', 'o')
      .replaceAll('ú', 'u')
      .replaceAll('ü', 'u')
      .replaceAll('ñ', 'n');

  // Mapa de keyword normalizada → emoji bandera
  static const Map<String, String> _flags = {
    //TODO: CAMBIAR POR BANDERAS DEL PAQUETE DE ICONOS O FLAGS QUE USAMOS EN USUARIOS
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
    'portugal': '🇵🇹',
    'francia': '🇫🇷',
    'france': '🇫🇷',
    'alemania': '🇩🇪',
    'germany': '🇩🇪',
    'reino unido': '🇬🇧',
    'united kingdom': '🇬🇧',
    'italia': '🇮🇹',
    'italy': '🇮🇹',
    'irlanda': '🇮🇪',
    'ireland': '🇮🇪',
  };

  // Clasificación de continente — normalizada
  static const Set<String> _america = {
    'colombia',
    'mexico',
    'estados unidos',
    'united states',
    'argentina',
    'venezuela',
    'peru',
    'chile',
    'ecuador',
    'brasil',
    'brazil',
    'panama',
    'guatemala',
    'costa rica',
    'dominicana',
    'dominican',
    'bolivia',
    'honduras',
    'nicaragua',
    'el salvador',
    'salvador',
    'paraguay',
    'uruguay',
    'cuba',
    'puerto rico',
    'canada',
  };

  static const Set<String> _europe = {
    'espana',
    'spain',
    'portugal',
    'francia',
    'france',
    'alemania',
    'germany',
    'reino unido',
    'united kingdom',
    'italia',
    'italy',
    'irlanda',
    'ireland',
    'holanda',
    'netherlands',
    'belgica',
    'belgium',
    'suiza',
    'switzerland',
    'suecia',
    'sweden',
    'noruega',
    'norway',
  };

  /// Devuelve el continente de una entrada ('América', 'Europa', 'Otros')
  static String continentOf(CountryEntry e) {
    if (e.name == 'Otros') return 'Otros';
    final key = _norm(e.name);
    if (_america.any((k) => key.contains(k))) return 'América';
    if (_europe.any((k) => key.contains(k))) return 'Europa';
    return 'Otros';
  }
}
