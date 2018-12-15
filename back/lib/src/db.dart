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
      'avatarPath': '',
    };
    final queryResult = await this._db.query('''
      SELECT
        id
      FROM
        user
      WHERE
        login = '${login}' AND
        password = '${password}'
    ''').first;
    return result; //TODO:
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
    final result = <String, String>{
      'avatarPath': '',
    };
    final queryResult = await this._db.query('''
      SELECT
        avatar_path
      FROM
        user
      WHERE
        login = '${login}'
    ''');
    return result; //TODO:
  }

  Future<int> _userIdByLogin(String login) async {
    final queryResult = await this._db.query('''
      SELECT
        id
      FROM
        user
      WHERE
        login = '${login}'
    ''');
    var id = 0; //TODO:
    return id;
  }

  /// Добавление пользователя с логином [loginFriend] в список
  /// контактов [loginOwner]
  Future<bool> addContact(String loginOwner, String loginFriend) async {
    if (!(await this.existsLogin(loginFriend))) {
      return false;
    }
    var idOwner = await this._userIdByLogin(loginOwner);
    var idFriend = await this._userIdByLogin(loginFriend);
    final queryResult = await this._db.query('''
      INSERT INTO contact
        (id_owner, id_friend)
      VALUES
        ($idOwner, $idFriend)
    ''');
    return false; //TODO:
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
    ''');
    return result; //TODO:
  }

  /// Получение списка сообщений для пользователя с логином [login]
  Future<List<Map<String, String>>> messages(String login) async {
    final result = <Map<String, String>>[];
    final ownerId = await this._userIdByLogin(login);
    final queryResult = await this._db.query('''
      SELECT
        user.login,
        user.avatar_path,
        message_waiting.count AS new_message_count
      FROM
        user
      INNER JOIN message
      ON message.user_owner_id = $ownerId
    ''');
    return result; //TODO:
  }

}

/*

user
  id int pk
  login str nn u
  password str nn
  avatar_path str nn

message
  id int pk
  text str nn
  user_owner_id int fk
  user_friend_id int fk
  time timestamp nn
n --- n

message_waiting
  id int pk
  user_owner_id int fk
  user_friend_id int fk
  count int nn
n --- n

contact
  id int pk
  user_owner_id int fk
  user_friend_id int fk
n --- n

*/
