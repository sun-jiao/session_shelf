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

/// Returns the cookies received from the [shelf.Request] or [dart_frog.Request].
/// The return value does not include cookies added after the request was received.
// ignore: avoid_annotating_with_dynamic
Map<String, String> parseCookies(dynamic request) {
  late final Map<String, String> headers;
  try {
    headers = request.headers as Map<String, String>;
  } catch(_) {
    throw ArgumentError('The request is neither `shelf.Request` nor `dart_frog.request`');
  }

  final cookieHeader = headers[HttpHeaders.cookieHeader];
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
  } catch (e, s) {
    print('$e\n$s');
    return {};
  }
}

// ignore: avoid_annotating_with_dynamic
Map<String, Object> getContext(dynamic request) {
  if (request is Request) {
    return request.context;
  } else {
    try {
      return request.shelfContext as Map<String, Object>;
    } catch(_) {
      throw ArgumentError('The request is neither `shelf.Request` nor `dart_frog.request`');
    }
  }
}

extension CookieExt on Cookie {
  /// Add cookies to the cookies list of a [shelf.Request] or [dart_frog.Request].
  /// A list of cookies will be sent along with response.
  // ignore: avoid_annotating_with_dynamic
  void addTo(dynamic request) {
    final context = getContext(request);
    final cookies = context[_cookiesKey] as List<Cookie>;
    cookies.add(this);
  }

  /// Changes the cookie's expiration date and adds it to the cookie list
  /// of a [shelf.Request] or [dart_frog.Request].
  /// A list of cookies will be sent along with response.
  // ignore: avoid_annotating_with_dynamic
  void removeFrom(dynamic request) {
    expires = DateTime(1970);
    final context = getContext(request);
    final cookies = context[_cookiesKey] as List<Cookie>;
    cookies.add(this);
  }
}

extension RequestCookiesExt on Request {
  /// Add cookies to the list of cookies. A list of cookies will be sent along
  /// with response.
  @Deprecated('Replaced by [Cookie.addTo] for compatible with dart_frog.')
  void addCookie(Cookie cookie) => cookie.addTo(this);

  /// Returns the cookies received from the request. The return value does not
  /// include cookies added after the request was received.
  @Deprecated('Replaced by [parseCookie(request)] for compatible with dart_frog.')
  Map<String, String> getCookies() => parseCookies(this);

  /// Changes the cookie's expiration date and adds it to the cookie list. A
  /// list of cookies will be sent along with response.
  @Deprecated('Replaced by [Cookie.removeFrom] for compatible with dart_frog.')
  void removeCookie(Cookie cookie) => cookie.removeFrom(this);
}
