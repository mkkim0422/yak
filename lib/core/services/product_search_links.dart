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

/// Hosts whose `data_source` URLs are known to be dead (returns DNS_NOT_FOUND
/// or 404 in the user's browser). The product detail screen suppresses the
/// "정보 출처" link when the URL belongs to one of these — the verified data
/// in the curated DB itself remains valid; only the now-defunct upstream
/// page is hidden.
///
/// Add new entries lower-case + bare host (no scheme, no path). The match
/// is suffix-based so subdomains like `www.example.com` also resolve.
const Set<String> _kDeadSourceHosts = {
  // Pfizer Korea consumer-health site for Centrum was retired; the
  // /product/* paths now fail DNS resolution.
  'centrum.pchkorea.co.kr',
  'pchkorea.co.kr',
};

/// Returns true when the URL's host is on the broken-source denylist OR the
/// URL itself is malformed. Empty / null URLs also count as unreachable so
/// callers can collapse the rendering check into one branch.
bool isDeadSourceUrl(String? url) {
  if (url == null || url.isEmpty) return true;
  final uri = Uri.tryParse(url);
  if (uri == null || uri.host.isEmpty) return true;
  final host = uri.host.toLowerCase();
  for (final dead in _kDeadSourceHosts) {
    if (host == dead || host.endsWith('.$dead')) return true;
  }
  return false;
}
