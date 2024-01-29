import 'dart:io';
import 'dart:math';

import 'package:shelf/shelf.dart';

import '../session/session.dart';
import 'cookies_middleware.dart';

const _sessionKey = 'shelf_session.session_id';

/// Returns the session middleware.
Middleware sessionMiddleware() {
  return (Handler innerHandler) {
    return (Request request) async {
      request = await _addSessionIdToRequest(request);
      final sessionId = getSessionId(request);
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
      cookie.addTo(request);
      final response = await innerHandler(request);
      final session = await Session.storage.getSession(sessionId);
      if (session != null) {
        session.expires = expires;
      }

      return response;
    };
  };
}

// ignore: avoid_annotating_with_dynamic
String getSessionId(dynamic request) {
  final context = getContext(request);
  if (!context.containsKey(_sessionKey)) {
    throw StateError('The session id was not found in the request context');
  }

  return context[_sessionKey] as String;
}

Future<Request> _addSessionIdToRequest(Request request) async {
  final cookies = _parseCookieHeader(request);
  var sessionId = cookies[Session.name];
  sessionId ??= await _generateSessionId();
  request = request.change(context: {
    _sessionKey: sessionId,
  });
  return request;
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
  } catch (e, s) {
    print('$e\n$s');
    return <String, String>{};
  }
}

Future<String> _generateSessionId() async {
  while (true) {
    final result = _getRandomString(32);
    if (!await Session.storage.sessionExist(result)) {
      return result;
    }
  }
}

String _getRandomString(int length) {
  const chars = 'AaBbCcDdEeFfGgHhIiJjKkLlMmNnOoPpQqRrSsTtUuVvWwXxYyZz1234567890';
  final rnd = Random.secure();
  return String.fromCharCodes(Iterable.generate(length, (_) {
    return chars.codeUnitAt(rnd.nextInt(chars.length));
  }));
}
