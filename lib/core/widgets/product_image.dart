import 'package:flutter/material.dart';

import '../data/models/product_model.dart';
import '../theme/app_colors.dart';
import '../theme/app_radius.dart';

/// Loads `assets/images/products/{id}.jpg` if available, otherwise renders a
/// soft category-emoji placeholder. The placeholder shape matches the photo
/// box so layout never shifts.
class ProductImage extends StatelessWidget {
  final Product product;
  final double size;
  final double radius;

  const ProductImage({
    super.key,
    required this.product,
    this.size = 56,
    this.radius = AppRadius.r12,
  });

  @override
  Widget build(BuildContext context) {
    final fallback = _CategoryFallback(
      category: product.category,
      size: size,
      radius: radius,
    );
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: Image.asset(
        product.imageAssetPath,
        width: size,
        height: size,
        fit: BoxFit.cover,
        // No image bundled (script hasn't downloaded one for this id) →
        // gracefully fall back to the emoji card.
        errorBuilder: (context, error, stackTrace) => fallback,
      ),
    );
  }
}

/// Visual fallback used when no product photo is bundled. Picks a soft
/// background tint by category and a representative emoji.
class _CategoryFallback extends StatelessWidget {
  final String category;
  final double size;
  final double radius;
  const _CategoryFallback({
    required this.category,
    required this.size,
    required this.radius,
  });

  @override
  Widget build(BuildContext context) {
    final (emoji, bg) = _categoryGlyph(category);
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(radius),
      ),
      child: Text(
        emoji,
        style: TextStyle(fontSize: size * 0.45, height: 1),
      ),
    );
  }
}

(String emoji, Color bg) _categoryGlyph(String category) {
  switch (category) {
    case 'multivitamin':
      return ('💊', AppColors.primarySoft);
    case 'vitamin_b':
    case 'biotin':
      return ('🌅', const Color(0xFFFFF8E1));
    case 'vitamin_c':
      return ('🍋', const Color(0xFFFFF8E1));
    case 'vitamin_d':
    case 'kids_vitamin_d':
      return ('☀️', const Color(0xFFFFF3E0));
    case 'omega3':
    case 'krill_oil':
    case 'kids_omega3':
      return ('🐟', AppColors.primarySoft);
    case 'probiotic':
    case 'probiotics':
      return ('🦠', AppColors.okBg);
    case 'magnesium':
      return ('🌙', const Color(0xFFEDE7F6));
    case 'calcium':
      return ('🦴', AppColors.surfaceMuted);
    case 'mineral':
    case 'iron':
      return ('⛏️', AppColors.surfaceMuted);
    case 'collagen':
      return ('✨', const Color(0xFFFCE4EC));
    case 'lutein':
    case 'eye':
      return ('👁️', const Color(0xFFE3F2FD));
    case 'antioxidant':
      return ('🍇', const Color(0xFFEDE7F6));
    case 'liver':
      return ('🌿', AppColors.okBg);
    case 'joint':
      return ('🦵', AppColors.surfaceMuted);
    case 'sleep':
      return ('🌙', const Color(0xFFEDE7F6));
    case 'sports':
      return ('💪', AppColors.primarySoft);
    case 'weight':
      return ('⚖️', AppColors.surfaceMuted);
    case 'fiber':
      return ('🌾', AppColors.okBg);
    case 'circulation':
      return ('❤️', const Color(0xFFFCE4EC));
    case 'immunity':
    case 'immune':
      return ('🛡️', AppColors.okBg);
    case 'menopause_female':
    case 'menopause_male':
    case 'women_health':
    case 'men_health':
      return ('🌸', const Color(0xFFFCE4EC));
    case 'prenatal':
    case 'pregnancy':
      return ('🤰', const Color(0xFFFCE4EC));
    case 'korean_herbal':
    case 'kids_korean_herbal':
    case 'ginseng':
      return ('🌿', AppColors.okBg);
    case 'superfood':
      return ('🥬', AppColors.okBg);
    case 'kids':
    case 'kids_multivitamin':
      return ('🧒', AppColors.primarySoft);
    default:
      return ('💊', AppColors.surfaceMuted);
  }
}
