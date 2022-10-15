import 'dart:io';
import 'dart:math';

import 'package:shelf/shelf.dart';

import 'cookies_middleware.dart';

const _sessionKey = 'shelf_session.session_id';

final Map<String, Session> _sessions = {};

Middleware sessionMiddleware() {
  return (Handler innerHandler) {
    return (Request request) async {
      request = _addSessionIdToRequest(request);
      final sessionId = _getSessionId(request);
      final requestedUri = request.requestedUri;
      final isSecure = requestedUri.scheme == 'https';
      final now = DateTime.now();
      final lifetime = Session.lifetime;
      final expires = now.add(lifetime);
      final cookie = Cookie(
        Session.name,
        sessionId,
      );
      cookie.secure = isSecure;
      cookie.path = '/';
      cookie.maxAge = expires.difference(DateTime.now()).inSeconds;
      cookie.expires = expires;
      cookie.httpOnly = true;
      request.addCookie(cookie);
      final response = await innerHandler(request);
      final session = _sessions[sessionId];
      if (session != null) {
        session.expires = expires;
      }

      return response;
    };
  };
}

Request _addSessionIdToRequest(Request request) {
  final cookies = _parseCookieHeader(request);
  var sessionId = cookies[Session.name];
  sessionId ??= _generateSessionId();
  request = request.change(context: {
    _sessionKey: sessionId,
  });
  return request;
}

String _generateSessionId() {
  while (true) {
    final result = _getRandomString(32);
    if (!_sessions.containsKey(result)) {
      return result;
    }
  }
}

String _getRandomString(int length) {
  const chars =
      'AaBbCcDdEeFfGgHhIiJjKkLlMmNnOoPpQqRrSsTtUuVvWwXxYyZz1234567890';
  final rnd = Random.secure();
  return String.fromCharCodes(Iterable.generate(length, (_) {
    return chars.codeUnitAt(rnd.nextInt(chars.length));
  }));
}

String _getSessionId(Request request) {
  final context = request.context;
  if (!context.containsKey(_sessionKey)) {
    throw StateError('The session id was not found in the request context');
  }

  return context[_sessionKey] as String;
}

Map<String, String> _parseCookieHeader(Request request) {
  final cookieHeader = request.headers[HttpHeaders.cookieHeader];
  if (cookieHeader == null || cookieHeader.isEmpty) {
    return <String, String>{};
  }

  try {
    final result = <String, String>{};
    for (final part in cookieHeader.split('; ')) {
      final index = part.indexOf('=');
      if (index != -1) {
        result[part.substring(0, index)] = part.substring(index + 1);
      }
    }

    return result;
  } catch (s) {
    return <String, String>{};
  }
}

class Session {
  static Duration lifetime = Duration(minutes: 30);

  static String name = 'shelf_session_id';

  final Map<String, Object?> data = {};

  DateTime expires = DateTime.now().add(lifetime);

  String id;

  Session._({
    required this.id,
  });

  static Session createSession(Request request) {
    final sessionId = _getSessionId(request);
    final result = Session._(
      id: sessionId,
    );
    _sessions[sessionId] = result;
    return result;
  }

  static void deleteSession(Request request) {
    final sessionId = _getSessionId(request);
    _sessions.remove(sessionId);
  }

  static Session? getSession(Request request) {
    final sessionId = _getSessionId(request);
    final now = DateTime.now();
    _sessions.removeWhere((k, v) => v.expires.compareTo(now) < 0);
    return _sessions[sessionId];
  }
}
