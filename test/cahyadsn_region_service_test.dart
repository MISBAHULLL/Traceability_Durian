import 'package:flutter_test/flutter_test.dart';
import 'package:traceability_durian/features/farmer/data/cahyadsn_region_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('memuat hierarki wilayah dan koordinat dari data cahyadsn', () async {
    final service = CahyadsnRegionService.instance;
    await service.load();

    expect(service.provinces.length, greaterThanOrEqualTo(38));

    final aceh = service.provinces.firstWhere((item) => item.code == '11');
    final cities = service.childrenOf(aceh.code);
    expect(cities, isNotEmpty);
    expect(service.mapFor(aceh.code), isNotNull);
    expect(service.mapFor(cities.first.code), isNotNull);
  });
}
