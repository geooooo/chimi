import 'package:front/src/router.dart';

import 'src/about.dart';
import 'src/addContact.dart';
import 'src/chat.dart';
import 'src/contacts.dart';
import 'src/login.dart';
import 'src/menu.dart';
import 'src/messages.dart';
import 'src/profile.dart';
import 'src/registration.dart';


typedef _PageCallback = void Function(Router router);

final pages = <String, _PageCallback>{
  'about': (router) => about(router),
  'profile': (router) => profile(router),
  'addContact': (router) => addContact(router),
  'messages': (router) => messages(router),
  'contacts': (router) => contacts(router),
  'registration': (router) => registration(router),
  'login': (router) => login(router),
  'chat': (router) => chat(router),
  'menu': (router) => menu(router),
};
