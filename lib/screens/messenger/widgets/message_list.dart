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
  final void Function(Map<String, dynamic> msg, [Rect? bubbleRect]) onMessageAction;
  final void Function(Map<String, dynamic>) onReply;
  final void Function(dynamic media, {int initialIndex, List<dynamic>? mediaList}) onOpenMedia;
  final void Function(Map<String, dynamic> msg, String emoji)? onToggleReaction;
  final String? currentUserId;
  final String? highlightedMessageId;
  final String? searchQuery;

  const MessageList({
    super.key,
    required this.stream,
    required this.activeTheme,
    required this.pendingMessages,
    required this.deletedIds,
    required this.scrollController,
    required this.onAllMessagesUpdated,
    required this.onScrollToBottom,
    required this.onMessageAction,
    required this.onReply,
    required this.onOpenMedia,
    this.onToggleReaction,
    this.currentUserId,
    this.highlightedMessageId,
    this.searchQuery,
  });

  @override
  State<MessageList> createState() => MessageListState();
}

class _ProcessedDisplayItem {
  final Map<String, dynamic> msg;
  final bool showDateHeader;
  final String dateBadgeText;
  final double marginBottom;

  const _ProcessedDisplayItem({
    required this.msg,
    required this.showDateHeader,
    required this.dateBadgeText,
    required this.marginBottom,
  });
}

class MessageListState extends State<MessageList> {
  List<Map<String, dynamic>> _lastStreamMessages = const [];
  List<_ProcessedDisplayItem> _cachedDisplayItems = const [];
  int _lastPendingLength = -1;
  int _lastDeletedCount = -1;

  bool _isImageMessage(Map<String, dynamic> m) {
    final mediaType = m['media_type'] as String? ?? '';
    final mediaUrl = m['media_url'] as String? ?? '';
    final localBytes = m['local_media_bytes'];
    if (mediaType == 'audio' ||
        mediaType == 'theme_change' ||
        mediaType == 'wallpaper_change') {
      return false;
    }
    return mediaType == 'image' ||
        localBytes != null ||
        (mediaUrl.isNotEmpty && mediaType != 'video');
  }

  List<Map<String, dynamic>> _groupConsecutiveImageMessages(
      List<Map<String, dynamic>> msgs) {
    if (msgs.length <= 1) return msgs;

    final List<Map<String, dynamic>> result = [];
    int i = 0;

    while (i < msgs.length) {
      final current = msgs[i];
      if (!_isImageMessage(current)) {
        result.add(current);
        i++;
        continue;
      }

      final List<Map<String, dynamic>> group = [current];
      int j = i + 1;

      while (j < msgs.length) {
        final next = msgs[j];
        if (!_isImageMessage(next)) break;
        if (next['isMe'] != current['isMe']) break;

        final gCurrent = current['group_id'] as String?;
        final gNext = next['group_id'] as String?;

        bool shouldGroup = false;

        if (gCurrent != null && gNext != null) {
          shouldGroup = (gCurrent == gNext);
        } else {
          final curText = (current['text'] as String? ?? '').trim();
          if (curText.isEmpty) {
            final dt1 = ChatDateFormatter.parseMessageDateTime(current);
            final dt2 = ChatDateFormatter.parseMessageDateTime(next);
            final diffSec = dt2.difference(dt1).abs().inSeconds;
            if (diffSec <= 90 &&
                current['reply_to_id'] == next['reply_to_id']) {
              shouldGroup = true;
            }
          }
        }

        if (shouldGroup) {
          group.add(next);
          j++;
          final nextText = (next['text'] as String? ?? '').trim();
          if (nextText.isNotEmpty) {
            break;
          }
        } else {
          break;
        }
      }

      if (group.length > 1) {
        final first = group.first;
        final lastWithText = group.reversed.firstWhere(
          (m) => (m['text'] as String? ?? '').trim().isNotEmpty,
          orElse: () => const {},
        );

        final mergedGroup = <String, dynamic>{
          'id': first['id'],
          'is_group': true,
          'group_messages': group,
          'isMe': first['isMe'],
          'time': first['time'],
          'created_at': first['created_at'],
          'is_read': group.every((m) => m['is_read'] == true),
          'is_sending': group.any((m) => m['is_sending'] == true),
          'is_pinned': group.any((m) => m['is_pinned'] == true),
          'reactions': first['reactions'],
          'reply_to_id': first['reply_to_id'],
          'reply_to_text': first['reply_to_text'],
          'reply_to_sender': first['reply_to_sender'],
          'text': lastWithText['text'] ?? '',
        };
        result.add(mergedGroup);
        i = j;
      } else {
        result.add(current);
        i++;
      }
    }

    return result;
  }

