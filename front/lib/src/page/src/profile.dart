import 'dart:html';

import 'package:front/src/context.dart';


void profile(Context context) {

  final ImageElement profileAvatar = querySelector('#profileAvatar');
  profileAvatar.src = window.sessionStorage['avatar_path'];

  final profileLogin = querySelector('#profileLogin');
  profileLogin.text = window.sessionStorage['login'];

}
