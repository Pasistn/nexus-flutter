import 'package:flutter_test/flutter_test.dart';
import 'package:nexus_flutter/models/conversation.dart';
import 'package:nexus_flutter/models/rating.dart';
import 'package:nexus_flutter/models/skill.dart';
import 'package:nexus_flutter/models/skill_request.dart';

void main() {
  group('Skill', () {
    test('parses a row including the joined category', () {
      final skill = Skill.fromJson({
        'id': 's1',
        'user_id': 'u1',
        'user_name': 'Lea',
        'skill_title': 'Gitarre',
        'description': 'Anfängerkurs',
        'lat': 48,
        'lng': 11.5,
        'skill_type': 'searching',
        'tags': ['Musik'],
        'category_id': 'c1',
        'categories': {'id': 'c1', 'name': 'Musik & Kunst', 'icon': '🎸'},
        'created_at': '2026-05-01T10:00:00Z',
      });

      expect(skill.type, SkillType.searching);
      expect(skill.isSearch, isTrue);
      expect(skill.lat, 48.0);
      expect(skill.categoryName, 'Musik & Kunst');
      expect(skill.tags, ['Musik']);
    });

    test('falls back to offering for unknown types', () {
      final skill = Skill.fromJson({'id': 's', 'skill_type': 'weird'});
      expect(skill.type, SkillType.offering);
      expect(skill.tags, isEmpty);
    });

    test('insert payload only contains writable columns', () {
      const skill = Skill(
        id: '',
        userId: 'u1',
        title: 'Rad',
        description: 'Reparatur',
        lat: 1,
        lng: 2,
      );
      final json = skill.toInsertJson();
      expect(json['skill_type'], 'offering');
      expect(json.containsKey('id'), isFalse);
      expect(json.containsKey('user_name'), isFalse);
    });
  });

  group('Conversation', () {
    Conversation direct() => Conversation.fromJson({
          'id': 'c1',
          'type': 'direct',
          'created_at': '2026-05-01T10:00:00Z',
          'conversation_members': [
            {'user_id': 'me', 'user_name': 'Ich'},
            {'user_id': 'other', 'user_name': 'Tom', 'avatar_url': 'other/1.png'},
          ],
        });

    test('uses the partner name as title in direct chats', () {
      final c = direct();
      expect(c.isGroup, isFalse);
      expect(c.titleFor('me'), 'Tom');
      expect(c.partnerOf('me')?.avatarUrl, 'other/1.png');
    });

    test('groups use their own name', () {
      final c = Conversation.fromJson({
        'id': 'g',
        'type': 'group',
        'name': 'Garten-Crew',
        'created_at': '2026-05-01T10:00:00Z',
      });
      expect(c.isGroup, isTrue);
      expect(c.titleFor('me'), 'Garten-Crew');
      expect(c.partnerOf('me'), isNull);
    });

    test('withLastMessage updates the sort key', () {
      final at = DateTime.utc(2026, 6, 1);
      final c = direct().withLastMessage('Hallo', at);
      expect(c.lastMessage, 'Hallo');
      expect(c.sortKey, at);
    });
  });

  test('RatingSummary averages the stars', () {
    Rating r(int stars) => Rating(
          id: '$stars',
          raterId: 'a',
          ratedUserId: 'b',
          stars: stars,
        );

    final summary = RatingSummary.of([r(5), r(4), r(3)]);
    expect(summary.average, 4);
    expect(summary.count, 3);
    expect(RatingSummary.of(const []), same(RatingSummary.empty));
  });

  test('SkillRequest maps the status string', () {
    final req = SkillRequest.fromJson({
      'id': 'r',
      'skill_id': 's',
      'requester_id': 'a',
      'skill_owner_id': 'b',
      'status': 'accepted',
      'created_at': '2026-05-01T10:00:00Z',
    });
    expect(req.status, RequestStatus.accepted);
    expect(req.isPending, isFalse);
  });
}
