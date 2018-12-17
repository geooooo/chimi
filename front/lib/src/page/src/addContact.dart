import 'dart:html';
import 'dart:convert';

import 'package:front/src/context.dart';


void addContact(Context context) {

  final InputElement loginInput = querySelector('#loginInput');
  final addButton = querySelector('#addButton');
  final errorElement = querySelector('#errorMessage');

  addButton.onClick.listen((MouseEvent event) async {
    event.preventDefault();
    final request = await HttpRequest.request(
      '${Context.href}/contact',
      method: 'post',
      sendData: json.encode(<String, String> {
        'login_owner': window.sessionStorage['login'],
        'login_friend': loginInput.value,
      })
    );
    final response = request.response.toString();
    if (response == 'false') {
      errorElement.text = 'Ошибка при добавлении пользователя !';
      errorElement.classes.add('login-form__error-message_show');
      return;
    }
    errorElement.classes.remove('login-form__error-message_show');
    window.alert('Пользователь успешно добавлен !');
    loginInput.value = '';
  });

}
