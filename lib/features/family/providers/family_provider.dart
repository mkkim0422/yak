import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/data/models/family_input.dart';
import '../models/family_member.dart';

/// Lightweight state container for the family roster.
/// Persistence to SecureStorage is handled by the onboarding/family-management
/// flows; this provider keeps an in-memory list ordered by entry index so the
/// home cards section can render deterministically.
class FamilyState {
  final List<FamilyMember> members;

  const FamilyState({this.members = const []});

  FamilyMember? getMember(String id) {
    for (final m in members) {
      if (m.id == id) return m;
    }
    return null;
  }

  FamilyState copyWith({List<FamilyMember>? members}) =>
      FamilyState(members: members ?? this.members);
}

class FamilyMembersNotifier extends StateNotifier<FamilyState> {
  FamilyMembersNotifier() : super(const FamilyState());

  void setMembers(List<FamilyMember> members) {
    state = state.copyWith(members: List.unmodifiable(members));
  }

  void addMember(FamilyMember member) {
    state = state.copyWith(members: [...state.members, member]);
  }

  void removeMember(String id) {
    state = state.copyWith(
      members: state.members.where((m) => m.id != id).toList(),
    );
  }

  void updateMember(FamilyMember updated) {
    state = state.copyWith(
      members: [
        for (final m in state.members)
          if (m.id == updated.id) updated else m,
      ],
    );
  }

  void updateInput(String id, FamilyInput input) {
    final existing = state.getMember(id);
    if (existing == null) return;
    updateMember(existing.copyWith(input: input));
  }
}

final familyProvider =
    StateNotifierProvider<FamilyMembersNotifier, FamilyState>((ref) {
  return FamilyMembersNotifier();
});
