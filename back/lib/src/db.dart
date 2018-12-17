import 'dart:io';

import 'package:sqlite2/sqlite.dart';


/// Интерфейс для хранения и доступа к данным
class Db {

  static Db _instance;
  String _fileName;
  Database _db;

  /// Создание бд в файле [fileName] и соединение
  static Future<Db> connect([String fileName = 'data.sqlite']) async {
    if (Db._instance == null) {
      Db._instance = Db();
      Db._instance._fileName = fileName;
      Db._instance._db = Database(fileName);
      final fileStat = await File(fileName).stat();
      if (fileStat.size == 0) {
        await Db._instance._create();
      }
    }
    return Db._instance;
  }

  /// Закрытие соединения с БД
  void close() {
    this.close();
  }

  /// Создание таблиц БД
  Future<void> _create() async {
    await this._db.execute('''
      CREATE TABLE user (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        login TEXT NOT NULL UNIQUE,
        password TEXT NOT NULL,
        avatar_path TEXT NOT NULL
      )''');
    await this._db.execute('''
      CREATE TABLE message (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        text TEXT NOT NULL,
        time INTEGER NOT NULL,
        user_owner_id INTEGER NOT NULL,
        user_friend_id INTEGER NOT NULL,
        FOREIGN KEY(user_owner_id) REFERENCES user(id),
        FOREIGN KEY(user_friend_id) REFERENCES user(id)
      )''');
    await this._db.execute('''
      CREATE TABLE message_waiting (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        count INTEGER NOT NULL,
        user_owner_id INTEGER NOT NULL,
        user_friend_id INTEGER NOT NULL,
        FOREIGN KEY(user_owner_id) REFERENCES user(id),
        FOREIGN KEY(user_friend_id) REFERENCES user(id)
      )''');
    await this._db.execute('''
      CREATE TABLE contact (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_owner_id INTEGER NOT NULL,
        user_friend_id INTEGER NOT NULL,
        FOREIGN KEY(user_owner_id) REFERENCES user(id),
        FOREIGN KEY(user_friend_id) REFERENCES user(id)
      )''');
  }

  /// Авторизация пользователя
  Future<Map<String, dynamic>> login(String login, String password) async {
    final result = <String, dynamic>{
      'success': false,
      'avatar_path': '',
    };
    final queryResult = await this._db.query('''
      SELECT
        avatar_path
      FROM
        user
      WHERE
        login = '${login}' AND
        password = '${password}'
    ''').toList();
    if (!queryResult.isEmpty) {
      result['success'] = true;
      result['avatar_path'] = queryResult[0]['avatar_path'];
    }
    return result;
  }

  /// Проверка существования пользователя с указаным логином [login]
  Future<bool> existsLogin(String login) async {
    final queryResult = await this._db.query('''
      SELECT
        id
      FROM
        user
      WHERE
        login = '${login}'
    ''').toList();
    return !queryResult.isEmpty;
  }

  /// Регистрация нового пользователя
  Future<bool> registration(String login, String password, String avatarPath) async {
    if (await this.existsLogin(login)) {
      return false;
    }
    await this._db.execute('''
      INSERT INTO user
        (login, password, avatar_path)
      VALUES
        ('${login}', '${password}', '${avatarPath}')
    ''');
    return true;
  }

  /// Получение информации о профиле пользователя
  Future<Map<String, String>> profile(String login) async {
    final queryResult = await this._db.query('''
      SELECT
        avatar_path
      FROM
        user
      WHERE
        login = '${login}'
    ''').toList();
    return {
      'avatar_path': queryResult[0]['avatar_path'],
    };
  }

  /// Получение идентификатора пользователя по его логину [login]
  Future<int> _userIdByLogin(String login) async {
    final queryResult = await this._db.query('''
      SELECT
        id
      FROM
        user
      WHERE
        login = '${login}'
    ''').toList();
    return queryResult[0][0];
  }

  /// Проверка наличия в друзьях пользователя с идентификатором
  /// [idFriend] у пользователя [idOwner]
  Future<bool> _hasFriend(int idOwner, int idFriend) async {
    final queryResult = await this._db.query('''
      SELECT
        id
      FROM
        contact
      WHERE
        user_owner_id = $idOwner AND
        user_friend_id = $idFriend
    ''').toList();
    return !queryResult.isEmpty;
  }

  /// Добавление пользователя с логином [loginFriend] в список
  /// контактов [loginOwner]
  Future<bool> addContact(String loginOwner, String loginFriend) async {
    if (loginFriend == loginOwner) return false;
    if (!(await this.existsLogin(loginFriend))) {
      return false;
    }
    var idOwner = await this._userIdByLogin(loginOwner);
    var idFriend = await this._userIdByLogin(loginFriend);
    if (await this._hasFriend(idOwner, idFriend)) {
      return false;
    }
    await this._db.execute('''
      INSERT INTO contact
        (user_owner_id, user_friend_id)
      VALUES
        ($idOwner, $idFriend)
    ''');
    await this._db.execute('''
      INSERT INTO contact
        (user_owner_id, user_friend_id)
      VALUES
        ($idFriend, $idOwner)
    ''');
    return true;
  }

