import 'package:flutter_test/flutter_test.dart';
import 'package:dak/models/user_experience.dart';
import 'package:dak/models/user_education.dart';
import 'package:dak/models/life_event.dart';
import 'package:dak/models/thread_post.dart';

void main() {
  group('UserExperience Model Tests', () {
    test('computes periodString correctly for current role', () {
      final exp = UserExperience(
        id: 'exp_1',
        userId: 'u_1',
        title: 'Senior Flutter Engineer',
        company: 'Pigeon Social',
        startDate: 'Jan 2023',
        isCurrent: true,
      );

      expect(exp.periodString, 'Jan 2023 - Present');
    });

    test('toJson and fromJson preserves data', () {
      final exp = UserExperience(
        id: 'exp_1',
        userId: 'u_1',
        title: 'Tech Lead',
        company: 'Google',
        employmentType: 'Full-time',
        location: 'Remote',
        locationType: 'Remote',
        startDate: 'Jun 2020',
        endDate: 'Dec 2022',
        isCurrent: false,
        description: 'Led architecture and design',
      );

      final jsonMap = exp.toJson();
      final revived = UserExperience.fromJson(jsonMap);

      expect(revived.title, 'Tech Lead');
      expect(revived.company, 'Google');
      expect(revived.employmentType, 'Full-time');
      expect(revived.isCurrent, isFalse);
      expect(revived.periodString, 'Jun 2020 - Dec 2022');
    });
  });

  group('UserEducation Model Tests', () {
    test('computes degreeWithField and periodString correctly', () {
      final edu = UserEducation(
        id: 'edu_1',
        userId: 'u_1',
        school: 'University of Dhaka',
        degree: 'Bachelor of Science',
        fieldOfStudy: 'Computer Science',
        startDate: '2018',
        endDate: '2022',
        isCurrent: false,
      );

      expect(edu.degreeWithField, 'Bachelor of Science, Computer Science');
      expect(edu.periodString, '2018 - 2022');
    });
  });

  group('LifeEvent & ThreadPost Parsing Tests', () {
    test('parses 🎉DakLifeEvent🎉 payload from post content correctly', () {
      final lifeEvent = LifeEvent(
        type: 'work',
        title: 'Product Manager',
        organization: 'Apple',
        subtitle: 'Full-time · On-site',
        startDate: 'Jan 2024',
        isCurrent: true,
      );

      final rawContent = "Excited to share my new journey!\n\n🎉DakLifeEvent🎉${lifeEvent.toJson()}";

      final rawJson = {
        'id': 'post_100',
        'user_id': 'u_123',
        'content': rawContent,
        'created_at': DateTime.now().toIso8601String(),
        'likes_count': 5,
        'profiles': {
          'id': 'u_123',
          'full_name': 'Steve Jobs',
          'username': 'steve',
        },
      };

      final post = ThreadPost.fromJson(rawJson, currentUid: 'u_123');

      expect(post.content, 'Excited to share my new journey!');
      expect(post.lifeEvent, isNotNull);
      expect(post.lifeEvent!.title, 'Product Manager');
      expect(post.lifeEvent!.organization, 'Apple');
      expect(post.lifeEvent!.isWork, isTrue);
    });
  });
}
