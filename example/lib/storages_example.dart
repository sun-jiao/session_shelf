import 'dart:io' show Directory;

import 'package:cryptography/cryptography.dart';
import 'package:mysql_client/mysql_client.dart';
import 'package:session_shelf/session_shelf.dart';
import 'package:sqlite3/sqlite3.dart' hide ResultSet;
import 'package:sqlite3/sqlite3.dart' as sqlite show ResultSet;

final algorithm = AesGcm.with256bits();
// This is just an example. Please DO NOT write your secret key in code.
// for example, use:
//    final secretKey = SecretKey(base64Decode(Platform.environment['shelf_session_key'].toString()));
final secretKey = SecretKey('--Session-Shelf--Session-Shelf--'.codeUnits);

final plainStorage = FileStorage.plain(Directory('session_shelf'));
final cryptoStorage = FileStorage.crypto(Directory('session_shelf'), algorithm, secretKey);

Future<SessionStorage> getSqliteStorage() async {
  final db = sqlite3.openInMemory();

  final sqliteStorage = SqlStorage('session_shelf', db.execute, (sql) {
    final sqlite.ResultSet resultSet = db.select(sql);
    return resultSet;
  });
  await sqliteStorage.createTable();
  return sqliteStorage;
}

Future<SessionStorage> getSqliteCryptoStorage() async {
  final db = sqlite3.openInMemory();

  final sqliteCryptoStorage = SqlCryptoStorage('session_shelf_crypto', db.execute, (sql) {
    final sqlite.ResultSet resultSet = db.select(sql);
    return resultSet;
  }, algorithm, secretKey);
  await sqliteCryptoStorage.createTable();
  return sqliteCryptoStorage;
}

Future<MySQLConnection> _conn() async {
  final conn = await MySQLConnection.createConnection(
    host: "127.0.0.1",
    port: 3306,
    userName: "user",
    password: "password",
    databaseName: "session_shelf_example", // optional
  );

  await conn.connect();

  return conn;
}

Future<SessionStorage> getMysqlStorage() async {
  final conn = await _conn();
  final mysqlStorage = SqlStorage('session_shelf', conn.execute, (sql) async {
    final resultSet = await conn.execute(sql);
    return resultSet.rows.map((row) =>
    {
      'id': row.colByName('id'),
      'expires': row.colByName('expires'),
      'data': row.colByName('data'),
    }).toList();
  });
  await mysqlStorage.createTable();
  return mysqlStorage;
}

Future<SessionStorage> getMysqlCryptoStorage() async {
  final conn = await _conn();
  final mysqlCryptoStorage = SqlCryptoStorage('session_shelf_crypto', conn.execute, (sql) async {
    final resultSet = await conn.execute(sql);
    return resultSet.rows.map((row) => {
      'id': row.colByName('id'),
      'cipherText': row.colByName('cipherText'),
      'nonce': row.colByName('nonce'),
      'mac': row.colByName('mac'),
    }).toList();
  }, algorithm, secretKey);
  await mysqlCryptoStorage.createTable();
  return mysqlCryptoStorage;
}
