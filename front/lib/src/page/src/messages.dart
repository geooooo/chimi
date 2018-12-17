import 'dart:html';
import 'dart:convert';

import 'package:front/src/context.dart';


const messageTemplate = '''
 <li class="messages__item" data-login="{login}">
    <div class="user">
      <img class="user__avatar" src="" alt="Аватра" width="80" height="80">
      <div class="user__login">{login}</div>
    </div>
    <div class="counter">
      <div class="counter__value counter__value_active">{messageCount}</div>
      <i class="material-icons">message</i>
    </div>
  </li>
''';

void messages(Context context) {

  final uri = Uri.parse(Context.href).replace(
    path: '/messages',
    queryParameters: {
      'login': window.sessionStorage['login']
    },
  );

  HttpRequest.request(
    uri.toString(),
    method: "get",
  ).then((HttpRequest request) {
    final responseData = json.decode(request.response.toString());
    final messagesElement = querySelector('#messagesElement');
    for (var contact in responseData) {
      final sign = (int.parse(contact['count'], radix: 10) > 0)? '+': '';
      messagesElement.setInnerHtml(
        messagesElement.innerHtml + messageTemplate.replaceAll('{login}', contact['login'])
                                                   .replaceFirst('{messageCount}', sign + contact['count']),
        validator: NodeValidatorBuilder.common()..allowElement('li', attributes: ['data-login'])
      );
    }
    final List<ImageElement> imgs = messagesElement.querySelectorAll('img');
    for (var i = 0; i < imgs.length; i++) {
      imgs[i].src = '${Context.href}/${responseData[i]['avatar_path']}';
    }
    // Перейти в чат
    messagesElement.querySelectorAll('.messages__item').forEach((Element message) {
      message.onClick.listen((MouseEvent event) async {
        await HttpRequest.request(
          '${Context.href}/read',
          method: 'post',
          sendData: json.encode(<String, String>{
            'login_owner': message.dataset['login'],
            'login_friend': window.sessionStorage['login']
          }),
        );
        window.sessionStorage['login_friend'] = message.dataset['login'];
        await context.router.go('menu/chat');
      });
    });
  });

}
