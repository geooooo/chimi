import 'src/main_server.dart';


/// Запуск серверной части
void run() {
  (() async {
    await MainServer.run();
    print('Основной сервер запущен...');
    print('Нажмите CTRL+C для завершения работы');
  }());
}
