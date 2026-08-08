import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../utils/app_theme.dart';
import '../../../utils/chat_themes.dart';
import '../../../utils/chat_date_formatter.dart';
import 'message_bubble.dart';


class MessageList extends StatefulWidget {
  final Stream<List<Map<String, dynamic>>> stream;
  final ChatTheme activeTheme;
  final List<Map<String, dynamic>> pendingMessages;
  final Set<String> deletedIds;
  final ScrollController scrollController;
  final void Function(List<Map<String, dynamic>>) onAllMessagesUpdated;
  final VoidCallback onScrollToBottom;
  final void Function(Map<String, dynamic>) onMessageAction;
  final void Function(Map<String, dynamic>) onReply;
  final void Function(String) onOpenMedia;

  const MessageList({super.key, required this.stream,
    required this.activeTheme,
    required this.pendingMessages,
    required this.deletedIds,
    required this.scrollController,
    required this.onAllMessagesUpdated,
    required this.onScrollToBottom,
    required this.onMessageAction,
    required this.onReply,
    required this.onOpenMedia,
  });

  @override
  State<MessageList> createState() => MessageListState();
}

class MessageListState extends State<MessageList> {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: widget.stream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting &&
            !snapshot.hasData) {
          return Center(
              child: CircularProgressIndicator(
                  color: widget.activeTheme.primaryColor));
        }

        final messages = snapshot.data ?? [];
        widget.onAllMessagesUpdated(messages);

        // Merge stream + pending, skip already-confirmed and deleted
        final List<Map<String, dynamic>> display =
            List<Map<String, dynamic>>.from(messages)
              ..removeWhere((m) => widget.deletedIds.contains(m['id']));

        final List<String> idsToRemove = [];
        for (final pm in widget.pendingMessages) {
          final pmId = pm['id'] as String;
          if (widget.deletedIds.contains(pmId)) continue;
          final alreadyIn = messages.any((m) {
            final mText = m['text'] as String? ?? '';
            final pmText = pm['text'] as String? ?? '';
            final mMedia = m['media_url'] as String? ?? '';
            final pmMedia = pm['media_url'] as String? ?? '';
            return m['id'] == pmId ||
                (mText == pmText && mMedia == pmMedia && m['isMe'] == true);
          });
          if (alreadyIn) {
            idsToRemove.add(pmId);
          } else {
            display.add(pm);
          }
        }

        if (idsToRemove.isNotEmpty) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              // Notify parent to remove from pending
              widget.pendingMessages
                  .removeWhere((m) => idsToRemove.contains(m['id']));
            }
          });
        }


        if (display.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.forum_outlined, size: 48, color: context.textMuted),
                const SizedBox(height: 12),
                Text('Send a message to start the conversation.',
                    style: GoogleFonts.inter(color: context.textMuted)),
              ],
            ),
          );
        }

        final List<Map<String, dynamic>> reversedDisplay = display.reversed.toList();

        return ListView.builder(
          reverse: true,
          controller: widget.scrollController,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          itemCount: reversedDisplay.length,
          itemBuilder: (context, index) {
            final msg = reversedDisplay[index];
            final msgDate = ChatDateFormatter.parseMessageDateTime(msg);

            // Check if we should show date header above this message
            bool showDateHeader = false;
            if (index == reversedDisplay.length - 1) {
              // First (oldest) message in chat
              showDateHeader = true;
            } else {
              final olderMsg = reversedDisplay[index + 1];
              final olderMsgDate = ChatDateFormatter.parseMessageDateTime(olderMsg);
              showDateHeader = !ChatDateFormatter.isSameDay(msgDate, olderMsgDate);
            }

            final dateBadgeText = ChatDateFormatter.formatWhatsAppDateBadge(msgDate);

            // Compute tight margin for consecutive same-sender messages
            double marginBottom = 10.0;
            if (index > 0) {
              final newerMsg = reversedDisplay[index - 1];
              final isSameSender = (msg['isMe'] == newerMsg['isMe']);
              if (isSameSender) {
                final newerDate = ChatDateFormatter.parseMessageDateTime(newerMsg);
                if (ChatDateFormatter.isSameDay(msgDate, newerDate) &&
                    newerDate.difference(msgDate).abs().inMinutes <= 3) {
                  marginBottom = 3.0;
                }
              }
            }

            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (showDateHeader) _buildDateBadgeWidget(context, dateBadgeText),
                RepaintBoundary(
                  child: MessageBubble(
                    key: ValueKey(msg['id']),
                    msg: msg,
                    activeTheme: widget.activeTheme,
                    onTap: () => widget.onMessageAction(msg),
                    onReply: () => widget.onReply(msg),
                    onOpenMedia: widget.onOpenMedia,
                    marginBottom: marginBottom,
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildDateBadgeWidget(BuildContext context, String text) {
    final isDark = context.isDarkMode;
    return Container(
      margin: const EdgeInsets.only(top: 14, bottom: 10),
      alignment: Alignment.center,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
        decoration: BoxDecoration(
          color: isDark
              ? const Color(0xFF1E293B).withValues(alpha: 0.9)
              : const Color(0xFFE2E8F0).withValues(alpha: 0.95),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: context.border.withValues(alpha: 0.4),
            width: 0.6,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 4,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Text(
          text,
          style: GoogleFonts.inter(
            fontSize: 11.5,
            fontWeight: FontWeight.w600,
            color: context.textSecondary,
          ),
        ),
      ),
    );
  }
}

// â”€â”€â”€ Message Bubble â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€