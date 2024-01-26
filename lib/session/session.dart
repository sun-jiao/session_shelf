import 'package:shelf/shelf.dart';
import '../middleware/session_middleware.dart';
import 'session_storage.dart';

class Session {
  /// Session lifetime.
  static Duration lifetime = Duration(minutes: 30);

  // The session name is a global value used as a cookie name to store the
  // session id.
  static String name = 'shelf_session_id';

  /// Session data.
  final Map<String, Object?> data = {};

  /// Session expiration date.
  DateTime expires = DateTime.now().add(lifetime);

  // Session storage
  static SessionStorage storage = MemoryStorage();

  // Unique session id.
  String id;

  Session._({
    required this.id,
  });

  /// Creates a new session, assigns it a unique id and returns that session.
  static Session createSession(Request request) {
    final sessionId = getSessionId(request);
    final result = Session._(
      id: sessionId,
    );
    storage.saveSession(result, sessionId);
    return result;
  }

  /// Invalidates the session for the specified request.
  static void deleteSession(Request request) {
    final sessionId = getSessionId(request);
    storage.deleteSession(sessionId);
  }

  /// Returns the session for the specified request, if it was previously
  /// created; otherwise returns null.
  static Session? getSession(Request request) {
    storage.clearOutdated();
    final sessionId = getSessionId(request);
    return storage.getSession(sessionId);
  }
}
