import 'package:dart_frog/dart_frog.dart';
import 'package:session_shelf/session/session.dart';

Future<Response> onRequest(Request request) async {
  await Session.deleteSession(request);
  return Response.movedPermanently(location: '/');
}