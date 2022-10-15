import 'dart:io';

import 'package:shelf/shelf.dart';

const _cookiesKey = 'shelf_session.cookies';

Middleware cookiesMiddleware() {
  return (Handler innerHandler) {
    return (Request request) async {
      request = _addCookiesToRequest(request);
      final response = await innerHandler(request);
      final context = request.context;
      final cookies = context[_cookiesKey] as List<Cookie>;
      return response.change(headers: {
        'Set-Cookie': cookies.map((e) => '$e').toList(),
      });
    };
  };
}

Request _addCookiesToRequest(Request request) {
  return request.change(
    context: {_cookiesKey: <Cookie>[]},
  );
}

Map<String, String> _parseCookieHeader(Request request) {
  final cookieHeader = request.headers[HttpHeaders.cookieHeader];
  if (cookieHeader == null || cookieHeader.isEmpty) {
    return {};
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
    return {};
  }
}

extension RequestCookiesExt on Request {
  void addCookie(Cookie cookie) {
    final cookies = context[_cookiesKey] as List<Cookie>;
    cookies.add(cookie);
  }

  Map<String, String> getCookies() {
    return _parseCookieHeader(this);
  }
}
