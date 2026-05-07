import 'package:flutter_test/flutter_test.dart';

import 'package:alyak/core/services/product_search_links.dart';

void main() {
  group('search link builders', () {
    test('naverShoppingUrl encodes Korean queries', () {
      final url = naverShoppingUrl('센트룸 우먼');
      expect(url,
          startsWith('https://search.shopping.naver.com/search/all?query='));
      // Korean characters must be percent-encoded.
      expect(url, contains('%'));
      expect(url, isNot(contains(' ')));
    });

    test('coupangSearchUrl encodes Korean queries', () {
      final url = coupangSearchUrl('노르딕 오메가-3');
      expect(url, startsWith('https://www.coupang.com/np/search?q='));
      expect(url, isNot(contains(' ')));
    });

    test('naverShoppingUrl handles ASCII query (form-encoded space)', () {
      // Uri.encodeQueryComponent uses `+` for spaces — both naver and
      // coupang accept this form-encoded variant.
      expect(naverShoppingUrl('Centrum Women'),
          'https://search.shopping.naver.com/search/all?query=Centrum+Women');
    });

    test('coupangSearchUrl handles ASCII query (form-encoded space)', () {
      expect(coupangSearchUrl('Centrum Women'),
          'https://www.coupang.com/np/search?q=Centrum+Women');
    });
  });

  group('isDeadSourceUrl — broken-source domain denylist', () {
    test('null / empty → true (no source to render)', () {
      expect(isDeadSourceUrl(null), isTrue);
      expect(isDeadSourceUrl(''), isTrue);
    });

    test('malformed URL → true', () {
      expect(isDeadSourceUrl('not a url at all'), isTrue);
    });

    test('centrum.pchkorea.co.kr (DNS dead) → true', () {
      expect(
        isDeadSourceUrl(
            'https://centrum.pchkorea.co.kr/product/centrum-for-men'),
        isTrue,
      );
      expect(isDeadSourceUrl('https://centrum.pchkorea.co.kr/'), isTrue);
    });

    test('subdomain of dead host → true', () {
      expect(isDeadSourceUrl('https://www.pchkorea.co.kr/x'), isTrue);
    });

    test('healthy host (health.kr) → false', () {
      expect(
        isDeadSourceUrl(
            'https://www.health.kr/searchDrug/result_drug.asp?drug_cd=A11AOOOOO0627'),
        isFalse,
      );
    });

    test('host case-insensitive match', () {
      expect(
        isDeadSourceUrl('https://CENTRUM.PCHKOREA.CO.KR/product/x'),
        isTrue,
      );
    });
  });
}
