import 'dart:convert';
import 'package:http/http.dart' as http;
import 'api_config.dart';

class ChatServiceHelper {
  ChatServiceHelper._();
  static final ChatServiceHelper instance = ChatServiceHelper._();

  String get _api => baseUrl.endsWith('/')
      ? baseUrl.substring(0, baseUrl.length - 1)
      : baseUrl;

  Future<int> startChatWithDoctor({
    required int pacijentId,
    required int doktorId,
    required int pacijentKorisnikId,
    required int doktorKorisnikId,
    String title = "",
  }) async {
    final convId = await _getOrCreateConversation(
      pacijentId: pacijentId,
      doktorId: doktorId,
      sestraId: null,
      title: title,
    );

    await addParticipant(
        convId: convId, korisnikId: pacijentKorisnikId, role: 'pacijent');
    await addParticipant(
        convId: convId, korisnikId: doktorKorisnikId, role: 'doktor');

    return convId;
  }

  Future<int> startChatWithNurse({
    required int pacijentId,
    required int sestraId,
    required int pacijentKorisnikId,
    required int sestraKorisnikId,
    String title = "",
  }) async {
    final convId = await _getOrCreateConversation(
      pacijentId: pacijentId,
      doktorId: null,
      sestraId: sestraId,
      title: title,
    );

    await addParticipant(
        convId: convId, korisnikId: pacijentKorisnikId, role: 'pacijent');
    await addParticipant(
        convId: convId, korisnikId: sestraKorisnikId, role: 'sestra');

    return convId;
  }

  Future<List<Map<String, dynamic>>> fetchMessages(int conversationId) async {
    final res = await http
        .get(Uri.parse("$_api/conversations/$conversationId/messages/"));
    _ensureOk(res, [200]);
    final list = jsonDecode(utf8.decode(res.bodyBytes)) as List;
    return list.cast<Map<String, dynamic>>();
  }

  Future<void> sendMessage({
    required int conversationId,
    required int senderKorisnikId,
    required String body,
  }) async {
    final res = await http.post(
      Uri.parse("$_api/conversations/$conversationId/messages/"),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'sender_korisnik_id': senderKorisnikId,
        'body': body,
        'type': 'text',
      }),
    );
    _ensureOk(res, [201]);
  }

  Future<void> addParticipant({
    required int convId,
    required int korisnikId,
    required String role,
  }) async {
    final res = await http.post(
      Uri.parse("$_api/conversations/$convId/participants/"),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'korisnik_id': korisnikId, 'role': role}),
    );
    _ensureOk(res, [200, 201]);
  }

  Future<int> _getOrCreateConversation({
    required int pacijentId,
    int? doktorId,
    int? sestraId,
    String title = "",
  }) async {
    final found = await _findConversationId(
      pacijentId: pacijentId,
      doktorId: doktorId,
      sestraId: sestraId,
    );
    if (found != null) return found;

    final res = await http.post(
      Uri.parse("$_api/conversations/"),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'title': title,
        'pacijent': pacijentId,
        'doktor': doktorId,
        'sestra': sestraId,
      }),
    );
    _ensureOk(res, [201]);
    return (jsonDecode(utf8.decode(res.bodyBytes))['id'] as num).toInt();
  }

  Future<int?> _findConversationId({
    required int pacijentId,
    int? doktorId,
    int? sestraId,
  }) async {
    final query = {
      'pacijent_id': '$pacijentId',
      if (doktorId != null) 'doktor_id': '$doktorId',
      if (sestraId != null) 'sestra_id': '$sestraId',
    };
    final uri =
        Uri.parse("$_api/conversations/").replace(queryParameters: query);
    final res = await http.get(uri);
    _ensureOk(res, [200]);
    final list = jsonDecode(utf8.decode(res.bodyBytes)) as List;
    if (list.isEmpty) return null;
    final first = list.first as Map<String, dynamic>;
    return (first['id'] as num).toInt();
  }

  /// --- NOVO: Lista razgovora filtrirano po ulozi (doktor/sestra) ---
  Future<List<Map<String, dynamic>>> listConversationsByRole({
    required int pacijentId,
    required String role,
  }) async {
    final convRes = await http.get(
      Uri.parse("$_api/conversations/").replace(queryParameters: {
        'user_id': '$pacijentId',
      }),
    );
    _ensureOk(convRes, [200]);

    final List convs = jsonDecode(utf8.decode(convRes.bodyBytes)) as List;
    final results = <Map<String, dynamic>>[];

    for (final raw in convs.cast<Map<String, dynamic>>()) {
      final convId = (raw['id'] as num?)?.toInt();
      if (convId == null) continue;

      // Ako backend vraća sudionike direktno u razgovoru
      final participants = (raw['participants'] as List?) ?? [];

      final other = participants.cast<Map<String, dynamic>>().firstWhere(
            (p) => (p['uloga'] ?? p['role'] ?? '')
                .toString()
                .toLowerCase()
                .contains(role.toLowerCase()),
            orElse: () => {},
          );

      if (other.isEmpty) continue;

      final ime = (other['ime'] ?? '').toString();
      final prezime = (other['prezime'] ?? '').toString();
      final title = (ime.isNotEmpty || prezime.isNotEmpty)
          ? '$ime $prezime'
          : (role.toLowerCase() == 'doktor' ? 'Doktor' : 'Sestra');

      results.add({
        'id': convId,
        'title': title,
        'otherKorisnikId':
            (other['korisnik_id'] ?? other['user_id'] ?? 0) as int,
      });
    }

    return results;
  }

  void _ensureOk(http.Response res, List<int> ok) {
    if (!ok.contains(res.statusCode)) {
      final body = utf8.decode(res.bodyBytes);
      throw Exception('HTTP ${res.statusCode}: $body');
    }
  }
}
