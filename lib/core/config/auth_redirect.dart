/// Must match Android intent-filter and iOS CFBundleURLSchemes, and Supabase
/// Auth → URL Configuration redirect URLs.
class AuthRedirect {
  AuthRedirect._();

  static const String callback = 'com.smartautocar.smart_auto_car://login-callback';
}
