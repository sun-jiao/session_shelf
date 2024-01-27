import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as path;

import 'session.dart';

abstract class SessionStorage {
  FutureOr<void> saveSession(Session session, String sessionId);

  FutureOr<void> deleteSession(String sessionId);

  FutureOr<Session?> getSession(String sessionId);

  FutureOr<bool> sessionExist(String sessionId);

  FutureOr<void> clearOutdated();
}

class MemoryStorage implements SessionStorage {
  final Map<String, Session> _sessions = {};

  @override
  void saveSession(Session session, String sessionId) => _sessions[sessionId] = session;

  @override
  void deleteSession(String sessionId) => _sessions.remove(sessionId);

  @override
  Session? getSession(String sessionId) => _sessions[sessionId];

  @override
  bool sessionExist(String sessionId) => _sessions.containsKey(sessionId);

  @override
  void clearOutdated() {
    final now = DateTime.now();
    _sessions.removeWhere((k, v) => v.expires.compareTo(now) < 0);
  }
}

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
          final session = Session.fromJson(jsonDecode(content) as Map<String, dynamic>);
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
        return Session.fromJson(jsonDecode(content) as Map<String, dynamic>);
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
      if (await file.exists()) {
        file.openWrite().write(session.toJson());
      }
    } catch(e) {
      print(e);
    }
  }

  @override
  Future<bool> sessionExist(String sessionId) => _file(sessionId).exists();
}
