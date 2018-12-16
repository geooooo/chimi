import 'dart:io';
import 'dart:convert';

import 'package:body_parser/body_parser.dart';
import 'package:random_string/random_string.dart';

import 'db.dart';


/// Основной сервер, который отдаёт контент, работае с БД
class MainServer {

  static MainServer _instance;
  Db _db;
  int _port;
  HttpServer _httpServer;

  /// Запуск сервера на заданом порту [port]
  static Future<MainServer> run([int port = 8082]) async {
    if (MainServer._instance == null) {
      MainServer._instance = MainServer();
      MainServer._instance._port = port;
      MainServer._instance._httpServer = await HttpServer.bind(
        InternetAddress.loopbackIPv4,
        MainServer._instance._port
      );
      MainServer._instance._listen();
      MainServer._instance._db = await Db.connect();
    }
    return MainServer._instance;
  }

  /// Обработка запросов
  void _listen() {
    MainServer._instance._httpServer.listen((HttpRequest request) async {
      print('${request.method} ${request.uri.path}');
      request.response.statusCode = 200;
      request.response.headers.add('Access-Control-Allow-Origin', '*');
      request.response.headers.add('Access-Control-Allow-Methods', 'GET, POST, OPTIONS, DELETE');
      await this._routing(request);
      await request.response.close();
    });
  }

  /// Роутинг запросов
  Future<void> _routing(HttpRequest request) async {
    if (await this._pageRouting(request)) return;
    if (await this._uploadRouting(request)) return;
    if (await this._restAPI(request)) return;
  }

  /// Роутинг загруженных файлов
  Future<bool> _uploadRouting(HttpRequest request) async {
    final isUpload = (request.method.toLowerCase() == 'get') &&
                   (request.uri.path.indexOf(RegExp(r'/uploads/')) != -1);
    if (!isUpload) return false;
    final fileName = request.uri.path.split(RegExp(r'^/uploads/')).last;
    print('<<< uploads "$fileName"');
    final fileData = await File('uploads/$fileName').readAsBytes();
    request.response.add(fileData);
    return true;
  }

  /// Роутинг страниц
  Future<bool> _pageRouting(HttpRequest request) async {
    request.response.headers.contentType = ContentType.html;
    final isPage = (request.method.toLowerCase() == 'get') &&
                   (request.uri.path.indexOf(RegExp(r'/page/')) != -1);
    if (!isPage) return false;
    final pageName = request.uri.path.split(RegExp(r'^/page/'))
                                .last.split('/').last;
    print('<<< page "$pageName"');
    final fileData = await File('page/${pageName}.html').readAsBytes();
    request.response.add(fileData);
    return true;
  }

  /// Проверка валидности логина [value]
  bool _isValidLogin(String value) {
    return RegExp(r'^\w{2,}$').hasMatch(value);
  }

  /// Проверка валидности пароля [value]
  bool _isValidPassword(String value) {
    return (value.length >= 6) && RegExp(r'[\d\w]+').hasMatch(value);
  }

  /// Роутинг REST API
  Future<bool> _restAPI(HttpRequest request) async {
    request.response.headers.contentType = ContentType.json;
    // Отправка данных для входа в приложение
    if ((request.method.toLowerCase() == 'post') &&
        (request.uri.path.indexOf('/login') == 0))
    {
      final parsedBody = json.decode(Uri.decodeFull(await request.transform(Utf8Decoder()).join()));
      final login = parsedBody['login'].toString().trim();
      final password = parsedBody['password'].toString().trim();
      if (!this._isValidLogin(login) || !this._isValidPassword(password)) {
        return false;
      }
      final result = await this._db.login(login, password);
      if (result['success']) {
        request.response.write(json.encode({
          'avatar_path': result['avatar_path'],
        }));
      }
      return result['success'];
    }
    // Отправка данных для регистрации
    if ((request.method.toLowerCase() == 'post') &&
        (request.uri.path.indexOf('/registration') == 0))
    {
      final parsedBody = await parseBody(request);
      final login = parsedBody.body['login'].toString().trim();
      final password = parsedBody.body['password'].toString().trim();
      String avatarPath;
      if (parsedBody.files.isEmpty) {
        avatarPath = 'uploads/guest.png';
      } else {
        final avatarFile = await parsedBody.files.first;
        avatarPath = 'uploads/${randomAlpha(10) + DateTime.now().millisecondsSinceEpoch.toString()}.${avatarFile.filename.split('.')[1]}';
        await File(avatarPath).writeAsBytes(avatarFile.data);
      }
      if (!this._isValidLogin(login) || !this._isValidPassword(password)) {
        return false;
      }
      if (!(await this._db.registration(login, password, avatarPath))) {
        return false;
      }
      request.response.write(json.encode({
        'avatar_path': avatarPath,
      }));
      return true;
    }
    // Получение информации о профиле пользователя
    if ((request.method.toLowerCase() == 'get') &&
        (request.uri.path.indexOf('/profile') == 0))
    {
      final login = request.uri.queryParameters['login'];
      final result = await this._db.profile(login);
      request.response.write(json.encode({
        'avatar_path': result['avatar_path'],
      }));
      return true;
    }
    // Получение списка контактов пользователя
    if ((request.method.toLowerCase() == 'get') &&
        (request.uri.path.indexOf('/contacts') == 0))
    {
      final login = request.uri.queryParameters['login'];
      final result = await this._db.contacts(login);
      request.response.write(json.encode(result));
      return true;
    }
    // Получение добавление пользователя в список контактов
    if ((request.method.toLowerCase() == 'post') &&
        (request.uri.path.indexOf('/contact') == 0))
    {
      final parsedBody = json.decode(await request.transform(Utf8Decoder()).join());
      final loginOwner = parsedBody['login_owner'].toString().trim();
      final loginFriend = parsedBody['login_friend'].toString().trim();
      final result = await this._db.addContact(loginOwner, loginFriend);
      request.response.write(result);
      return result;
    }
    // Удаление пользователя из списка контактов
    if ((request.method.toLowerCase() == 'delete') &&
        (request.uri.path.indexOf('/contact') == 0))
    {
      final parsedBody = json.decode(await request.transform(Utf8Decoder()).join());
      final loginFriend = parsedBody['login_friend'].trim();
      final loginOwner = parsedBody['login_owner'].trim();
      return await this._db.deleteContact(loginOwner, loginFriend);
    }
    return false;
  }

}
