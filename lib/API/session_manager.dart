import 'package:shared_preferences/shared_preferences.dart';

class SessionManager {
  static Future<void> saveLogin(String token, int idUtilizador) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('jwtToken', token);
    await prefs.setInt('idUtilizador', idUtilizador);
  }

  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('jwtToken');
  }

  static Future<int?> getIdUtilizador() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt('idUtilizador');
  }

  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('jwtToken');
    await prefs.remove('idUtilizador');
  }
}
