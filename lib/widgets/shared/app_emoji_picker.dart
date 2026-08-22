import 'package:flutter/material.dart';
import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import 'package:flutter/foundation.dart' as foundation;
import '../../utils/app_theme.dart';

class AppEmojiPicker extends StatelessWidget {
  final ValueChanged<String>? onEmojiSelected;

  const AppEmojiPicker({
    super.key,
    this.onEmojiSelected,
  });

  @override
  Widget build(BuildContext context) {
    
    return Container(
      color: context.scaffoldBg,
      child: EmojiPicker(
        onEmojiSelected: (category, emoji) {
          if (onEmojiSelected != null) {
            onEmojiSelected!(emoji.emoji);
          }
        },
        config: Config(
          height: 256,
          checkPlatformCompatibility: true,
          emojiViewConfig: EmojiViewConfig(
            emojiSizeMax: 28 * (foundation.defaultTargetPlatform == TargetPlatform.iOS ? 1.30 : 1.0),
            backgroundColor: context.scaffoldBg,
          ),
          bottomActionBarConfig: BottomActionBarConfig(
            backgroundColor: context.scaffoldBg,
            buttonColor: context.scaffoldBg,
            buttonIconColor: context.isDarkMode ? Colors.white54 : Colors.black54,
          ),
          searchViewConfig: SearchViewConfig(
            backgroundColor: context.scaffoldBg,
          ),
          categoryViewConfig: CategoryViewConfig(
            backgroundColor: context.scaffoldBg,
            iconColorSelected: Theme.of(context).primaryColor,
            indicatorColor: Theme.of(context).primaryColor,
          ),
        ),
      ),
    );
  }
}
