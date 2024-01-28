import 'dart:async';
import 'dart:convert';

import 'package:cryptography/cryptography.dart';

import '../session/session.dart';
import 'session_storage.dart';


class SqlStorage implements SessionStorage {
  SqlStorage(this.tableName, this.sqlExecute, this.sqlSelect);

  final String tableName;
  final FutureOr<void> Function(String sql) sqlExecute;
  final FutureOr<Iterable<Map<String, Object?>>?> Function(String sql) sqlSelect;

  Future<void> createTable() async {
    await sqlExecute("CREATE TABLE IF NOT EXISTS `$tableName` (`id` TEXT NOT NULL, "
        "`expires` INTEGER NOT NULL, `data` TEXT NOT NULL, PRIMARY KEY (`id`));");
  }

  @override
  Future<void> clearOutdated() async {
    final now = DateTime.now().microsecondsSinceEpoch;
    await sqlExecute("DELETE FROM $tableName WHERE expires < $now;");
  }

  @override
  Future<void> deleteSession(String sessionId) async {
    await sqlExecute("DELETE FROM $tableName WHERE id='$sessionId';");
  }

  @override
  Future<Session?> getSession(String sessionId) async {
    final results = await sqlSelect("SELECT * FROM $tableName WHERE id='$sessionId';");
    if (results != null && results.isNotEmpty) {
      final result = results.first;
      return Session.fromMap({
        "id": result["id"],
        "expires": result["expires"],
        "data":
            json.decode(result["data"] as String, reviver: Session.reviver) as Map<String, dynamic>
      });
    }

    return null;
  }

  @override
  Future<void> saveSession(Session session, String sessionId) async {
    final dataString = json.encode(session.data, toEncodable: Session.toEncodable);
    if (await sessionExist(sessionId)) {
      await sqlExecute("UPDATE $tableName SET expires=${session.expires.microsecondsSinceEpoch}, "
          "data='$dataString' WHERE id='$sessionId';");
    } else {
      await sqlExecute("INSERT INTO $tableName (id, expires, data) "
          "VALUES ('$sessionId', ${session.expires.microsecondsSinceEpoch}, '$dataString');");
    }
  }

  @override
  Future<bool> sessionExist(String sessionId) async {
    final results = await sqlSelect("SELECT * FROM $tableName WHERE id='$sessionId';");
    return results != null && results.isNotEmpty;
  }
}

class SqlCryptoStorage implements SessionStorage {
  SqlCryptoStorage(this.tableName, this.sqlExecute, this.sqlSelect, this.algorithm, this.secretKey);

  Cipher algorithm;
  SecretKey secretKey;
  final String tableName;
  final FutureOr<void> Function(String sql) sqlExecute;
  final FutureOr<Iterable<Map<String, Object?>>?> Function(String sql) sqlSelect;

  Future<void> createTable() async {
    await sqlExecute("CREATE TABLE IF NOT EXISTS `$tableName` (`id` TEXT NOT NULL, "
        "`nonce` TEXT NOT NULL, `cipherText` TEXT NOT NULL, `mac` TEXT NOT NULL, "
        "PRIMARY KEY (`id`));");
  }

  @override
  Future<void> clearOutdated() async {
    final now = DateTime.now();
    final results = await sqlSelect("SELECT * FROM $tableName");
    if (results == null || results.isEmpty) {
      return;
    }
    final List<Future<void>> deletions = [];

    for (var result in results) {
      final secretBox = SecretBox(
        base64.decode(result['cipherText'] as String),
        nonce: base64.decode(result['nonce'] as String),
        mac: Mac(base64.decode(result['mac'] as String)),
      );
      final clearText = await algorithm.decryptString(
        secretBox,
        secretKey: secretKey,
      );
      final session = Session.fromJson(clearText);
      if (session.expires.compareTo(now) < 0) {
        deletions.add(deleteSession(session.id));
      }
    }

    await Future.wait(deletions);
  }

  @override
  Future<void> deleteSession(String sessionId) async {
    await sqlExecute("DELETE FROM $tableName WHERE id='$sessionId';");
  }

  @override
  Future<Session?> getSession(String sessionId) async {
    final results = await sqlSelect("SELECT * FROM $tableName WHERE id='$sessionId';");
    if (results != null && results.isNotEmpty) {
      final result = results.first;
      final secretBox = SecretBox(
        base64.decode(result['cipherText'] as String),
        nonce: base64.decode(result['nonce'] as String),
        mac: Mac(base64.decode(result['mac'] as String)),
      );
      final clearText = await algorithm.decryptString(
        secretBox,
        secretKey: secretKey,
      );
      return Session.fromJson(clearText);
    }

    return null;
  }

  @override
  Future<void> saveSession(Session session, String sessionId) async {
    final clearText = session.toJson();
    final secretBox = await algorithm.encryptString(
      clearText,
      secretKey: secretKey,
    );
    if (await sessionExist(sessionId)) {
      await sqlExecute("UPDATE $tableName SET nonce='${base64.encode(secretBox.nonce)}', "
          "cipherText='${base64.encode(secretBox.cipherText)}', "
          "mac='${base64.encode(secretBox.mac.bytes)}' WHERE id='$sessionId';");
    } else {
      await sqlExecute("INSERT INTO $tableName (id, nonce, cipherText, mac) "
          "VALUES ('$sessionId', '${base64.encode(secretBox.nonce)}', "
          "'${base64.encode(secretBox.cipherText)}', '${base64.encode(secretBox.mac.bytes)}');");
    }
  }

  @override
  Future<bool> sessionExist(String sessionId) async {
    final results = await sqlSelect("SELECT * FROM $tableName WHERE id='$sessionId';");
    return results != null && results.isNotEmpty;
  }
}
