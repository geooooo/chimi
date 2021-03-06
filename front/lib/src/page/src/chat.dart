import 'dart:html';
import 'dart:convert';

import 'package:front/src/context.dart';


void chat(Context context) {

  final InputElement messageInput = querySelector('#messageInput');
  final sendButton = querySelector('#sendButton');
  final chatElement = querySelector('#chatElement');

  context.openSocket();
  context.socket.onOpen.listen(
    (_) => context.socket.send('in ${window.sessionStorage['login']}-${window.sessionStorage['login_friend']}')
  );
  context.socket.onMessage.listen((MessageEvent event) {
    final data = (event.data as String).split(' ');
    final eventName = data[0];
    final params = data.sublist(1);
    switch (eventName) {
      case 'write':
        final text = params.join(' ');
        chatElement.innerHtml += createMessage(text, 2);
        chatElement.children.last.scrollIntoView();
        break;
    }
  });

  getMessages(chatElement);

  sendButton.onClick.listen((MouseEvent event) async {
    event.preventDefault();
    final message = messageInput.value.trim();
    messageInput.value = '';
    if (message.isEmpty) return;
    context.socket.send('write ${window.sessionStorage['login']}-${window.sessionStorage['login_friend']} $message');
    chatElement.innerHtml += createMessage(message, 1);
    chatElement.children.last.scrollIntoView();
  });

}

/// Создать сообщение с текстом [text] от пользователя с номером [personNumber]
String createMessage(String text, int personNumber) {
  return '''
    <li class="chat__message chat__message_person-${personNumber}">
      <div class="chat__text">${text}</div>
    </li>
  ''';
}

/// Получение старых сообщений
Future<void> getMessages(Element chatElement) async {

  final uri = Uri.parse(Context.href).replace(
    path: '/oldmessages',
    queryParameters: {
      'login_owner': window.sessionStorage['login'],
      'login_friend': window.sessionStorage['login_friend'],
    },
  );

  HttpRequest.request(
    uri.toString(),
    method: "get",
  ).then((HttpRequest request) {
    final response = request.response.toString();
    if (response.isEmpty) return;
    final responseData = json.decode(response);
    for (var message in responseData) {
      chatElement.innerHtml += createMessage(message['text'], message['person']);
    }
    if (!chatElement.children.isEmpty) {
      chatElement.children.last.scrollIntoView();
    }
  });

}
