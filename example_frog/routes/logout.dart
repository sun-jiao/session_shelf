import 'package:dart_frog/dart_frog.dart';
import 'package:session_shelf/session_shelf.dart';

Future<Response> onRequest(RequestContext context) async {
  await Session.deleteSession(context.request);
  return Response.movedPermanently(location: '/');
}