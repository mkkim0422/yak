import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:alyak/core/widgets/profile_avatar.dart';
import 'package:alyak/features/family/models/family_member.dart';

FamilyMember _member({String? photoPath}) {
  final now = DateTime(2026, 1, 1);
  return FamilyMember(
    id: 'm1',
    name: '테스트',
    relationship: Relationship.self,
    birthYear: DateTime.now().year - 30,
    sex: Sex.female,
    profileImagePath: photoPath,
    createdAt: now,
    updatedAt: now,
  );
}

void main() {
  group('ProfileAvatar', () {
    testWidgets('null path → renders relationship emoji fallback',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: ProfileAvatar(member: _member(), size: 60)),
        ),
      );
      expect(find.text('👤'), findsOneWidget);
    });

    testWidgets('non-existent path → falls back to emoji', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ProfileAvatar(
              member: _member(photoPath: '/nope/does/not/exist.jpg'),
              size: 60,
            ),
          ),
        ),
      );
      expect(find.text('👤'), findsOneWidget);
    });

    testWidgets('showEditHint=true draws a camera badge overlay',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ProfileAvatar(
              member: _member(),
              size: 60,
              showEditHint: true,
            ),
          ),
        ),
      );
      expect(find.byIcon(Icons.camera_alt_rounded), findsOneWidget);
    });

    testWidgets('showEditHint=false omits the camera badge',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ProfileAvatar(member: _member(), size: 60),
          ),
        ),
      );
      expect(find.byIcon(Icons.camera_alt_rounded), findsNothing);
    });
  });
}
