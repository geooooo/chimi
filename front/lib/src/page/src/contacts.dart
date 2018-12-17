import 'dart:html';
import 'dart:convert';

import 'package:front/src/context.dart';


const contactTemplate = '''
  <li class="contacts__item">
    <div class="user">
      <img class="user__avatar" src="" alt="Аватар" width="80" height="80">
      <div class="user__login">{login}</div>
    </div>
    <div class="controls">
      <div class="controls__button">
        <i class="writeButton material-icons" title="Написать сообщение" data-login="{login}">edit</i>
      </div>
      <div class="controls__button">
        <i class="deleteButton material-icons" title="Удалить контакт" data-login="{login}">delete</i>
      </div>
    </div>
  </li>
''';

void contacts(Context context) async {

  final uri = Uri.parse(Context.href).replace(
    path: '/contacts',
    queryParameters: {
      'login': window.sessionStorage['login']
    },
  );

  HttpRequest.request(
    uri.toString(),
    method: "get",
  ).then((HttpRequest request) {
    final responseData = json.decode(request.response.toString());
    final contactsElement = querySelector('#contactsElement');
    for (var contact in responseData) {
      contactsElement.setInnerHtml(
        contactsElement.innerHtml + contactTemplate.replaceAll('{login}', contact['login']),
        validator: NodeValidatorBuilder.common()..allowElement('i', attributes: ['data-login'])
      );
    }
    final List<ImageElement> imgs = contactsElement.querySelectorAll('img');
    for (var i = 0; i < imgs.length; i++) {
      imgs[i].src = '${Context.href}/${responseData[i]['avatar_path']}';
    }
    // Удаление контакта
    contactsElement.querySelectorAll('.deleteButton').forEach((Element button) {
      button.onClick.listen((MouseEvent event) async {
        await HttpRequest.request(
          '${Context.href}/contact',
          method: 'delete',
          sendData: json.encode(<String, String>{
            'login_owner': window.sessionStorage['login'],
            'login_friend': button.dataset['login']
          }),
        );
        button.parent.parent.parent.remove();
      });
    });
    // Написать сообщение
    contactsElement.querySelectorAll('.writeButton').forEach((Element button) {
      button.onClick.listen((MouseEvent event) async {
        await HttpRequest.request(
          '${Context.href}/read',
          method: 'post',
          sendData: json.encode(<String, String>{
            'login_owner': button.dataset['login'],
            'login_friend': window.sessionStorage['login']
          }),
        );
        window.sessionStorage['login_friend'] = button.dataset['login'];
        await context.router.go('menu/chat');
      });
    });
  });

}
