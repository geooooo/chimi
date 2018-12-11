import 'src/router.dart';
import 'src/page/page.dart';


final _hostname = 'localhost:8081';

final router = Router({
  'login': {
    '_href': 'http://$_hostname/page/login',
    '_callback': pages['login'],
  },
  'registration': {
    '_href': 'http://$_hostname/page/registration',
    '_callback': pages['registration'],
  },
  'menu': {
    '_href': 'http://$_hostname/page/menu',
    '_callback': pages['menu'],
    '_child': {

      'about': {
        '_href': 'http://$_hostname/page/about',
        '_callback': pages['about'],
      },
      'contacts': {
        '_href': 'http://$_hostname/page/contacts',
        '_callback': pages['contacts'],
      },
      'profile': {
        '_href': 'http://$_hostname/page/profile',
        '_callback': pages['profile'],
      },
      'add': {
        '_href': 'http://$_hostname/page/add_contact',
        '_callback': pages['addContact'],
      },
      'chat': {
        '_href': 'http://$_hostname/page/chat',
        '_callback': pages['chat'],
      },
      'messages': {
        '_href': 'http://$_hostname/page/messages',
        '_callback': pages['messages'],
      },
    },
  },
});
