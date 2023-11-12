abstract class IGUIAdapter {
  void onReceive(var message);
  void onLogin();
  void onLogged();
  void onStop();
  void onError(var message);
}