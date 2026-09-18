class UserExperience {
  final String id;
  final String userId;
  final String title;
  final String company;
  final String employmentType; // 'Full-time', 'Part-time', 'Contract', 'Internship', 'Freelance'
  final String? location;
  final String locationType; // 'On-site', 'Hybrid', 'Remote'
  final bool isCurrent;
  final String startDate; // e.g. 'Jan 2023' or '2023-01'
  final String? endDate; // null if isCurrent
  final String? description;
  final DateTime? createdAt;

  const UserExperience({
    required this.id,
    required this.userId,
    required this.title,
    required this.company,
    this.employmentType = 'Full-time',
    this.location,
    this.locationType = 'On-site',
    this.isCurrent = true,
    required this.startDate,
    this.endDate,
    this.description,
    this.createdAt,
  });

  factory UserExperience.fromJson(Map<String, dynamic> json) {
    return UserExperience(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      title: json['title'] as String? ?? '',
      company: json['company'] as String? ?? '',
      employmentType: json['employment_type'] as String? ?? 'Full-time',
      location: json['location'] as String?,
      locationType: json['location_type'] as String? ?? 'On-site',
      isCurrent: json['is_current'] as bool? ?? true,
      startDate: json['start_date'] as String? ?? '',
      endDate: json['end_date'] as String?,
      description: json['description'] as String?,
      createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at'] as String) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'title': title,
      'company': company,
      'employment_type': employmentType,
      'location': location,
      'location_type': locationType,
      'is_current': isCurrent,
      'start_date': startDate,
      'end_date': isCurrent ? null : endDate,
      'description': description,
    };
  }

  UserExperience copyWith({
    String? id,
    String? userId,
    String? title,
    String? company,
    String? employmentType,
    String? location,
    String? locationType,
    bool? isCurrent,
    String? startDate,
    String? endDate,
    String? description,
    DateTime? createdAt,
  }) {
    return UserExperience(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      company: company ?? this.company,
      employmentType: employmentType ?? this.employmentType,
      location: location ?? this.location,
      locationType: locationType ?? this.locationType,
      isCurrent: isCurrent ?? this.isCurrent,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      description: description ?? this.description,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  /// Formatted period e.g. "Jan 2023 - Present" or "Jan 2021 - Dec 2022"
  String get periodString {
    final end = isCurrent ? 'Present' : (endDate?.isNotEmpty == true ? endDate! : 'Present');
    return '$startDate - $end';
  }
}
