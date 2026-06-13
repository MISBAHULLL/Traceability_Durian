import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;

class CahyadsnRegion {
  const CahyadsnRegion({required this.code, required this.name});

  final String code;
  final String name;

  String get parentCode {
    final separator = code.lastIndexOf('.');
    return separator == -1 ? '' : code.substring(0, separator);
  }
}

class CahyadsnRegionMap {
  const CahyadsnRegionMap({
    required this.code,
    required this.name,
    required this.latitude,
    required this.longitude,
  });

  final String code;
  final String name;
  final double latitude;
  final double longitude;
}

/// A single boundary point (latitude, longitude).
class CahyadsnBoundaryPoint {
  const CahyadsnBoundaryPoint(this.latitude, this.longitude);

  final double latitude;
  final double longitude;
}

/// Boundary data for a region — consists of one or more polygon rings.
class CahyadsnRegionBoundary {
  const CahyadsnRegionBoundary({
    required this.code,
    required this.name,
    required this.latitude,
    required this.longitude,
    required this.rings,
  });

  final String code;
  final String name;
  final double latitude;
  final double longitude;

  /// List of polygon rings. Each ring is a list of [CahyadsnBoundaryPoint].
  /// The first ring is the outer boundary; subsequent rings are holes/islands.
  final List<List<CahyadsnBoundaryPoint>> rings;
}

class CahyadsnAddressLocation {
  const CahyadsnAddressLocation({
    required this.latitude,
    required this.longitude,
    required this.displayName,
  });

  final double latitude;
  final double longitude;
  final String displayName;
}

class CahyadsnRegionService {
  CahyadsnRegionService._();

  static final instance = CahyadsnRegionService._();

  final Map<String, List<CahyadsnRegion>> _children = {};
  final Map<String, CahyadsnRegionMap> _maps = {};
  final Map<String, CahyadsnRegionBoundary?> _boundaries = {};
  final Map<String, Future<void>> _boundarySources = {};
  bool _loaded = false;

  List<CahyadsnRegion> get provinces => _children[''] ?? const [];

  Future<void> load() async {
    if (_loaded) return;

    final assets = await Future.wait([
      rootBundle.loadString('assets/data/cahyadsn_wilayah.sql'),
      rootBundle.loadString('assets/data/cahyadsn_wilayah_map.txt'),
    ]);

    // ── Parse region hierarchy ──────────────────────────────────────────
    final regionPattern = RegExp(r"\('([^']+)'\s*,\s*'((?:''|[^'])*)'\)");
    for (final match in regionPattern.allMatches(assets[0])) {
      final region = CahyadsnRegion(
        code: match.group(1)!,
        name: match.group(2)!.replaceAll("''", "'"),
      );
      _children.putIfAbsent(region.parentCode, () => []).add(region);
    }

    // ── Parse coordinate map (province + city centroids) ────────────────
    final mapPattern = RegExp(
      r"^\uFEFF?\('([^']+)'\s*,\s*'((?:''|[^'])*)'\s*,\s*'((?:''|[^'])*)'\s*,\s*([-0-9.]+)\s*,\s*([-0-9.]+)",
      multiLine: true,
    );
    for (final match in mapPattern.allMatches(assets[1])) {
      final code = match.group(1)!;
      _maps[code] = CahyadsnRegionMap(
        code: code,
        name: match.group(2)!.replaceAll("''", "'"),
        latitude: double.parse(match.group(4)!),
        longitude: double.parse(match.group(5)!),
      );
    }

    for (final values in _children.values) {
      values.sort((a, b) => a.name.compareTo(b.name));
    }
    _loaded = true;
  }

  /// Loads official boundary SQL on demand and falls back to the parent when
  /// the requested village boundary is not available upstream.
  Future<CahyadsnRegionBoundary?> loadBoundaryFor(String? code) async {
    if (code == null) return null;
    var current = code;
    while (current.isNotEmpty) {
      if (_boundaries.containsKey(current)) {
        final cached = _boundaries[current];
        if (cached != null) return cached;
      } else {
        final source = _boundarySource(current);
        if (source != null) {
          await (_boundarySources[source] ??= _loadBoundarySource(source));
          final boundary = _boundaries[current];
          if (boundary != null) return boundary;
        }
        _boundaries[current] = null;
      }

      final separator = current.lastIndexOf('.');
      if (separator == -1) break;
      current = current.substring(0, separator);
    }
    return null;
  }

  Future<CahyadsnAddressLocation?> findAddress(String query) async {
    final uri = Uri.https('nominatim.openstreetmap.org', '/search', {
      'q': query,
      'format': 'jsonv2',
      'limit': '1',
      'countrycodes': 'id',
      'accept-language': 'id',
    });

    try {
      final response = await http.get(uri);
      if (response.statusCode != 200) return null;
      final results = jsonDecode(response.body);
      if (results is! List || results.isEmpty) return null;
      final result = results.first;
      if (result is! Map<String, dynamic>) return null;
      final latitude = double.tryParse('${result['lat']}');
      final longitude = double.tryParse('${result['lon']}');
      if (latitude == null || longitude == null) return null;
      return CahyadsnAddressLocation(
        latitude: latitude,
        longitude: longitude,
        displayName: '${result['display_name'] ?? query}',
      );
    } catch (_) {
      return null;
    }
  }

