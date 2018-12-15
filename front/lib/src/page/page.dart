import 'package:front/src/context.dart';

import 'src/about.dart';
import 'src/addContact.dart';
import 'src/chat.dart';
import 'src/contacts.dart';
import 'src/login.dart';
import 'src/menu.dart';
import 'src/messages.dart';
import 'src/profile.dart';
import 'src/registration.dart';


typedef _PageCallback = void Function(Context context);

final pages = <String, _PageCallback>{
  'about': about,
  'profile': profile,
  'addContact': addContact,
  'messages': messages,
  'contacts': contacts,
  'registration': registration,
  'login': login,
  'chat': chat,
  'menu': menu,
};
