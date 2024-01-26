import 'session.dart';

abstract class SessionStorage {
  void saveSession(Session session, String sessionId);

  void deleteSession(String sessionId);

  Session? getSession(String sessionId);

  bool sessionExist(String sessionId);

  void clearOutdated();
}

class MemoryStorage implements SessionStorage {
  final Map<String, Session> _sessions = {};

  @override
  void saveSession(Session session, String sessionId) =>
      _sessions[sessionId] = session;

  @override
  void deleteSession(String sessionId) =>
      _sessions.remove(sessionId);

  @override
  Session? getSession(String sessionId) =>
      _sessions[sessionId];

  @override
  bool sessionExist(String sessionId) =>
      _sessions.containsKey(sessionId);

  @override
  void clearOutdated() {
    final now = DateTime.now();
    _sessions.removeWhere((k, v) => v.expires.compareTo(now) < 0);
  }
}

class PlainTextStorage implements SessionStorage {
  @override
  void clearOutdated() {
    // TODO: implement clearOutdated
  }

  @override
  void deleteSession(String sessionId) {
    // TODO: implement deleteSession
  }

  @override
  Session? getSession(String sessionId) {
    // TODO: implement getSession
    throw UnimplementedError();
  }

  @override
  void saveSession(Session session, String sessionId) {
    // TODO: implement saveSession
  }

  @override
  bool sessionExist(String sessionId) {
    // TODO: implement sessionExist
    throw UnimplementedError();
  }

}