  String? _boundarySource(String code) {
    final parts = code.split('.');
    final province = parts.first;
    const base =
        'https://raw.githubusercontent.com/cahyadsn/'
        'wilayah_boundaries/main/db';

    return switch (parts.length) {
      1 => '$base/prov/wilayah_boundaries_prov_${_provinceGroup(province)}.sql',
      2 => '$base/kab/wilayah_boundaries_kab_$province.sql',
      3 => '$base/kec/wilayah_boundaries_kec_$province.sql',
      4 =>
        '$base/kel/$province/wilayah_boundaries_kel_${parts[0]}.${parts[1]}.sql',
      _ => null,
    };
  }

  int _provinceGroup(String province) {
    final value = int.parse(province);
    if (value <= 15) return 1;
    if (value <= 21) return 2;
    if (value <= 36) return 3;
    if (value <= 53) return 4;
    if (value <= 65) return 5;
    if (value <= 76) return 6;
    if (value <= 82) return 7;
    return 8;
  }

  Future<void> _loadBoundarySource(String source) async {
    try {
      final response = await http.get(Uri.parse(source));
      if (response.statusCode != 200) return;
      for (final rawLine in const LineSplitter().convert(response.body)) {
        final line = rawLine.trim();
        if (!line.startsWith("('")) continue;
        final boundary = _parseBoundary(line);
        if (boundary != null) _boundaries[boundary.code] = boundary;
      }
    } catch (_) {
      // Fallback to the parent boundary is handled by loadBoundaryFor.
    }
  }

  CahyadsnRegionBoundary? _parseBoundary(String line) {
    try {
      final code = _readSqlString(line, 1);
      final name = _readSqlString(line, code.$2);
      var cursor = _skipComma(line, name.$2);

      final latitudeEnd = line.indexOf(',', cursor);
      final latitude = double.parse(line.substring(cursor, latitudeEnd));
      cursor = latitudeEnd + 1;
      final longitudeEnd = line.indexOf(',', cursor);
      final longitude = double.parse(line.substring(cursor, longitudeEnd));
      final path = _readSqlString(line, longitudeEnd + 1);

      final rings = <List<CahyadsnBoundaryPoint>>[];
      _collectRings(jsonDecode(path.$1), rings);
      if (rings.isEmpty) return null;

      return CahyadsnRegionBoundary(
        code: code.$1,
        name: name.$1,
        latitude: latitude,
        longitude: longitude,
        rings: rings,
      );
    } catch (_) {
      return null;
    }
  }

  (String, int) _readSqlString(String source, int start) {
    var cursor = _skipComma(source, start);
    if (cursor >= source.length || source[cursor] != "'") {
      throw const FormatException();
    }

    final output = StringBuffer();
    cursor++;
    while (cursor < source.length) {
      if (source[cursor] != "'") {
        output.write(source[cursor++]);
      } else if (cursor + 1 < source.length && source[cursor + 1] == "'") {
        output.write("'");
        cursor += 2;
      } else {
        return (output.toString(), cursor + 1);
      }
    }
    throw const FormatException();
  }

  int _skipComma(String source, int start) {
    var cursor = start;
    while (cursor < source.length &&
        (source[cursor] == ',' || source[cursor].trim().isEmpty)) {
      cursor++;
    }
    return cursor;
  }

  void _collectRings(Object? value, List<List<CahyadsnBoundaryPoint>> output) {
    if (value is! List || value.isEmpty) return;
    final first = value.first;
    if (first is List &&
        first.length >= 2 &&
        first[0] is num &&
        first[1] is num) {
      final points = value
          .whereType<List>()
          .where((point) => point.length >= 2)
          .map(
            (point) => CahyadsnBoundaryPoint(
              (point[0] as num).toDouble(),
              (point[1] as num).toDouble(),
            ),
          )
          .toList(growable: false);
      if (points.length >= 3) output.add(_sampleRing(points));
      return;
    }
    for (final child in value) {
      _collectRings(child, output);
    }
  }

  List<CahyadsnBoundaryPoint> _sampleRing(List<CahyadsnBoundaryPoint> points) {
    const maximumPoints = 600;
    if (points.length <= maximumPoints) return points;
    final step = (points.length / maximumPoints).ceil();
    return [
      for (var index = 0; index < points.length; index += step) points[index],
      if ((points.length - 1) % step != 0) points.last,
    ];
  }

  List<CahyadsnRegion> childrenOf(String? parentCode) {
    if (parentCode == null) return const [];
    return _children[parentCode] ?? const [];
  }

  CahyadsnRegion? findExact(List<CahyadsnRegion> options, String value) {
    final query = value.trim().toLowerCase();
    for (final option in options) {
      if (option.name.toLowerCase() == query) return option;
    }
    return null;
  }

  CahyadsnRegionMap? mapFor(String? code) => code == null ? null : _maps[code];

  /// Walks up the code hierarchy to find the nearest available coordinate.
  /// e.g. for '11.01.01.2001' (desa) → tries '11.01.01' → '11.01' → '11'.
  CahyadsnRegionMap? mapForClosest(String? code) {
    if (code == null) return null;
    var current = code;
    while (current.isNotEmpty) {
      final map = _maps[current];
      if (map != null) return map;
      final separator = current.lastIndexOf('.');
      if (separator == -1) break;
      current = current.substring(0, separator);
    }
    return null;
  }

  /// Returns the depth level of a region code.
  /// '11' = 1 (province), '11.01' = 2 (city), '11.01.01' = 3 (district),
  /// '11.01.01.2001' = 4 (village).
  static int levelOf(String code) => '.'.allMatches(code).length + 1;
}
