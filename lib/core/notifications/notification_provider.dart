import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'notification_service.dart';

/// Overridden in `main()` with the initialized singleton. Keeping the
/// declaration outside `main.dart` avoids a circular import for files that
/// depend on the service but should not pull in `app.dart`.
final notificationServiceProvider = Provider<NotificationService>(
  (ref) => throw UnimplementedError('main() must override this provider'),
);
