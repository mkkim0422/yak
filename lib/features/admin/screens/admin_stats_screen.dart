import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/manual_entry_hash.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_typography.dart';
import '../../family/models/family_member.dart';
import '../../family/providers/family_provider.dart';
import '../../supplements/providers/user_product_photo_provider.dart';
import '../../supplements/providers/user_product_review_provider.dart';

/// Admin 통계 화면. V1엔 로컬 데이터만 — 외부 전송 없음. 클라우드 카운터는
/// 단계 11 (CloudService 활성) 이후 표시 예정.
///
/// 표시 항목:
///   * 가족 멤버 수
///   * 등록 영양제 수 (큐레이션 / manual 분리)
///   * 사용자 등록 사진 수 (단계 7 활성)
///   * 사용자 후기 수 (단계 8 활성, V1 정책상 productId 당 1개라
///     indexedProductIds.length 가 곧 후기 수)
///   * 가족 구성 분포 (성별 / 연령대)
///   * manual_entry_hash 누적 카운트 — 10건+ 도달 시 강조 (V1엔 표시만,
///     승인은 V1.x 단계 13)
class AdminStatsScreen extends ConsumerWidget {
  const AdminStatsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final members = ref.watch(familyMembersProvider);
    final photoSummary = ref.watch(_adminPhotoSummaryProvider);
    final reviewIndex =
        ref.watch(_adminReviewIndexedProductIdsProvider);

    final manualEntries = members
        .expand((m) => m.manualProducts)
        .toList(growable: false);
    final curatedCount =
        members.fold<int>(0, (sum, m) => sum + m.currentProductIds.length);
    final manualCount = manualEntries.length;
    final hashCounts = _aggregateManualHashes(manualEntries);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: const Text('관리자 통계'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          _StatCard(
            title: '가족 멤버',
            value: '${members.length}명',
          ),
          _StatCard(
            title: '등록 영양제 (큐레이션)',
            value: '$curatedCount건',
            sub: '검증된 250 DB 항목 누적',
          ),
          _StatCard(
            title: '등록 영양제 (직접 입력)',
            value: '$manualCount건',
            sub: '사용자 직접 입력 항목',
          ),
          _StatCard(
            title: '사용자 등록 사진',
            value: photoSummary.when(
              data: (s) => '${s.photoCount}장 / 제품 ${s.productCount}종',
              loading: () => '계산 중…',
              error: (_, _) => '집계 실패',
            ),
            sub: '단계 7 — `<appDocs>/products/`',
          ),
          _StatCard(
            title: '사용자 후기',
            value: reviewIndex.when(
              data: (ids) => '${ids.length}건',
              loading: () => '계산 중…',
              error: (_, _) => '집계 실패',
            ),
            sub: '단계 8 — productId 당 1건 정책',
          ),
          const SizedBox(height: 8),
          _SectionHeader('가족 구성 분포'),
          _DistributionCard(members: members),
          const SizedBox(height: 8),
          _SectionHeader('manual_entry_hash 누적'),
          _ManualHashList(counts: hashCounts),
          const SizedBox(height: 16),
          Text(
            '※ V1엔 로컬 데이터 집계만. 클라우드 카운터는 단계 11 이후 표시.',
            style: AppTypography.caption.copyWith(
              fontSize: 11,
              color: AppColors.muted,
            ),
          ),
        ],
      ),
    );
  }
}

/// (productId, manualEntry) 쌍을 받아 manual_entry_hash 별 누적 카운트.
/// 키는 hash, 값은 (count, 대표 entry name).
Map<String, _HashAgg> _aggregateManualHashes(
    List<ManualProductEntry> entries) {
  final map = <String, _HashAgg>{};
  for (final e in entries) {
    final h = manualEntryHash(e);
    final cur = map[h];
    if (cur == null) {
      map[h] = _HashAgg(count: 1, name: e.name, brand: e.brand);
    } else {
      map[h] = _HashAgg(
        count: cur.count + 1,
        name: cur.name,
        brand: cur.brand,
      );
    }
  }
  return map;
}

class _HashAgg {
  final int count;
  final String name;
  final String? brand;
  const _HashAgg({required this.count, required this.name, this.brand});
}

class _PhotoSummary {
  final int productCount;
  final int photoCount;
  const _PhotoSummary({required this.productCount, required this.photoCount});
}

/// 사진 집계 — UserProductPhotoRepository 의 인덱스를 순회해 각 productId
/// 의 사진 list 길이를 합산. V1 데이터 양(수 백)에선 충분히 빠름.
final _adminPhotoSummaryProvider = FutureProvider<_PhotoSummary>((ref) async {
  final repo = ref.watch(userProductPhotoRepositoryProvider);
  final ids = await repo.indexedProductIds();
  var total = 0;
  for (final id in ids) {
    final list = await repo.listFor(id);
    total += list.length;
  }
  return _PhotoSummary(productCount: ids.length, photoCount: total);
});

