import 'dart:html';
import 'dart:convert';

import 'package:front/src/context.dart';


void login(Context context) {

  //NOTE:
  /*(() async {
    final data = json.encode({
      'login': 'vasia',
      'password': '123456',
    });
    final request = await HttpRequest.request(
      '${Context.href}/login',
      method: 'post',
      sendData: data,
    );
    final response = request.response.toString();
    final responseData = json.decode(response);
    window.sessionStorage['avatar_path'] = '${Context.href}/${responseData['avatar_path']}';
    window.sessionStorage['login'] = 'vasia';
    await context.router.go('menu');
  }());
  return;*/

  // Получение ссылок на элементы
  final InputElement loginInput = querySelector('#loginInput');
  final InputElement passwordInput = querySelector('#passwordInput');
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
    final login = loginInput.value.trim();
    final password = passwordInput.value.trim();
    if (login.isEmpty || password.isEmpty) {
      errorElement.text = 'Заполните все поля !';
      errorElement.classes.add('login-form__error-message_show');
      return;
    }
    if (!isValidLogin(login)) {
      errorElement.text = 'Логин должен состоять хотябы из 2 букв !';
      errorElement.classes.add('login-form__error-message_show');
      return;
    }
    if (!isValidPassword(password)) {
      errorElement.text = 'Пароль должен состоять из цифр и букв и его длинна больше 5 символов !';
      errorElement.classes.add('login-form__error-message_show');
      return;
    }
    final data = json.encode({
      'login': login,
      'password': password,
    });
    final request = await HttpRequest.request(
      '${Context.href}/login',
      method: 'post',
      sendData: data,
    );
    final response = request.response.toString();
    if (response.isEmpty) {
      errorElement.text = 'Неправильный логин или пароль !';
      errorElement.classes.add('login-form__error-message_show');
      return;
    }
    errorElement.classes.remove('login-form__error-message_show');
    final responseData = json.decode(response);
    window.sessionStorage['avatar_path'] = '${Context.href}/${responseData['avatar_path']}';
    window.sessionStorage['login'] = login;
    await context.router.go('menu');
  });

}

/// Проверка валидности логина [value]
bool isValidLogin(String value) {
  return RegExp(r'^\w{2,}$').hasMatch(value);
}

/// Проверка валидности пароля [value]
bool isValidPassword(String value) {
  return (value.length >= 6) && RegExp(r'[\d\w]+').hasMatch(value);
}
