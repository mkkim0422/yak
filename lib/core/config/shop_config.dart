import 'region_config.dart';

/// Shopping search URL builder per region.
class ShopConfig {
  ShopConfig._();

  static String searchUrl(String name) {
    final encoded = Uri.encodeComponent(name);
    switch (RegionConfig.region) {
      case 'KR':
        return 'https://search.shopping.naver.com/search/all?query=$encoded';
      case 'JP':
        return 'https://www.amazon.co.jp/s?k=$encoded';
      case 'US':
        return 'https://www.amazon.com/s?k=$encoded';
      case 'SEA':
        return 'https://www.lazada.com/catalog/?q=$encoded';
      default:
        return 'https://www.google.com/search?q=$encoded';
    }
  }

  static String shopName() {
    switch (RegionConfig.region) {
      case 'KR':
        return '네이버 쇼핑';
      case 'JP':
        return 'Amazon JP';
      case 'US':
        return 'Amazon US';
      case 'SEA':
        return 'Lazada';
      default:
        return 'Google 쇼핑';
    }
  }
}
