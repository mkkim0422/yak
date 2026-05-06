import 'package:flutter/material.dart';

import '../../../core/widgets/chat_bubbles.dart';

/// Backwards-compat wrapper around the design-token-aware
/// `BotBubble` / `UserBubble` widgets.
class ChatMessage extends StatelessWidget {
  final String text;
  final bool fromUser;
  final bool withMark;

  const ChatMessage({
    super.key,
    required this.text,
    this.fromUser = false,
    this.withMark = false,
  });

  @override
  Widget build(BuildContext context) {
    if (fromUser) return UserBubble(text: text);
    return BotBubble(text: text, withMark: withMark);
  }
}
