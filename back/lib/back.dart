import 'package:ansicolor/ansicolor.dart';

import 'src/main_server.dart';


/// Запуск серверной части
void run() {
  (() async {
    await MainServer.run();
    final pen = AnsiPen()..yellow();
    print('Нажмите ${pen('CTRL+C')} для завершения работы\n');
  }());
}
