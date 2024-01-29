import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:example/example.dart';
import 'package:example/storages_example.dart';
import 'package:session_shelf/session_shelf.dart';

Future<HttpServer> run(Handler handler, InternetAddress ip, int port) async {
  // 1. Execute any custom code prior to starting the server...

  // 2. Use the provided `handler`, `ip`, and `port` to create a custom `HttpServer`.
  // Or use the Dart Frog serve method to do that for you.
  Session.storage = await getSqliteCryptoStorage();
  setupJsonSerializer();

  return serve(handler, ip, port);
}