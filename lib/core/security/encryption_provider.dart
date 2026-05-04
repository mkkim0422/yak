import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'encryption_service.dart';

/// Overridden in `main()` with the initialized singleton. Lives outside
/// `main.dart` so consumers can import it without dragging in app boot.
final encryptionServiceProvider = Provider<EncryptionService>(
  (ref) => throw UnimplementedError('main() must override this provider'),
);
