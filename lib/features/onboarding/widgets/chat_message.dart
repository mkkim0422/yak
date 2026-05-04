import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';

/// Toss-style chat bubble. Bot bubbles align left in white; user bubbles
/// align right with the brand blue.
class ChatMessage extends StatelessWidget {
  final String text;
  final bool fromUser;

  const ChatMessage({super.key, required this.text, this.fromUser = false});

  static const Color _userBubble = Color(0xFF3182F6);

  @override
  Widget build(BuildContext context) {
    final align = fromUser ? Alignment.centerRight : Alignment.centerLeft;
    final bg = fromUser ? _userBubble : Colors.white;
    final fg = fromUser ? Colors.white : AppColors.textPrimary;
    final radius = BorderRadius.only(
      topLeft: const Radius.circular(16),
      topRight: const Radius.circular(16),
      bottomLeft: Radius.circular(fromUser ? 16 : 4),
      bottomRight: Radius.circular(fromUser ? 4 : 16),
    );

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Align(
        alignment: align,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.78,
          ),
          child: Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(color: bg, borderRadius: radius),
            child: Text(
              text,
              style: TextStyle(color: fg, fontSize: 15, height: 1.4),
            ),
          ),
        ),
      ),
    );
  }
}