  List<_ProcessedDisplayItem> _buildProcessedItems(List<Map<String, dynamic>> messages) {
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
          widget.pendingMessages
              .removeWhere((m) => idsToRemove.contains(m['id']));
        }
      });
    }

    if (display.isEmpty) {
      return const [];
    }

    final List<Map<String, dynamic>> reversedDisplay =
        _groupConsecutiveImageMessages(display).reversed.toList();

    final List<_ProcessedDisplayItem> items = [];
    final int len = reversedDisplay.length;

    for (int index = 0; index < len; index++) {
      final msg = reversedDisplay[index];
      final msgDate = ChatDateFormatter.parseMessageDateTime(msg);

      bool showDateHeader = false;
      if (index == len - 1) {
        showDateHeader = true;
      } else {
        final olderMsg = reversedDisplay[index + 1];
        final olderMsgDate = ChatDateFormatter.parseMessageDateTime(olderMsg);
        showDateHeader = !ChatDateFormatter.isSameDay(msgDate, olderMsgDate);
      }

      final dateBadgeText = showDateHeader
          ? ChatDateFormatter.formatWhatsAppDateBadge(msgDate)
          : '';

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

      items.add(_ProcessedDisplayItem(
        msg: msg,
        showDateHeader: showDateHeader,
        dateBadgeText: dateBadgeText,
        marginBottom: marginBottom,
      ));
    }

    return items;
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: widget.stream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting &&
            !snapshot.hasData) {
          return Center(
            child: CircularProgressIndicator(
              color: widget.activeTheme.primaryColor,
            ),
          );
        }

        final messages = snapshot.data ?? const [];

        // Check if we need to recompute display items
        final bool hasChanged = !identical(messages, _lastStreamMessages) ||
            widget.pendingMessages.length != _lastPendingLength ||
            widget.deletedIds.length != _lastDeletedCount;

        if (hasChanged) {
          _lastStreamMessages = messages;
          _lastPendingLength = widget.pendingMessages.length;
          _lastDeletedCount = widget.deletedIds.length;
          _cachedDisplayItems = _buildProcessedItems(messages);

          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              widget.onAllMessagesUpdated(messages);
            }
          });
        }

        if (_cachedDisplayItems.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.forum_outlined, size: 48, color: context.textMuted),
                const SizedBox(height: 12),
                Text(
                  'Send a message to start the conversation.',
                  style: GoogleFonts.inter(color: context.textMuted),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          reverse: true,
          controller: widget.scrollController,
          physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          itemCount: _cachedDisplayItems.length,
          addRepaintBoundaries: true,
          addAutomaticKeepAlives: false,
          itemBuilder: (context, index) {
            final item = _cachedDisplayItems[index];

            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (item.showDateHeader)
                  _buildDateBadgeWidget(context, item.dateBadgeText),
                RepaintBoundary(
                  child: MessageBubble(
                    key: ValueKey(item.msg['id']),
                    msg: item.msg,
                    activeTheme: widget.activeTheme,
                    onTap: (bubbleRect) => widget.onMessageAction(item.msg, bubbleRect),
                    onReply: () => widget.onReply(item.msg),
                    onOpenMedia: widget.onOpenMedia,
                    onToggleReaction: widget.onToggleReaction != null
                        ? (emoji) => widget.onToggleReaction!(item.msg, emoji)
                        : null,
                    currentUserId: widget.currentUserId,
                    isHighlighted: widget.highlightedMessageId == item.msg['id'],
                    searchQuery: widget.searchQuery,
                    marginBottom: item.marginBottom,
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