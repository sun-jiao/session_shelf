import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:example/example.dart';
import 'package:session_shelf/middleware/cookies_middleware.dart';

Response render(String body) {
  return Response(body: body, headers: {
    'Content-type': 'text/html; charset=UTF-8',
  },);
}

Future<Response> onRequest(RequestContext context) async {
  final request = context.request;
  final userManager = UserManager();
  final user = await userManager.getUser(request);
  var body = '$menu{{message}}<br />{{cookies}}';
  if (user == null) {
    body = body.replaceAll('{{message}}', 'You are not logged in');
  } else {
    body = body.replaceAll('{{message}}', 'You are logged in as ${user.name}');
  }

  final cookies = parseCookies(request);
  body = body.replaceAll(
      '{{cookies}}', cookies.entries.map((e) => '${e.key}: ${e.value}').join('<br />'));
  Cookie('foo', 'Foo').addTo(request);
  if (!cookies.containsKey('baz')) {
    Cookie('baz', 'Baz').addTo(request);
  } else {
    Cookie('baz', '').removeFrom(request);
  }

  return render(body);
}