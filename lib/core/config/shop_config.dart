/// One purchase channel surfaced to the user.
class ShopOption {
  final String name;
  final String url;
  final String? iconAsset;
  final bool isAffiliate;
  final String? note;

  const ShopOption({
    required this.name,
    required this.url,
    this.iconAsset,
    this.isAffiliate = false,
    this.note,
  });
}

/// Search and affiliate URL builder for supplement purchase channels.
///
/// Affiliate IDs are intentionally empty placeholders during Stage 1-3.
/// They will be filled in Phase 4 when partner accounts are registered.
/// When an ID is empty the builder falls back to a regular search URL,
/// so the UI keeps working without disclosure obligations.
class ShopConfig {
  ShopConfig._();

  static const String region = 'KR';

  static const String coupangAffiliateId = '';
  static const String iherbAffiliateId = '';
  static const String naverAffiliateId = '';

  static bool get hasAnyAffiliate =>
      coupangAffiliateId.isNotEmpty ||
      iherbAffiliateId.isNotEmpty ||
      naverAffiliateId.isNotEmpty;

  static const String _affiliateNote = '구매 시 수수료를 받을 수 있어요';

  static String naverSearchUrl(String productName) {
    final encoded = Uri.encodeComponent(productName);
    return 'https://search.shopping.naver.com/search/all?query=$encoded';
  }

  static String coupangUrl(String productName) {
    final encoded = Uri.encodeComponent(productName);
    if (coupangAffiliateId.isEmpty) {
      return 'https://www.coupang.com/np/search?q=$encoded';
    }
    return 'https://www.coupang.com/np/search?q=$encoded&trackId=$coupangAffiliateId';
  }

  static String iherbUrl(String productName) {
    final encoded = Uri.encodeComponent(productName);
    if (iherbAffiliateId.isEmpty) {
      return 'https://www.iherb.com/search?kw=$encoded';
    }
    return 'https://www.iherb.com/search?kw=$encoded&rcode=$iherbAffiliateId';
  }

  static List<ShopOption> getShopOptions(String productName) {
    return [
      ShopOption(
        name: '네이버 쇼핑',
        url: naverSearchUrl(productName),
        isAffiliate: naverAffiliateId.isNotEmpty,
        note: naverAffiliateId.isNotEmpty ? _affiliateNote : null,
      ),
      ShopOption(
        name: '쿠팡',
        url: coupangUrl(productName),
        isAffiliate: coupangAffiliateId.isNotEmpty,
        note: coupangAffiliateId.isNotEmpty ? _affiliateNote : null,
      ),
      ShopOption(
        name: 'iHerb',
        url: iherbUrl(productName),
        isAffiliate: iherbAffiliateId.isNotEmpty,
        note: iherbAffiliateId.isNotEmpty ? _affiliateNote : null,
      ),
    ];
  }

  /// Backward-compatible shortcut used by older call sites.
  static String searchUrl(String productName) =>
      naverSearchUrl(productName);

  /// Region-aware search URL for future global expansion.
  static String searchUrlForRegion(String productName, String regionCode) {
    final encoded = Uri.encodeComponent(productName);
    switch (regionCode) {
      case 'KR':
        return 'https://search.shopping.naver.com/search/all?query=$encoded';
      case 'JP':
        return 'https://www.amazon.co.jp/s?k=$encoded';
      case 'US':
        return 'https://www.amazon.com/s?k=$encoded supplement';
      default:
        return 'https://www.google.com/search?q=$encoded supplement';
    }
  }

  static String shopName() {
    switch (region) {
      case 'KR':
        return '네이버 쇼핑';
      case 'JP':
        return 'Amazon JP';
      case 'US':
        return 'Amazon US';
      default:
        return 'Google 쇼핑';
    }
  }
}
