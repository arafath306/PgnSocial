class UserEducation {
  final String id;
  final String userId;
  final String school;
  final String? degree; // e.g. "Bachelor of Science", "Master's", "HSC"
  final String? fieldOfStudy; // e.g. "Computer Science & Engineering"
  final String startDate; // e.g. "2019" or "Sep 2019"
  final String? endDate; // e.g. "2023" or "Jun 2023", null if isCurrent
  final bool isCurrent;
  final String? grade; // e.g. "CGPA 3.85 / 4.00"
  final String? activities; // clubs, societies
  final String? description;
  final DateTime? createdAt;

  const UserEducation({
    required this.id,
    required this.userId,
    required this.school,
    this.degree,
    this.fieldOfStudy,
    required this.startDate,
    this.endDate,
    this.isCurrent = false,
    this.grade,
    this.activities,
    this.description,
    this.createdAt,
  });

  factory UserEducation.fromJson(Map<String, dynamic> json) {
    return UserEducation(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      school: json['school'] as String? ?? '',
      degree: json['degree'] as String?,
      fieldOfStudy: json['field_of_study'] as String?,
      startDate: json['start_date'] as String? ?? '',
      endDate: json['end_date'] as String?,
      isCurrent: json['is_current'] as bool? ?? false,
      grade: json['grade'] as String?,
      activities: json['activities'] as String?,
      description: json['description'] as String?,
      createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at'] as String) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'school': school,
      'degree': degree,
      'field_of_study': fieldOfStudy,
      'start_date': startDate,
      'end_date': isCurrent ? null : endDate,
      'is_current': isCurrent,
      'grade': grade,
      'activities': activities,
      'description': description,
    };
  }

  UserEducation copyWith({
    String? id,
    String? userId,
    String? school,
    String? degree,
    String? fieldOfStudy,
    String? startDate,
    String? endDate,
    bool? isCurrent,
    String? grade,
    String? activities,
    String? description,
    DateTime? createdAt,
  }) {
    return UserEducation(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      school: school ?? this.school,
      degree: degree ?? this.degree,
      fieldOfStudy: fieldOfStudy ?? this.fieldOfStudy,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      isCurrent: isCurrent ?? this.isCurrent,
      grade: grade ?? this.grade,
      activities: activities ?? this.activities,
      description: description ?? this.description,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  String get periodString {
    final end = isCurrent ? 'Present' : (endDate?.isNotEmpty == true ? endDate! : 'Present');
    return '$startDate - $end';
  }

  String get degreeWithField {
    if (degree != null && fieldOfStudy != null) {
      return '$degree, $fieldOfStudy';
    }
    return degree ?? fieldOfStudy ?? '';
  }
}
