import 'dart:async';

import '../session/session.dart';

abstract class SessionStorage {
  FutureOr<void> saveSession(Session session, String sessionId);

  FutureOr<void> deleteSession(String sessionId);

  FutureOr<Session?> getSession(String sessionId);

  FutureOr<bool> sessionExist(String sessionId);

  FutureOr<void> clearOutdated();
}
