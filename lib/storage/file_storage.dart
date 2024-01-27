import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:cryptography/cryptography.dart';
import 'package:path/path.dart' as path;

import '../session/session.dart';
import 'session_storage.dart';

abstract class FileStorage extends SessionStorage {
  // Directory to store session files
  late final Directory dir;
  // Regex for file names;
  late final RegExp regex;

  static FileStorage crypto(Directory dir, Cipher algorithm, SecretKey secretKey) =>
      _CryptoStorage(dir, algorithm, secretKey);

  static FileStorage plain(Directory dir) =>
      _PlainTextStorage(dir);

  FutureOr<Session> sessionFromFile(File file);

  FutureOr<void> writeSession(Session session, File file);

  File getFile(String sessionId);
  
  @override
  Future<void> clearOutdated() async {
    final now = DateTime.now();

    await Future.wait(await dir.list().map((file) async {
      if (file is File && regex.hasMatch(file.path.split(Platform.pathSeparator).last)) {
        try {
          final session = await sessionFromFile(file);
          if (session.expires.compareTo(now) < 0) {
            await file.delete();
          }
        } catch (e) {
          print(e);
        }
      }
    }).toList());
  }
  
  @override
  Future<void> deleteSession(String sessionId) async {
    final File file = getFile(sessionId);
    if (await file.exists()) {
      await file.delete();
    }
  }

  @override
  Future<Session?> getSession(String sessionId) async {
    final File file = getFile(sessionId);
    try {
      if (await file.exists()) {
        return await sessionFromFile(file);
      }
    } catch(e) {
      print(e);
    }
    return null;
  }

  @override
  Future<void> saveSession(Session session, String sessionId) async {
    final File file = getFile(sessionId);
    try {
      if (!await file.exists()) {
        await file.create();
      }
      await writeSession(session, file);
    } catch(e) {
      print(e);
    }
  }

  @override
  Future<bool> sessionExist(String sessionId) => getFile(sessionId).exists();
}

class _PlainTextStorage extends FileStorage {
  _PlainTextStorage(Directory dir) {
    super.dir = dir;
    super.regex = RegExp(r'^[A-Za-z0-9]{32}\.json$');
  }

  @override
  Future<Session> sessionFromFile(File file) async {
    final content = await file.readAsString();
    return Session.fromJson(json.decode(content) as Map<String, dynamic>);
  }

  @override
  void writeSession(Session session, File file) => file.openWrite().write(json.encode(session.toJson()));

  @override
  File getFile(String sessionId) => File(path.join(dir.path, '$sessionId.json'));
}

class _CryptoStorage extends FileStorage {
  _CryptoStorage(Directory dir, this.algorithm, this.secretKey) {
    super.dir = dir;
    super.regex = RegExp(r'^[A-Za-z0-9]{32}\$');
  }

  Cipher algorithm;

  SecretKey secretKey;

  @override
  Future<Session> sessionFromFile(File file) async {
    final content = (await file.readAsString()).split('|');
    final secretBox = SecretBox(base64.decode(content[1]), nonce: base64.decode(content[0]), mac: Mac(base64.decode(content[2])));
    final clearText = await algorithm.decryptString(
      secretBox,
      secretKey: secretKey,
    );
    return Session.fromJson(json.decode(clearText) as Map<String, dynamic>);
  }

  @override
  Future<void> writeSession(Session session, File file) async {
    final clearText = json.encode(session.toJson());
    final secretBox = await algorithm.encryptString(
      clearText,
      secretKey: secretKey,
    );

    await file.writeAsString(
        '${base64.encode(secretBox.nonce)}|${base64.encode(secretBox.cipherText)}|${base64.encode(secretBox.mac.bytes)}'
    );
  }

  @override
  File getFile(String sessionId) => File(path.join(dir.path, sessionId));
}
