import '../session/session.dart';
import 'session_storage.dart';

class MemoryStorage implements SessionStorage {
  final Map<String, Session> _sessions = {};

  @override
  void saveSession(Session session, String sessionId) => _sessions[sessionId] = session;

  @override
  void deleteSession(String sessionId) => _sessions.remove(sessionId);

  @override
  Session? getSession(String sessionId) => _sessions[sessionId];

  @override
  bool sessionExist(String sessionId) => _sessions.containsKey(sessionId);

  @override
  void clearOutdated() {
    final now = DateTime.now();
    _sessions.removeWhere((k, v) => v.expires.compareTo(now) < 0);
  }
}