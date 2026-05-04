import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/app.dart';
import 'core/data/product_repository.dart';
import 'core/notifications/notification_provider.dart';
import 'core/notifications/notification_service.dart';
import 'core/security/encryption_provider.dart';
import 'core/security/encryption_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final encryption = EncryptionService();
  await encryption.init();

  final notifications = NotificationService();
  await notifications.ensureInitialized();

  final productRepository = ProductRepository();
  await productRepository.load();

  runApp(
    ProviderScope(
      overrides: [
        encryptionServiceProvider.overrideWithValue(encryption),
        notificationServiceProvider.overrideWithValue(notifications),
        productRepositoryProvider.overrideWithValue(productRepository),
      ],
      child: const AlyakApp(),
    ),
  );
}
