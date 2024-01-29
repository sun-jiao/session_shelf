import 'package:session_shelf/session/session.dart';

const menu = '''
<a href="/">Home</a><br />
<a href="/login">Log in</a><br />
<a href="/logout">Log out</a><br />''';

const html = '''
<form action="" method="post">
<label>Login</label><br />
<input name="login" type="text" /><br />
<label>Password</label><br />
<input name="password" type="password" /><br /><br />
<button>Log in</button>
</form>
''';

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

class User {
  final String name;

  User(this.name);
}

class UserManager {
  Future<User?> getUser(dynamic request) async {
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

  Future<User> setUser(dynamic request, User user) async {
    var session = await Session.getSession(request);
    session ??= await Session.createSession(request);
    session.data['user'] = user;
    Session.storage.saveSession(session, session.id); // This is required if you use a file storage.
    return user;
  }
}
