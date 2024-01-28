# shelf_sessions

The `shelf_sessions` is the implementation of `cookiesMiddleware` and  `sessionMiddleware` for `shelf`, to store sessions in files or SQL databases as plain or encrypted text.

This package is based on mezoni's (shelf_session)[https://pub.dev/packages/shelf_session], with more powerful feathers.

Version: 0.2.0

## About

Adds two middleware for `shelf`:
- cookiesMiddleware
- sessionMiddleware

The `cookiesMiddleware` can be used independently.  
The `sessionMiddleware` depends on `cookiesMiddleware` and must be used after it.

```dart
final pipeline = const Pipeline()
    .addMiddleware(cookiesMiddleware())
    .addMiddleware(sessionMiddleware())
    .addHandler(handler);
```

A small workable example:

```dart
import 'dart:io' show Cookie;

import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as io;
import 'package:shelf_router/shelf_router.dart';
import 'package:shelf_sessions/shelf_sessions.dart';
import 'package:shelf_static/shelf_static.dart';

void main(List<String> args) async {
  final router = Router();
  router.get('/', _handleHome);
  router.get('/login', _handleLogin);
  router.get('/login/', _handleLogin);
  router.post('/login', _handleLogin);
  router.post('/login/', _handleLogin);
  router.get('/logout', _handleLogout);
  router.get('/logout/', _handleLogout);
  final staticHandler =
  createStaticHandler('web', defaultDocument: 'index.html');
  final handler = Cascade().add(staticHandler).add(router).handler;
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
    if (user is User) {
      return user;
    }

    return null;
  }

  Future<User> setUser(Request request, User user) async {
    var session = await Session.getSession(request);
    session ??= await Session.createSession(request);
    session.data['user'] = user;
    return user;
  }
}

```

By default, session data is stored in a hash map at runtime.
This implementation implies that session data should only be created for authorized users.
This approach eliminates memory overflow in the case of various types of attacks.
After the expiration of the lifetime, the session data is deleted automatically (which causes the memory to be freed).
Timers are not used for these purposes. This happens during the creation of new sessions.

To store sessions in files, use`FileStorage.plain`;

```dart
main() {
  Session.storage = FileStorage.plain(Directory('shelf_sessions'));
}
```

To store encrypted sessions in files, use`FileStorage.crypto`;

```dart
main() {
  Session.storage = FileStorage.crypto(
      Directory('shelf_sessions'),
      AesGcm.with256bits(),
      // This is just an example. Please DO NOT write your secret key in code.
      SecretKey('Shelf~Sessions??Shelf!Sessions~!'.codeUnits));
}
```

To store sessions in SQL database, use`SqlStorage`;

```dart
final db = sqlite3.openInMemory();

main() async {
  Session.storage = SqlStorage('shelf_sessions', db.execute, (sql) {
    final ResultSet resultSet = db.select(sql);
    return resultSet;
  });
  await Session.storage.createTable();
}
```

To store encrypted sessions in SQL database, use`SqlCryptoStorage`;

```dart
final db = sqlite3.openInMemory();

main() async {
  Session.storage = SqlCryptoStorage('shelf_sessions_crypto', db.execute, (sql) {
    final ResultSet resultSet = db.select(sql);
    return resultSet;
    // This is just an example. Please DO NOT write your secret key in code.
  }, AesGcm.with256bits(), SecretKey('Shelf~Sessions??Shelf!Sessions~!'.codeUnits));
  await Session.storage.createTable();
}
```

If your `data` contains non-basic types:

```dart
void setupJsonSerializer() {
  Session.toEncodable = (obj) {
    if (obj is User) {
      return {
        'type': 'User',
        'name': obj.name,
      };
    }
    return obj;
  };
  Session.reviver = (k, v) {
    if (v is Map && v.length == 2 && v['type'] == 'User' && v.containsKey('name')) {
      return User(v['name'] as String);
    }
    return v;
  };
}
```

For other examples, see `example.dart`. Or you can implement your own `SessionStorage`.