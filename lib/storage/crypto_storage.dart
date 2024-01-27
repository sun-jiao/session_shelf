import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:cryptography/cryptography.dart';
import 'package:path/path.dart' as path;

import '../session/session.dart';
import 'session_storage.dart';

class CryptoStorage implements SessionStorage {
  CryptoStorage(this.dir, this.algorithm, this.secretKey);

  Directory dir;

  Cipher algorithm;

  SecretKey secretKey;

  static final RegExp regex = RegExp(r'^[A-Za-z0-9]{32}\$');

  @override
  Future<void> clearOutdated() async {
    final now = DateTime.now();

    await Future.wait(await dir.list().map((file) async {
      if (file is File && regex.hasMatch(file.path.split(Platform.pathSeparator).last)) {
        try {
          final content = (await file.readAsString()).split('|');
          final secretBox = SecretBox(base64.decode(content[1]), nonce: base64.decode(content[0]), mac: Mac(base64.decode(content[2])));
          final clearText = await algorithm.decryptString(
            secretBox,
            secretKey: secretKey,
          );
          final session = Session.fromJson(json.decode(clearText) as Map<String, dynamic>);
          if (session.expires.compareTo(now) < 0) {
            await file.delete();
          }
        } catch (e) {
          print(e);
        }
      }
    }).toList());
  }

  File _file(String sessionId) => File(path.join(dir.path, sessionId));

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
        final content = (await file.readAsString()).split('|');
        final secretBox = SecretBox(base64.decode(content[1]), nonce: base64.decode(content[0]), mac: Mac(base64.decode(content[2])));
        final clearText = await algorithm.decryptString(
          secretBox,
          secretKey: secretKey,
        );
        return Session.fromJson(json.decode(clearText) as Map<String, dynamic>);
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
      final clearText = json.encode(session.toJson());
      final secretBox = await algorithm.encryptString(
        clearText,
        secretKey: secretKey,
      );

      await file.writeAsString(
          '${base64.encode(secretBox.nonce)}|${base64.encode(secretBox.cipherText)}|${base64.encode(secretBox.mac.bytes)}'
      );
    } catch(e) {
      print(e);
    }
  }

  @override
  Future<bool> sessionExist(String sessionId) => _file(sessionId).exists();
}
