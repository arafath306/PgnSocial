class PollOption {
  final String id;
  final String threadId;
  final String optionText;
  final int votesCount;
  final String? imageUrl;

  PollOption({
    required this.id,
    required this.threadId,
    required this.optionText,
    this.votesCount = 0,
    this.imageUrl,
  });

  factory PollOption.fromJson(Map<String, dynamic> json, {List<dynamic>? votesList}) {
    final optionId = json['id'] as String;
    String rawText = json['option_text'] as String? ?? '';
    String? parsedImageUrl = json['image_url'] as String?;

    if (parsedImageUrl == null && rawText.contains('|DakOptionImg|')) {
      final parts = rawText.split('|DakOptionImg|');
      rawText = parts[0];
      if (parts.length > 1 && parts[1].isNotEmpty) {
        parsedImageUrl = parts[1];
      }
    }
    
    // Calculate votes count either from cached count or dynamically from joined votesList
    int count = 0;
    if (votesList != null) {
      count = votesList.where((vote) => vote['poll_option_id'] == optionId).length;
    } else {
      count = (json['votes_count'] as int?) ?? 0;
    }

    return PollOption(
      id: optionId,
      threadId: json['thread_id'] as String? ?? '',
      optionText: rawText,
      votesCount: count,
      imageUrl: parsedImageUrl,
    );
  }

  Map<String, dynamic> toJson() {
    final String textToSave = imageUrl != null && imageUrl!.isNotEmpty
        ? '$optionText|DakOptionImg|$imageUrl'
        : optionText;

    return {
      'id': id,
      'thread_id': threadId,
      'option_text': textToSave,
      'image_url': imageUrl,
      'votes_count': votesCount,
    };
  }

  PollOption copyWith({
    String? id,
    String? threadId,
    String? optionText,
    int? votesCount,
    String? imageUrl,
  }) {
    return PollOption(
      id: id ?? this.id,
      threadId: threadId ?? this.threadId,
      optionText: optionText ?? this.optionText,
      votesCount: votesCount ?? this.votesCount,
      imageUrl: imageUrl ?? this.imageUrl,
    );
  }
}
