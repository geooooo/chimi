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
      <div class="controls__button" title="Удалить контакт">
        <i class="deleteButton material-icons" data-login="{login}">delete</i>
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
    contactsElement.querySelectorAll('.deleteButton').forEach((Element button) {
      button.onClick.listen((MouseEvent event) async {
        await HttpRequest.request(
          '${Context.href}/contact',
          method: 'DELETE',
          sendData: json.encode(<String, String>{
            'login_owner': window.sessionStorage['login'],
            'login_friend': button.dataset['login']
          }),
        );
        button.parent.parent.parent.remove();
      });
    });
  });

}
