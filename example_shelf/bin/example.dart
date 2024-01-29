import 'dart:io' show Cookie;

import 'package:example/example.dart';
import 'package:example/storages_example.dart';
import 'package:session_shelf/session_shelf.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as io;
import 'package:shelf_router/shelf_router.dart';

void main(List<String> args) async {
  Session.storage = await getSqliteCryptoStorage();
  setupJsonSerializer();
  final router = Router();
  router.get('/', _handleHome);
  router.get('/login', _handleLogin);
  router.get('/login/', _handleLogin);
  router.post('/login', _handleLogin);
  router.post('/login/', _handleLogin);
  router.get('/logout', _handleLogout);
  router.get('/logout/', _handleLogout);
  final handler = Cascade().add(router).handler;
  final pipeline = const Pipeline()
      .addMiddleware(logRequests())
      .addMiddleware(cookiesMiddleware())
      .addMiddleware(sessionMiddleware())
      .addHandler(handler);
  const address = 'localhost';
  const port = 8080;
  final server = await io.serve(pipeline, address, port);
  print('Serving at http://${server.address.host}:${server.port}');
}

Future<Response> _handleHome(Request request) async {
  final userManager = UserManager();
  final user = await userManager.getUser(request);
  var body = '$menu{{message}}<br />{{cookies}}';
  if (user == null) {
    body = body.replaceAll('{{message}}', 'You are not logged in');
  } else {
    body = body.replaceAll('{{message}}', 'You are logged in as ${user.name}');
  }

  final cookies = request.getCookies();
  body = body.replaceAll(
      '{{cookies}}', cookies.entries.map((e) => '${e.key}: ${e.value}').join('<br />'));
  request.addCookie(Cookie('foo', 'Foo'));
  if (!cookies.containsKey('baz')) {
    request.addCookie(Cookie('baz', 'Baz'));
  } else {
    request.removeCookie(Cookie('baz', ''));
  }

  return _render(body);
}

Future<Response> _handleLogin(Request request) async {
  if (request.method == 'GET') {
    return _render(menu + html);
  }

  final body = await request.readAsString();
  final queryParameters = Uri(query: body).queryParameters;
  final login = queryParameters['login'] ?? ''
    ..trim();
  final password = queryParameters['password'] ?? ''
    ..trim();
  if (login.isEmpty || password.isEmpty) {
    return _render(menu + html);
  }

  final user = User(login);
  final userManager = UserManager();
  await userManager.setUser(request, user);
  return Response.found('/');
}

Future<Response> _handleLogout(Request request) async {
  await Session.deleteSession(request);
  return Response.found('/');
}

Response _render(String body) {
  return Response.ok(body, headers: {
    'Content-type': 'text/html; charset=UTF-8',
  });
}
