import 'dart:convert';

class LifeEvent {
  final String type; // 'work' | 'education'
  final String title; // Job Title or Degree
  final String organization; // Company or School
  final String? subtitle; // e.g. 'Full-time • On-site' or 'Computer Science'
  final String? startDate;
  final String? endDate;
  final bool isCurrent;
  final String? location;
  final String? employmentType;
  final String? customNote;

  const LifeEvent({
    required this.type,
    required this.title,
    required this.organization,
    this.subtitle,
    this.startDate,
    this.endDate,
    this.isCurrent = true,
    this.location,
    this.employmentType,
    this.customNote,
  });

  bool get isWork => type == 'work';
  bool get isEducation => type == 'education';

  factory LifeEvent.fromMap(Map<String, dynamic> map) {
    return LifeEvent(
      type: map['type'] as String? ?? 'work',
      title: map['title'] as String? ?? '',
      organization: map['organization'] as String? ?? (map['company'] as String? ?? map['school'] as String? ?? ''),
      subtitle: map['subtitle'] as String?,
      startDate: map['start_date'] as String?,
      endDate: map['end_date'] as String?,
      isCurrent: map['is_current'] as bool? ?? true,
      location: map['location'] as String?,
      employmentType: map['employment_type'] as String?,
      customNote: map['custom_note'] as String?,
    );
  }

  factory LifeEvent.fromJson(String source) => LifeEvent.fromMap(json.decode(source) as Map<String, dynamic>);

  Map<String, dynamic> toMap() {
    return {
      'type': type,
      'title': title,
      'organization': organization,
      if (subtitle != null) 'subtitle': subtitle,
      if (startDate != null) 'start_date': startDate,
      if (endDate != null) 'end_date': endDate,
      'is_current': isCurrent,
      if (location != null) 'location': location,
      if (employmentType != null) 'employment_type': employmentType,
      if (customNote != null) 'custom_note': customNote,
    };
  }

  String toJson() => json.encode(toMap());

  String get milestoneHeadline {
    if (isWork) {
      return 'Started new role as $title at $organization';
    } else {
      if (isCurrent) {
        return 'Started studying at $organization';
      } else {
        return 'Graduated from $organization';
      }
    }
  }

  String get dateRange {
    final start = startDate ?? '';
    final end = isCurrent ? 'Present' : (endDate ?? 'Present');
    if (start.isEmpty) return end;
    return '$start - $end';
  }
}
