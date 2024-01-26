import 'dart:io';

import 'package:shelf/shelf.dart';

const _cookiesKey = 'shelf_session.cookies';

/// Returns the cookie middleware.
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
  /// Add cookies to the list of cookies. A list of cookies will be sent along
  /// with response.
  void addCookie(Cookie cookie) {
    final cookies = context[_cookiesKey] as List<Cookie>;
    cookies.add(cookie);
  }

  /// Returns the cookies received from the request. The return value does not
  /// include cookies added after the request was received.
  Map<String, String> getCookies() {
    return _parseCookieHeader(this);
  }

  /// Changes the cookie's expiration date and adds it to the cookie list. A
  /// list of cookies will be sent along with response.
  void removeCookie(Cookie cookie) {
    cookie.expires = DateTime(1970);
    final cookies = context[_cookiesKey] as List<Cookie>;
    cookies.add(cookie);
  }
}
