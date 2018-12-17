import 'dart:io';
import 'dart:convert';

import 'package:body_parser/body_parser.dart';
import 'package:random_string/random_string.dart';
import 'package:ansicolor/ansicolor.dart';

import 'db.dart';


/// Основной сервер, который отдаёт контент, работае с БД
class MainServer {

  static MainServer _instance;
  Db _db;
  int _port;
  HttpServer _httpServer;
  final Map<String, dynamic> _sockets = {};

  /// Запуск сервера на заданом порту [port]
  static Future<MainServer> run([int port = 8082]) async {
    if (MainServer._instance == null) {
      MainServer._instance = MainServer();
      MainServer._instance._port = port;
      MainServer._instance._httpServer = await HttpServer.bind(
        InternetAddress.loopbackIPv4,
        MainServer._instance._port
      );
      final pen = AnsiPen()..cyan();
      print('Главный сервер запущен на ${pen('localhost:' + port.toString())} ...');
      MainServer._instance._listen();
      MainServer._instance._db = await Db.connect();
    }
    return MainServer._instance;
  }

  /// Обработка запросов
  void _listen() {
    MainServer._instance._httpServer.listen((HttpRequest request) async {
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
    if (await this._websocketRouting(request)) return;
    if (await this._restAPI(request)) return;
  }

  /// Обработка соединений на веб сокетах
  Future<bool> _websocketRouting(HttpRequest request) async {
    if (!request.uri.path.startsWith('/ws')) return false;
    final ws = await WebSocketTransformer.upgrade(request);
    ws.listen((dynamic data) async {
      final splittedData = data.toString().split(' ');
      final event = splittedData[0];
      final params = splittedData.sublist(1);
      final mainPen = AnsiPen()..green(bg: true)..black();
      final eventPen = AnsiPen()..green();
      final paramsPen = AnsiPen()..blue();
      print('${mainPen('SOCKET:')} ${eventPen(event)} ${paramsPen(params.toString())}\n');
      switch (event) {
        // in sender-receiver
        case 'in':
          final logins = params[0].split('-');
          final sender = logins[0];
          final receiver = logins[1];
          final key1 = '$sender-$receiver';
          final key2 = '$receiver-$sender';
          if (this._sockets.containsKey(key1)) {
            this._sockets[key1][sender] = ws;
          } else if (this._sockets.containsKey(key2)) {
            this._sockets[key2][sender] = ws;
          } else {
            this._sockets[key1] = {
              sender: ws,
            };
          }
          break;
        // out sender-receiver
        case 'out':
          final logins = params[0].split('-');
          final sender = logins[0];
          final receiver = logins[1];
          final key1 = '$sender-$receiver';
          final key2 = '$receiver-$sender';
          if (this._sockets.containsKey(key1)) {
            (this._sockets[key1][sender] as WebSocket).close();
            (this._sockets[key1] as Map).remove(sender);
            if (!(this._sockets[key1] as Map).containsKey(receiver)) {
              this._sockets.remove(key1);
            }
          } else {
            (this._sockets[key2][sender] as WebSocket).close();
            (this._sockets[key2] as Map).remove(sender);
            if (!(this._sockets[key2] as Map).containsKey(receiver)) {
              this._sockets.remove(key2);
            }
          }
          break;
        // write sender-receiver message
        case 'write':
          final logins = params[0].split('-');
          final sender = logins[0];
          final receiver = logins[1];
          final text = params.sublist(1).join(' ');
          final key1 = '$sender-$receiver';
          final key2 = '$receiver-$sender';
          var isInc = true;
          if (this._sockets.containsKey(key1)) {
            if (this._sockets[key1].containsKey(receiver)) {
              this._sockets[key1][receiver].add('write $text');
              isInc = false;
            }
          } else if (this._sockets[key2].containsKey(receiver)) {
            this._sockets[key2][receiver].add('write $text');
            isInc = false;
          }
          await this._db.writeMessage(sender, receiver, text, isInc);
          break;
        case 'info':
          final socketPen = AnsiPen()..white(bg: true)..black();
          print('${socketPen(this._sockets.toString())}\n');
          break;
      }
    });
    return true;
  }

  /// Роутинг загруженных файлов
  Future<bool> _uploadRouting(HttpRequest request) async {
    final isUpload = (request.method.toLowerCase() == 'get') &&
                   (request.uri.path.indexOf(RegExp(r'/uploads/')) != -1);
    if (!isUpload) return false;
    final fileName = request.uri.path.split(RegExp(r'^/uploads/')).last;
    final penMain = AnsiPen()..cyan(bg: true)..black();
    final penMethod = AnsiPen()..red(bg: true);
    final penPath = AnsiPen()..red();
    print('${penMain('MAIN: STATIC')} ${penMethod(request.method)} ${penPath(request.uri.toString())}');
    final penPage = AnsiPen()..red();
    print('\t<<<uploads ${penPage(fileName)}\n');
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
    final penMain = AnsiPen()..cyan(bg: true)..black();
    final penMethod = AnsiPen()..red(bg: true);
    final penPath = AnsiPen()..red();
    print('${penMain('MAIN: STATIC')} ${penMethod(request.method)} ${penPath(request.uri.toString())}');
    final penPage = AnsiPen()..red();
    print('\t<<<page ${penPage(pageName)}\n');
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
    final penMain = AnsiPen()..cyan(bg: true)..black();
    final penMethod = AnsiPen()..magenta(bg: true);
    final penPath = AnsiPen()..magenta();
    print('${penMain('MAIN: API')} ${penMethod(request.method)} ${penPath(request.uri.path)}\n');
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
    // Добавление пользователя в список контактов
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
    // Получение списка контактов, от которых приходили сообщения
    if ((request.method.toLowerCase() == 'get') &&
        (request.uri.path.indexOf('/messages') == 0))
    {
      final login = request.uri.queryParameters['login'];
      final result = await this._db.messages(login);
      request.response.write(json.encode(result));
      return true;
    }
    // Отметка прочитанных сообщений
    if ((request.method.toLowerCase() == 'post') &&
        (request.uri.path.indexOf('/read') == 0))
    {
      final parsedBody = json.decode(await request.transform(Utf8Decoder()).join());
      final loginOwner = parsedBody['login_owner'].toString().trim();
      final loginFriend = parsedBody['login_friend'].toString().trim();
      await this._db.readMessage(loginOwner, loginFriend);
      return true;
    }
    // Получение сообщений чата
    if ((request.method.toLowerCase() == 'get') &&
        (request.uri.path.indexOf('/oldmessages') == 0))
    {
      final login_owner = request.uri.queryParameters['login_owner'];
      final login_friend = request.uri.queryParameters['login_friend'];
      final result = await this._db.chatMessages(login_owner, login_friend);
      request.response.write(json.encode(result));
      return true;
    }
    return false;
  }

}