  /// Получение списка контактов пользователя с логином [login]
  Future<List<Map<String, String>>> contacts(String login) async {
    final result = <Map<String, String>>[];
    final ownerId = await this._userIdByLogin(login);
    final queryResult = await this._db.query('''
      SELECT
        login,
        avatar_path
      FROM
        user
      INNER JOIN contact
      ON contact.user_owner_id = $ownerId
      WHERE
        user.id = contact.user_friend_id
    ''').toList();
    for (var row in queryResult) {
      result.add({
        'login': row['login'],
        'avatar_path': row['avatar_path'],
      });
    }
    return result;
  }

  /// Получение списка сообщений для пользователя с логином [login]
  Future<List<Map<String, String>>> messages(String login) async {
    final result = <Map<String, String>>[];
    final ownerId = await this._userIdByLogin(login);
    final queryResult = await this._db.query('''
      SELECT
        user.login,
        user.avatar_path,
        message_waiting.count
      FROM
        user
      INNER JOIN
        contact
      ON
        contact.user_friend_id = $ownerId
      INNER JOIN
        message_waiting
      ON
        message_waiting.user_friend_id = $ownerId
      WHERE
        user.id = contact.user_owner_id AND
        user.id = message_waiting.user_owner_id AND
        message_waiting.count > 0
    ''').toList();
    for (var row in queryResult) {
      result.add({
        'login': row['login'],
        'avatar_path': row['avatar_path'],
        'count': row['count'].toString(),
      });
    }
    return result;
  }

  /// Удаление пользователя с логином [loginFriend] из списка друзей [loginOwner]
  Future<bool> deleteContact(String loginOwner, String loginFriend) async {
    final idOwner = await this._userIdByLogin(loginOwner);
    final idFriend = await this._userIdByLogin(loginFriend);
    await this._db.execute('''
      DELETE FROM
        contact
      WHERE
        user_owner_id = '${idOwner}' AND user_friend_id = '${idFriend}' OR
        user_owner_id = '${idFriend}' AND user_friend_id = '${idOwner}'
    ''');
    await this._db.execute('''
      DELETE FROM
        message_waiting
      WHERE
        user_owner_id = '${idOwner}' AND user_friend_id = '${idFriend}' OR
        user_owner_id = '${idFriend}' AND user_friend_id = '${idOwner}'
    ''');
    await this._db.execute('''
      DELETE FROM
        message
      WHERE
        user_owner_id = '${idOwner}' AND user_friend_id = '${idFriend}' OR
        user_owner_id = '${idFriend}' AND user_friend_id = '${idOwner}'
    ''');
    return true;
  }

  /// Удаление записи о непрочитанных сообщениях от пользователя [loginOwner] у [loginFriend]
  Future<bool> readMessage(String loginOwner, String loginFriend) async {
    final idOwner = await this._userIdByLogin(loginOwner);
    final idFriend = await this._userIdByLogin(loginFriend);
    await this._db.execute('''
      UPDATE
        message_waiting
      SET
        count = 0
      WHERE
        user_owner_id = '${idOwner}' AND user_friend_id = '${idFriend}'
    ''');
    return true;
  }

  /// Получение списка сообщений чата пользователей [loginOwner] и [loginFriend]
  Future<List<Map<String, dynamic>>> chatMessages(String loginOwner, String loginFriend) async {
    final result = <Map<String, dynamic>>[];
    final idOwner = await this._userIdByLogin(loginOwner);
    final idFriend = await this._userIdByLogin(loginFriend);
    final queryResult = await this._db.query('''
      SELECT
        user_owner_id as id,
        text
      FROM
        message
      WHERE
        user_owner_id = '${idOwner}' AND user_friend_id = '${idFriend}' OR
        user_owner_id = '${idFriend}' AND user_friend_id = '${idOwner}'
      ORDER BY
        time
    ''').toList();
    for (var row in queryResult) {
      result.add({
        'person': (row['id'] == idOwner)? 1 : 2,
        'text': row['text'],
      });
    }
    return result;
  }

  /// Запись сообщения [message] от пользователя [loginOwner] для [loginFriend]
  Future<bool> writeMessage(String loginOwner, String loginFriend, String message, bool isInc) async {
    final idOwner = await this._userIdByLogin(loginOwner);
    final idFriend = await this._userIdByLogin(loginFriend);
    final time = DateTime.now().millisecondsSinceEpoch;
    await this._db.execute('''
      INSERT INTO message
        (user_owner_id, user_friend_id, text, time)
      VALUES
        ($idOwner, $idFriend, '$message', $time)
    ''');
    if (!isInc) return true;
    final queryResult = await this._db.query('''
      SELECT
        id
      FROM
        message_waiting
      WHERE
        user_owner_id = '${idOwner}' AND user_friend_id = '${idFriend}'
    ''').toList();
    if (queryResult.isEmpty) {
      await this._db.execute('''
        INSERT INTO message_waiting
          (user_owner_id, user_friend_id, count)
        VALUES
          ($idOwner, $idFriend, 1)
      ''');
    } else {
      await this._db.execute('''
        UPDATE
          message_waiting
        SET
          count = count + 1
        WHERE
          user_owner_id = '${idOwner}' AND user_friend_id = '${idFriend}'
      ''');
    }
    return true;
  }

}
