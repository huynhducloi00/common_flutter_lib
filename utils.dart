import 'dart:html' as html;
final appContainer =
html.window.document.getElementById('app-container');
setCursor(bool isHovering){
  appContainer.style.cursor = isHovering ? 'pointer':'default';
}