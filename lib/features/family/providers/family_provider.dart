import 'dart:async';
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/notifications/notification_provider.dart';
import '../../../core/security/secure_storage.dart';
import '../models/family_member.dart';

/// Storage layer interface so tests can inject an in-memory backing store.
abstract class FamilyStorage {
  Future<String?> read(String key);
  Future<void> write(String key, String value);
  Future<void> delete(String key);
}

class _SecureFamilyStorage implements FamilyStorage {
  const _SecureFamilyStorage();
  @override
  Future<String?> read(String key) => SecureStorage.read(key);
  @override
  Future<void> write(String key, String value) =>
      SecureStorage.write(key, value);
  @override
  Future<void> delete(String key) => SecureStorage.delete(key);
}

/// Hook used by tests to abort scheduled notification side-effects.
typedef NotificationCanceller = Future<void> Function(String memberId);

/// SecureStorage key under which the ordered list of member ids is kept.
const String kFamilyMembersListKey = 'family.members.list';
const String kFamilyMemberPrefix = 'family.member.';

class FamilyMembersNotifier extends StateNotifier<List<FamilyMember>> {
  static const String _kFamilyMembersList = kFamilyMembersListKey;
  static const String _kMemberPrefix = kFamilyMemberPrefix;

  final FamilyStorage _storage;
  final NotificationCanceller? _onMemberRemoved;
  final Completer<void> _initialized = Completer<void>();

  FamilyMembersNotifier(
    this._storage, {
    NotificationCanceller? onMemberRemoved,
  })  : _onMemberRemoved = onMemberRemoved,
        super(const []) {
    // Fire-and-forget; await via [ready] in tests.
    unawaited(_loadFromStorage());
  }

  /// Resolves once the initial load attempt has completed (success or fail).
  Future<void> get ready => _initialized.future;

  Future<void> _loadFromStorage() async {
    try {
      final indexJson = await _storage.read(_kFamilyMembersList);
      if (indexJson == null) {
        if (!_initialized.isCompleted) _initialized.complete();
        return;
      }
      final ids = (jsonDecode(indexJson) as List).cast<String>();
      final members = <FamilyMember>[];
      for (final id in ids) {
        final memberJson = await _storage.read('$_kMemberPrefix$id');
        if (memberJson == null) continue;
        try {
          members.add(
            FamilyMember.fromJson(jsonDecode(memberJson) as Map<String, dynamic>),
          );
        } catch (_) {
          // Skip individual corrupt records but keep the rest.
        }
      }
      state = members;
    } catch (_) {
      // Corrupted index — start fresh.
      state = const [];
    } finally {
      if (!_initialized.isCompleted) _initialized.complete();
    }
  }

  FamilyMember? getMember(String id) {
    for (final m in state) {
      if (m.id == id) return m;
    }
    return null;
  }

  Future<void> addMember(FamilyMember member) async {
    state = [...state, member];
    await _persistMember(member);
    await _persistIndex();
  }

  Future<void> updateMember(FamilyMember member) async {
    state = [
      for (final m in state)
        if (m.id == member.id) member else m,
    ];
    await _persistMember(member);
  }

  Future<void> removeMember(String memberId) async {
    state = state.where((m) => m.id != memberId).toList();
    await _storage.delete('$_kMemberPrefix$memberId');
    await _persistIndex();
    if (_onMemberRemoved != null) {
      await _onMemberRemoved(memberId);
    }
  }

  /// Test/onboarding helper that replaces state without touching storage.
  void debugReplace(List<FamilyMember> members) {
    state = List.unmodifiable(members);
  }

  Future<void> _persistMember(FamilyMember member) async {
    await _storage.write(
      '$_kMemberPrefix${member.id}',
      jsonEncode(member.toJson()),
    );
  }

  Future<void> _persistIndex() async {
    final ids = state.map((m) => m.id).toList();
    await _storage.write(_kFamilyMembersList, jsonEncode(ids));
  }
}

/// Family roster persisted to SecureStorage. Notifications attached to a
/// removed member are automatically cancelled.
final familyMembersProvider =
    StateNotifierProvider<FamilyMembersNotifier, List<FamilyMember>>((ref) {
  final notifications = ref.watch(notificationServiceProvider);
  return FamilyMembersNotifier(
    const _SecureFamilyStorage(),
    onMemberRemoved: (memberId) async {
      await notifications.cancelAllForMember(memberId);
    },
  );
});

/// Backwards-compatible facade so existing UI code (`familyProvider`) keeps
/// working. Exposes the same notifier; the underlying state is the list.
class FamilyState {
  final List<FamilyMember> members;
  const FamilyState(this.members);
  FamilyMember? getMember(String id) {
    for (final m in members) {
      if (m.id == id) return m;
    }
    return null;
  }
}

final familyProvider = Provider<FamilyState>((ref) {
  final list = ref.watch(familyMembersProvider);
  return FamilyState(list);
});

/// Convenience access to the notifier so widgets can call add/remove/update
/// without juggling two providers.
final familyControllerProvider = Provider<FamilyMembersNotifier>((ref) {
  return ref.watch(familyMembersProvider.notifier);
});

/// Reusable noop-cancel for tests that don't want to mock NotificationService.
Future<void> noopMemberRemoved(String _) async {}

/// In-memory storage used by tests.
class InMemoryFamilyStorage implements FamilyStorage {
  final Map<String, String> _store;
  InMemoryFamilyStorage([Map<String, String>? seed])
      : _store = {...?seed};
  @override
  Future<String?> read(String key) async => _store[key];
  @override
  Future<void> write(String key, String value) async {
    _store[key] = value;
  }

  @override
  Future<void> delete(String key) async {
    _store.remove(key);
  }

  Map<String, String> snapshot() => Map.unmodifiable(_store);
}
