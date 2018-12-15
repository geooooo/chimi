import 'dart:html';

import 'package:front/src/context.dart';


void login(Context context) {

  // Получение ссылок на элементы
  final loginInput = querySelector('#loginInput');
  final passwordInput = querySelector('#passwordInput');
  final loginButton = querySelector('#loginButton');
  final regButton = querySelector('#regButton');
  final errorElement = querySelector('#errorMessage');
  final yearElement = querySelector('#nowYear');

  // Получение текущего года
  yearElement.text = DateTime.now().year.toString();

  // Нажатие на кнопку регистрации
  regButton.onClick.listen((MouseEvent event) async {
    event.preventDefault();
    await context.router.go('registration');
  });

  // Нажатие на кнопку логина
  loginButton.onClick.listen((MouseEvent event) async {
    event.preventDefault();
    // NOTE: проверка
    await context.router.go('menu');
  });

}
