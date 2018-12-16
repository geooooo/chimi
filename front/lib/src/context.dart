import 'router.dart';


/// Контекст для взаимодействия с клиентом и сервером
class Context {

  final Router router;
  static const href = 'http://localhost:8082';

  Context(this.router);

}
