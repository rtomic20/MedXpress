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

  Future<List<Map<String, dynamic>>> listConversationsByRole({
    required int pacijentId,
    required String role,
  }) async {
    final isDoctorLookingForPatients = role.toLowerCase() == 'pacijent';
    final isPatientLookingForDoctors = role.toLowerCase() == 'doktor';
    final isPatientLookingForNurses = role.toLowerCase() == 'sestra';
    final isNurseLookingForPatients = role.toLowerCase() == 'pacijent_sestra';

    final convRes = await http.get(
      Uri.parse("$_api/conversations/").replace(queryParameters: {
        'user_id': '$pacijentId',
      }),
    );
    _ensureOk(convRes, [200]);

    final List convs = jsonDecode(utf8.decode(convRes.bodyBytes)) as List;

    final byPair = <String, Map<String, dynamic>>{};

    int _ts(dynamic x) {
      final v = (x is Map<String, dynamic>)
          ? (x['last_ts'] ??
              x['last_message_ts'] ??
              x['updated_at'] ??
              x['created_at'])
          : x;
      if (v is int) return v;
      if (v is String) {
        final dt = DateTime.tryParse(v);
        if (dt != null) return dt.millisecondsSinceEpoch;
        final n = int.tryParse(v);
        if (n != null) return n;
      }
      return 0;
    }

    for (final rawAny in convs) {
      final raw = (rawAny as Map).cast<String, dynamic>();
      final convId = (raw['id'] as num?)?.toInt();
      if (convId == null) continue;

      final participants =
          (raw['participants'] as List?)?.cast<Map<String, dynamic>>() ??
              const [];

      Map<String, dynamic>? doctorP;
      Map<String, dynamic>? patientP;
      Map<String, dynamic>? nurseP;

      for (final pAny in participants) {
        final p = pAny.map((k, v) => MapEntry(k.toString(), v));
        final roleStr =
            ((p['uloga'] ?? p['role'] ?? '') as String).toLowerCase();
        if (roleStr.contains('doktor')) doctorP ??= p;
        if (roleStr.contains('pacijent')) patientP ??= p;
        if (roleStr.contains('sestra')) nurseP ??= p;
      }

      if (doctorP != null && patientP != null) {
        final doctorKId =
            (doctorP['korisnik_id'] ?? doctorP['user_id']) as int?;
        final patientKId =
            (patientP['korisnik_id'] ?? patientP['user_id']) as int?;
        if (doctorKId == null || patientKId == null) continue;

        final include =
            (isDoctorLookingForPatients && doctorKId == pacijentId) ||
                (isPatientLookingForDoctors && patientKId == pacijentId);
        if (!include) {
        } else {
          String title;
          int otherKorisnikId;
          if (isDoctorLookingForPatients) {
            final ime = (patientP['ime'] ?? '').toString();
            final prezime = (patientP['prezime'] ?? '').toString();
            title = (ime.isNotEmpty || prezime.isNotEmpty)
                ? '$ime $prezime'
                : 'Pacijent';
            otherKorisnikId = patientKId;
          } else {
            final ime = (doctorP['ime'] ?? '').toString();
            final prezime = (doctorP['prezime'] ?? '').toString();
            title = (ime.isNotEmpty || prezime.isNotEmpty)
                ? '$ime $prezime'
                : 'Doktor';
            otherKorisnikId = doctorKId;
          }

          final key = 'D_${doctorKId}_P_${patientKId}';
          final candidate = {
            'id': convId,
            'title': title,
            'otherKorisnikId': otherKorisnikId,
            'doctor_korisnik_id': doctorKId,
            'patient_korisnik_id': patientKId,
            'last_ts': raw['last_ts'] ??
                raw['last_message_ts'] ??
                raw['updated_at'] ??
                raw['created_at'],
          };

          if (!byPair.containsKey(key) || _ts(candidate) > _ts(byPair[key])) {
            byPair[key] = candidate;
          }
        }
      }

      if (nurseP != null && patientP != null) {
        final nurseKId = (nurseP['korisnik_id'] ?? nurseP['user_id']) as int?;
        final patientKId =
            (patientP['korisnik_id'] ?? patientP['user_id']) as int?;
        if (nurseKId == null || patientKId == null) continue;

        final include = (isNurseLookingForPatients && nurseKId == pacijentId) ||
            (isPatientLookingForNurses && patientKId == pacijentId);
        if (!include) {
        } else {
          String title;
          int otherKorisnikId;
          if (isNurseLookingForPatients) {
            final ime = (patientP['ime'] ?? '').toString();
            final prezime = (patientP['prezime'] ?? '').toString();
            title = (ime.isNotEmpty || prezime.isNotEmpty)
                ? '$ime $prezime'
                : 'Pacijent';
            otherKorisnikId = patientKId;
          } else {
            final ime = (nurseP['ime'] ?? '').toString();
            final prezime = (nurseP['prezime'] ?? '').toString();
            title = (ime.isNotEmpty || prezime.isNotEmpty)
                ? '$ime $prezime'
                : 'Sestra';
            otherKorisnikId = nurseKId;
          }

          final key = 'N_${nurseKId}_P_${patientKId}';
          final candidate = {
            'id': convId,
            'title': title,
            'otherKorisnikId': otherKorisnikId,
            'nurse_korisnik_id': nurseKId,
            'patient_korisnik_id': patientKId,
            'last_ts': raw['last_ts'] ??
                raw['last_message_ts'] ??
                raw['updated_at'] ??
                raw['created_at'],
          };

          if (!byPair.containsKey(key) || _ts(candidate) > _ts(byPair[key])) {
            byPair[key] = candidate;
          }
        }
      }
    }

    return byPair.values.toList();
  }

  void _ensureOk(http.Response res, List<int> ok) {
    if (!ok.contains(res.statusCode)) {
      final body = utf8.decode(res.bodyBytes);
      throw Exception('HTTP ${res.statusCode}: $body');
    }
  }
}
