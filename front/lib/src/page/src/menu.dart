import 'dart:html';

import 'package:front/src/context.dart';


void menu(Context context) {

  final ImageElement userAvatar = querySelector('#userAvatar');
  userAvatar.src = window.sessionStorage['avatar_path'];

  final linkProfile = querySelector('#linkProfile');
  final linkContact = querySelector('#linkContact');
  final linkMessage = querySelector('#linkMessage');
  final linkAddContact = querySelector('#linkAddContact');
  final linkAbout = querySelector('#linkAbout');
  var activeLink = linkProfile;

  linkAbout.onClick.listen((MouseEvent event) async {
    await go(context, 'about', event, activeLink, linkAbout);
    activeLink = linkAbout;
  });

  linkProfile.onClick.listen((MouseEvent event) async {
    await go(context, 'profile', event, activeLink, linkProfile);
    activeLink = linkProfile;
  });

  linkContact.onClick.listen((MouseEvent event) async {
    await go(context, 'contacts', event, activeLink, linkContact);
    activeLink = linkContact;
  });

  linkMessage.onClick.listen((MouseEvent event) async {
    await go(context, 'messages', event, activeLink, linkMessage);
    activeLink = linkMessage;
  });

  linkAddContact.onClick.listen((MouseEvent event) async {
    await go(context, 'addContact', event, activeLink, linkAddContact);
    activeLink = linkAddContact;
  });

  activeLink.classes.add('menu__item_active');
  activeLink.click();

}

/// Переход на другую страницу
Future<void> go(Context context,
                String page,
                MouseEvent event,
                HtmlElement activeLink
                HtmlElement link) async {
  event.preventDefault();
  activeLink.classes.remove('menu__item_active');
  link.classes.add('menu__item_active');
  await context.router.go('menu/$page');
}