final _adminReviewIndexedProductIdsProvider =
    FutureProvider<List<String>>((ref) async {
  final repo = ref.watch(userProductReviewRepositoryProvider);
  return repo.indexedProductIds();
});

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final String? sub;
  const _StatCard({required this.title, required this.value, this.sub});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.r12),
        border: Border.all(color: AppColors.divider),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: AppTypography.caption.copyWith(
                    fontSize: 12,
                    color: AppColors.muted,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (sub != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    sub!,
                    style: AppTypography.caption.copyWith(
                      fontSize: 11,
                      color: AppColors.muted,
                    ),
                  ),
                ],
              ],
            ),
          ),
          Text(
            value,
            style: AppTypography.heading2.copyWith(
              fontSize: 17,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String text;
  const _SectionHeader(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 16, 4, 8),
      child: Text(
        text,
        style: AppTypography.title.copyWith(
          fontSize: 14,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _DistributionCard extends StatelessWidget {
  final List<FamilyMember> members;
  const _DistributionCard({required this.members});

  @override
  Widget build(BuildContext context) {
    final maleCount = members.where((m) => m.sex == Sex.male).length;
    final femaleCount = members.where((m) => m.sex == Sex.female).length;
    final ageGroups = <String, int>{
      '0-12 (어린이)': 0,
      '13-19 (청소년)': 0,
      '20-39 (성인)': 0,
      '40-59 (중년)': 0,
      '60+ (시니어)': 0,
    };
    for (final m in members) {
      final a = m.age;
      if (a <= 12) {
        ageGroups['0-12 (어린이)'] = ageGroups['0-12 (어린이)']! + 1;
      } else if (a <= 19) {
        ageGroups['13-19 (청소년)'] = ageGroups['13-19 (청소년)']! + 1;
      } else if (a <= 39) {
        ageGroups['20-39 (성인)'] = ageGroups['20-39 (성인)']! + 1;
      } else if (a <= 59) {
        ageGroups['40-59 (중년)'] = ageGroups['40-59 (중년)']! + 1;
      } else {
        ageGroups['60+ (시니어)'] = ageGroups['60+ (시니어)']! + 1;
      }
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.r12),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          _kvRow('성별', '남 $maleCount명 / 여 $femaleCount명'),
          const SizedBox(height: 8),
          for (final entry in ageGroups.entries)
            _kvRow(entry.key, '${entry.value}명'),
        ],
      ),
    );
  }

  Widget _kvRow(String k, String v) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Expanded(
            child: Text(
              k,
              style: AppTypography.body2.copyWith(
                fontSize: 13,
                color: AppColors.ink2,
              ),
            ),
          ),
          Text(
            v,
            style: AppTypography.body2.copyWith(
              fontSize: 13,
              color: AppColors.ink,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _ManualHashList extends StatelessWidget {
  final Map<String, _HashAgg> counts;
  const _ManualHashList({required this.counts});

  @override
  Widget build(BuildContext context) {
    if (counts.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.r12),
          border: Border.all(color: AppColors.divider),
        ),
        child: Text(
          '직접 입력 영양제가 없어요.',
          style: AppTypography.body2.copyWith(
            fontSize: 13,
            color: AppColors.muted,
          ),
        ),
      );
    }
    final entries = counts.entries.toList()
      ..sort((a, b) => b.value.count.compareTo(a.value.count));

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.r12),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        children: [
          for (var i = 0; i < entries.length; i++) ...[
            if (i > 0) const Divider(height: 1, color: AppColors.divider),
            _ManualHashRow(hash: entries[i].key, agg: entries[i].value),
          ],
        ],
      ),
    );
  }
}

class _ManualHashRow extends StatelessWidget {
  final String hash;
  final _HashAgg agg;
  const _ManualHashRow({required this.hash, required this.agg});

  @override
  Widget build(BuildContext context) {
    final highlight = agg.count >= 10;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    if (highlight) ...[
                      const Text('🔥', style: TextStyle(fontSize: 14)),
                      const SizedBox(width: 4),
                    ],
                    Expanded(
                      child: Text(
                        agg.brand == null || agg.brand!.isEmpty
                            ? agg.name
                            : '${agg.brand} · ${agg.name}',
                        style: AppTypography.body2.copyWith(
                          fontSize: 13.5,
                          color: AppColors.ink,
                          fontWeight: highlight
                              ? FontWeight.w800
                              : FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  hash,
                  style: AppTypography.caption.copyWith(
                    fontSize: 10.5,
                    color: AppColors.muted,
                    fontFeatures: const [],
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: highlight ? AppColors.warnBg : AppColors.divider,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              '${agg.count}건',
              style: AppTypography.title.copyWith(
                fontSize: 12.5,
                color: highlight ? AppColors.warnInk : AppColors.ink2,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
