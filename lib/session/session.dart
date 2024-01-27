import 'package:shelf/shelf.dart';
import '../middleware/session_middleware.dart';
import '../storage/memory_storage.dart';
import '../storage/session_storage.dart';

class Session {
  /// Session lifetime.
  static Duration lifetime = Duration(minutes: 30);

  // The session name is a global value used as a cookie name to store the
  // session id.
  static String name = 'shelf_session_id';

  /// Session data.
  final Map<String, Object?> data;

  /// Session expiration date.
  DateTime expires;

  // Session storage
  static SessionStorage storage = MemoryStorage();

  // Unique session id.
  String id;

  Session._({
    required this.id,
    Map<String, Object?>? data,
    DateTime? expires,
  }): data = data ?? {},
      expires = expires ?? DateTime.now().add(lifetime);

  /// Creates a new session, assigns it a unique id and returns that session.
  static Future<Session> createSession(Request request) async {
    final sessionId = getSessionId(request);
    final result = Session._(
      id: sessionId,
    );
    await storage.saveSession(result, sessionId);
    return result;
  }

  /// Invalidates the session for the specified request.
  static Future<void> deleteSession(Request request) async {
    final sessionId = getSessionId(request);
    await storage.deleteSession(sessionId);
  }

  /// Returns the session for the specified request, if it was previously
  /// created; otherwise returns null.
  static Future<Session?> getSession(Request request) async {
    storage.clearOutdated();
    final sessionId = getSessionId(request);
    return await storage.getSession(sessionId);
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'expires': expires.microsecondsSinceEpoch,
    'data': data,
  };

  factory Session.fromJson(Map<String, dynamic> json) {
    final id = json['id'];
    if (id == null || id is! String) {
      throw ArgumentError('The `id` is either empty or not a String.');
    }

    late final int? intExpires;
    final jsonExpires = json['expires'];
    switch (jsonExpires.runtimeType) {
      case String:
        try {
          intExpires = int.parse(jsonExpires as String);
        } catch (e) {
          throw ArgumentError('The `expires` value is not a valid integer.');
        }
        break;
      case int:
        intExpires = jsonExpires as int;
        break;
      default:
        throw ArgumentError('The `expires` value has an unexpected type.');
    }
    final expires = DateTime.fromMicrosecondsSinceEpoch(intExpires);

    try {
      final data = json['data'] as Map<String, Object?>;
      return Session._(
        id: id,
        expires: expires,
        data: data,
      );
    } catch (e) {
      throw ArgumentError('The session `data` is not in the expected format.');
    }
  }
}
