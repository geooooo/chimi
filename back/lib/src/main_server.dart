import 'dart:io';

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
      request.response.headers.add('Access-Control-Allow-Origin', '*');
      await this._routing(request);
      await request.response.close();
    });
  }

  /// Роутинг запросов
  Future<void> _routing(HttpRequest request) async {
    request.response.statusCode = 200;
    if (await this._pageRouting(request)) return;
    if (await this._restAPI(request)) return;
    request.response.statusCode = 404;
  }

  /// Роутинг страниц
  Future<bool> _pageRouting(HttpRequest request) async {
    final isPage = (request.method.toLowerCase() == 'get') &&
                   (request.uri.path.indexOf(RegExp(r'/page/')) != -1);
    if (!isPage) return false;
    final pageName = request.uri.path.split(RegExp(r'^/page/'))
                                .last.split('/').last;
    print('<<< page "$pageName"');
    final fileData = await File('page/${pageName}.html').readAsBytes();
    request.response.headers.contentType = ContentType.html;
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
    // Отправка данных для входа в приложение
    if ((request.method.toLowerCase() == 'post') &&
        (request.uri.path.indexOf('/login') == 0))
    {
      return true;
    }
    // Отправка данных для регистрации
    if ((request.method.toLowerCase() == 'post') &&
        (request.uri.path.indexOf('/registration') == 0))
    {
      final parsedBody = await parseBody(request);
      final login = parsedBody.body['login'].toString().trim();
      final password = parsedBody.body['password'].toString().trim();
      final avatarFile = await parsedBody.files.first;
      final avatarPath = 'uploads/${randomAlpha(10) + DateTime.now().millisecondsSinceEpoch.toString()}.${avatarFile.filename.split('.')[1]}';
      await File(avatarPath).writeAsBytes(avatarFile.data);
      if (!this._isValidLogin(login) || !this._isValidPassword(password)) {
        return false;
      }
      return await this._db.registration(login, password, avatarPath);
    }
    // Получение информации о профиле пользователя
    if ((request.method.toLowerCase() == 'get') &&
        (request.uri.path.indexOf('/profile') == 0))
    {
      return true;
    }
    // Получение списка контактов пользователя
    if ((request.method.toLowerCase() == 'get') &&
        (request.uri.path.indexOf('/contacts') == 0))
    {
      return true;
    }
    // Получение добавление пользователя в список контактов
    if ((request.method.toLowerCase() == 'post') &&
        (request.uri.path.indexOf('/add_contact') == 0))
    {
      return true;
    }
    return false;
  }

}
