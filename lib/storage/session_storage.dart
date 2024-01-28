import 'dart:async';

import '../session/session.dart';

abstract class SessionStorage {
  /// Save session data to memory, local files or databases
  FutureOr<void> saveSession(Session session, String sessionId);

  /// Delete a session from memory, local files or databases
  FutureOr<void> deleteSession(String sessionId);

  /// Get session data by ID
  FutureOr<Session?> getSession(String sessionId);

  /// Check if a session exists by ID
  FutureOr<bool> sessionExist(String sessionId);

  /// Clear outdated sessions
  FutureOr<void> clearOutdated();
}
