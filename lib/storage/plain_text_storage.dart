import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as path;

import '../session/session.dart';
import 'session_storage.dart';

class PlainTextStorage implements SessionStorage {
  PlainTextStorage(this.dir);

  Directory dir;

  static final RegExp regex = RegExp(r'^[A-Za-z0-9]{32}\.json$');

  @override
  Future<void> clearOutdated() async {
    final now = DateTime.now();

    await Future.wait(await dir.list().map((file) async {
      if (file is File && regex.hasMatch(file.path.split(Platform.pathSeparator).last)) {
        try {
          final content = await file.readAsString();
          final session = Session.fromJson(json.decode(content) as Map<String, dynamic>);
          if (session.expires.compareTo(now) < 0) {
            await file.delete();
          }
        } catch (e) {
          print(e);
        }
      }
    }).toList());
  }

  File _file(String sessionId) => File(path.join(dir.path, '$sessionId.json'));

  @override
  Future<void> deleteSession(String sessionId) async {
    final File file = _file(sessionId);
    if (await file.exists()) {
      await file.delete();
    }
  }

  @override
  Future<Session?> getSession(String sessionId) async {
    final File file = _file(sessionId);
    try {
      if (await file.exists()) {
        final content = await file.readAsString();
        return Session.fromJson(json.decode(content) as Map<String, dynamic>);
      }
    } catch(e) {
      print(e);
    }
    return null;
  }

  @override
  Future<void> saveSession(Session session, String sessionId) async {
    final File file = _file(sessionId);
    try {
      if (!await file.exists()) {
        await file.create();
      }
      file.openWrite().write(json.encode(session.toJson()));
    } catch(e) {
      print(e);
    }
  }

  @override
  Future<bool> sessionExist(String sessionId) => _file(sessionId).exists();
}
