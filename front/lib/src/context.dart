import 'dart:html';

import 'router.dart';


/// Контекст для взаимодействия с клиентом и сервером
class Context {

  Router router;
  WebSocket socket;
  bool closedSocket = true;
  static const href = 'http://localhost:8082';

  Context(this.router);

  /// Открытие веб сокета
  void openSocket() {
    this.closedSocket = false;
    final wsHref = 'ws://${Uri.parse(Context.href).host}:${Uri.parse(Context.href).port}/ws';
    this.socket = WebSocket(wsHref);
  }

  /// Закрытие веб сокета
  void closeSocket() {
    if (this.closedSocket) return;
    this.closedSocket = true;
    this.socket.send('out ${window.sessionStorage['login']}-${window.sessionStorage['login_friend']}');
    this.socket.close();
  }

}
