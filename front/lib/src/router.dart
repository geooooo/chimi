import 'dart:html';

import 'context.dart';
import 'spinner.dart';


/// Роутинг и навигация для обеспечения SPA
class Router {

  Map<String, dynamic> _routes;
  Spinner _spinner;
  Context _context;

  Router(Map<String, dynamic> routes) {
    this._spinner = Spinner();
    this._routes = routes;
    this._context = Context(this);
  }

  /// Переход на страницу по указаному роуту [route]
  Future<void> go(String path) async {
    this._spinner.show();
    // window.history.replaceState(null, path, path);
    // Получение адреса запроса по заданому роуту
    final pathParts = path.split('/');
    final routerDepth = pathParts.length;
    Map<String, dynamic> route = this._routes;
    for (var i = 0; i < routerDepth; i++) {
      route = (route.containsKey('_child')) ?
        route['_child'][pathParts[i]] :
        route[pathParts[i]];
    }
    // Получение контента новой страницы
    final href = route['_href'];
    final pageData = await HttpRequest.getString(href);
    // Добавление контента на страницу
    HtmlElement routerElement = querySelector('.router');
    for (var i = 1; i < routerDepth; i++) {
      routerElement = routerElement.querySelector('.router');
    }
    routerElement.innerHtml = pageData;
    route['_callback'](this._context);
    this._spinner.hide();
  }

}
