import 'dart:html';
import 'dart:convert';

import 'package:front/src/context.dart';


void registration(Context context) {

  // Получение ссылок на элементы
  final InputElement loginInput = querySelector('#loginInput');
  final InputElement passwordInput = querySelector('#passwordInput');
  final InputElement passwordRepeatInput = querySelector('#passwordRepeatInput');
  final FileUploadInputElement fileInput = querySelector('#fileInput');
  final avatarLabel = querySelector('#avatarLabel');
  final avatarElement = querySelector('#avatarElement');
  final regButton = querySelector('#regButton');
  final errorElement = querySelector('#errorMessage');
  final yearElement = querySelector('#nowYear');
  final loadedImage = <String, dynamic>{
    'name': '',
    'data': null,
  };

  // Получение текущего года
  yearElement.text = DateTime.now().year.toString();

  avatarElement.onClick.listen((MouseEvent _) => loadImage(loadedImage, fileInput, avatarElement));
  avatarLabel.onClick.listen((MouseEvent _) => loadImage(loadedImage, fileInput, avatarElement));

  // Нажатие на кнопку регистрации
  regButton.onClick.listen((MouseEvent event) async {
    event.preventDefault();
    final login = loginInput.value;
    final password = passwordInput.value;
    final passwordRepeat = passwordRepeatInput.value;
    if (login.isEmpty || password.isEmpty || passwordRepeat.isEmpty) {
      errorElement.text = 'Заполните все поля !';
      errorElement.classes.add('registration-form__error-message_show');
      return;
    }
    if (!isValidLogin(login)) {
      errorElement.text = 'Логин должен состоять хотябы из 2 букв !';
      errorElement.classes.add('registration-form__error-message_show');
      return;
    }
    if (!isValidPassword(password)) {
      errorElement.text = 'Пароль должен состоять из цифр и букв и его длинна больше 5 символов !';
      errorElement.classes.add('registration-form__error-message_show');
      return;
    }
    if (password != passwordRepeat) {
      errorElement.text = 'Введёные пароли не совпадают !';
      errorElement.classes.add('registration-form__error-message_show');
      return;
    }
    final data = FormData();
    data.append('login', login);
    data.append('password', password);
    data.appendBlob('avatar', fileInput.files.first);
    final request = await HttpRequest.request(
      '${Context.href}/registration',
      method: 'post',
      sendData: data,
    );
     final response = request.response.toString();
    final responseData = json.decode(response);
    errorElement.classes.remove('registration-form__error-message_show');
    window.sessionStorage['avatar_path'] = '${Context.href}/${responseData['avatar_path']}';
    window.sessionStorage['login'] = login;
    await context.router.go('menu');
  });

}

/// Выбор и загрузка аватара пользователя
Future<void> loadImage(Map<String, dynamic> image,
                       FileUploadInputElement fileInput,
                       HtmlElement avatarElement) async {

  fileInput.click();

  final reader = FileReader();
  fileInput.onChange.listen((Event event) {
    if (fileInput.files.isEmpty) return;
    image['name'] = fileInput.files.first.name;
    reader.onLoad.listen((ProgressEvent event) {
      avatarElement.style.backgroundImage = 'url(${reader.result})';
    });
    reader.readAsDataUrl(fileInput.files.first);
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
