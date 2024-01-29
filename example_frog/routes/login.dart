import 'package:dart_frog/dart_frog.dart';
import 'package:example/example.dart';
import 'index.dart' as index;

Future<Response> onRequest(RequestContext context) async {
  final request = context.request;
  if (request.method == HttpMethod.get) {
    return index.render(menu + html);
  }

  final body = await request.body();
  final queryParameters = Uri(query: body).queryParameters;
  final login = queryParameters['login'] ?? ''
    ..trim();
  final password = queryParameters['password'] ?? ''
    ..trim();
  if (login.isEmpty || password.isEmpty) {
    return index.render(menu + html);
  }

  final user = User(login);
  final userManager = UserManager();
  await userManager.setUser(request, user);
  return Response.movedPermanently(location: '/');
}