import 'dart:html';


/// Спинер, отображаемый при загрузке страниц
class Spinner {

  final HtmlElement _element = querySelector('.spinner');

  void show() =>
    this._element.classes.add('spinner_show');

  void hide() =>
    this._element.classes.remove('spinner_show');

  /// Переместить спиннер в другой элемент
  void move(HtmlElement target) {
    target.append(this._element);
  }

}
