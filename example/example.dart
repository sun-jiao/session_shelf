import 'dart:io' show Cookie, Directory;

import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as io;
import 'package:shelf_router/shelf_router.dart';
import 'package:shelf_session/shelf_session.dart';

void main(List<String> args) async {
  Session.storage = PlainTextStorage(Directory('shelf_session'));
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

const _menu = '''
<a href="/">Home</a><br />
<a href="/login">Log in</a><br />
<a href="/logout">Log out</a><br />''';

Future<Response> _handleHome(Request request) async {
  final userManager = UserManager();
  final user = await userManager.getUser(request);
  var body = '$_menu{{message}}<br />{{cookies}}';
  if (user == null) {
    body = body.replaceAll('{{message}}', 'You are not logged in');
  } else {
    body = body.replaceAll('{{message}}', 'You are logged in as ${user.name}');
  }

  final cookies = request.getCookies();
  body = body.replaceAll('{{cookies}}',
      cookies.entries.map((e) => '${e.key}: ${e.value}').join('<br />'));
  request.addCookie(Cookie('foo', 'Foo'));
  if (!cookies.containsKey('baz')) {
    request.addCookie(Cookie('baz', 'Baz'));
  } else {
    request.removeCookie(Cookie('baz', ''));
  }

  return _render(body);
}

Future<Response> _handleLogin(Request request) async {
  const html = '''
<form action="" method="post">
<label>Login</label><br />
<input name="login" type="text" /><br />
<label>Password</label><br />
<input name="password" type="password" /><br /><br />
<button>Log in</button>
</form>
''';

  if (request.method == 'GET') {
    return _render(_menu + html);
  }

  final body = await request.readAsString();
  final queryParameters = Uri(query: body).queryParameters;
  final login = queryParameters['login'] ?? ''
    ..trim();
  final password = queryParameters['password'] ?? ''
    ..trim();
  if (login.isEmpty || password.isEmpty) {
    return _render(_menu + html);
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

class User {
  final String name;

  User(this.name);
}

class UserManager {
  Future<User?> getUser(Request request) async {
    final session = await Session.getSession(request);
    if (session == null) {
      return null;
    }

    final user = session.data['user'];
    if (user is String) {
      return User(user);
    }

    return null;
  }

  Future<User> setUser(Request request, User user) async {
    var session = await Session.getSession(request);
    session ??= await Session.createSession(request);
    session.data['user'] = user.name;
    Session.storage.saveSession(session, session.id);
    return user;
  }
}
