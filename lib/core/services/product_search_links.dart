/// Builds external search URLs (네이버 쇼핑 / 쿠팡) for a given product
/// query. Pure string functions — kept separate from the launch logic
/// so they're trivially unit-testable without `url_launcher`.
library;

String naverShoppingUrl(String query) {
  final q = Uri.encodeQueryComponent(query);
  return 'https://search.shopping.naver.com/search/all?query=$q';
}

String coupangSearchUrl(String query) {
  final q = Uri.encodeQueryComponent(query);
  return 'https://www.coupang.com/np/search?q=$q';
}
