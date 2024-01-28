## 0.2.0
- new abstract class `SessionStorage`.
- rewrite the original way of storing sessions in a Map into an implementation, `MemoryStorage`.
- other implementations to store sessions in files or SQL databases as plain or encrypted text: 
-- `FileStorage`, `FileStorage.plain`, `FileStorage.crypto`, `SqlStorage` and `SqlCryptoStorage`.
- corresponding updates: the example has been updated, and some methods were turned into asynchronous ones.
- other minor changes.

## 0.1.2

- Added some documentation.

## 0.1.1

- Added static extension method `removeCookie(Cookie cookie)` to the `Request` class.

## 0.1.0

- Initial release.