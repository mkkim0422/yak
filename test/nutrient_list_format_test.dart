import 'package:flutter_test/flutter_test.dart';

import 'package:alyak/features/home/widgets/nutrient_status_widgets.dart';

void main() {
  group('formatNutrientList', () {
    test('empty → empty string', () {
      expect(formatNutrientList(const []), '');
    });

    test('single item', () {
      expect(formatNutrientList(const ['마그네슘']), '마그네슘');
    });

    test('two items joined with comma', () {
      expect(formatNutrientList(const ['마그네슘', '아연']), '마그네슘, 아연');
    });

    test('five items still rendered fully', () {
      expect(
        formatNutrientList(const ['A', 'B', 'C', 'D', 'E']),
        'A, B, C, D, E',
      );
    });

    test('six items truncated to "외 N개"', () {
      expect(
        formatNutrientList(const ['A', 'B', 'C', 'D', 'E', 'F']),
        'A, B, C 외 3개',
      );
    });

    test('many items truncated to "외 N개"', () {
      final names = List.generate(10, (i) => 'N$i');
      expect(formatNutrientList(names), 'N0, N1, N2 외 7개');
    });
  });
}
