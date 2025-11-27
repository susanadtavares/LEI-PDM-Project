import 'package:flutter/material.dart';
import 'package:pint/API/api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pint/API/session_manager.dart';

class LoginPage extends StatefulWidget {
  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  void login() async {
    final email = emailController.text.trim();
    final password = passwordController.text;

    if (email.isEmpty || password.isEmpty) return;

    try {
      final userData = await ApiService.login(email, password);

      // Guarda o email autenticado localmente

      await SessionManager.saveLogin(
          userData['jwt_token'], userData['id_utilizador']);

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('email_logado', email);

      if (userData['primeiro_login'] == true) {
        print('[DEBUG] Primeiro login detectado para $email');
        Navigator.pushReplacementNamed(
          context,
          '/mudar-password',
          arguments: userData['id_utilizador'],
        );
      } else {
        print('[DEBUG] Login normal para $email');
        Navigator.pushReplacementNamed(context, '/principal');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Credenciais inválidas ou erro no login')),
      );
    }
  }

  void registar() {
    Navigator.pushNamed(context, '/registar');
  }

  void recuperarPassword() {
    Navigator.pushNamed(context, '/registar');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.only(
            left: 24.0,
            right: 24.0,
            top: 24.0,
            bottom: MediaQuery.of(context).viewInsets.bottom + 24.0,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(height: 40),
              Image.asset('assets/images/logosoftinsa.png', height: 60),
              SizedBox(height: 24),
              Text(
                'Iniciar Sessão',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 24),
              TextField(
                controller: emailController,
                decoration: InputDecoration(
                  prefixIcon: Icon(Icons.person_outline),
                  labelText: 'Email',
                  border: OutlineInputBorder(),
                ),
              ),
              SizedBox(height: 16),
              TextField(
                controller: passwordController,
                obscureText: true,
                decoration: InputDecoration(
                  prefixIcon: Icon(Icons.lock_outline),
                  labelText: 'Palavra-passe',
                  border: OutlineInputBorder(),
                ),
              ),
              SizedBox(height: 12),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: recuperarPassword,
                  child: Text('Esqueceu-se da Palavra-passe?'),
                ),
              ),
              SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: login,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF295C99),
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: Text('Entrar'),
                ),
              ),
              SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: registar,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey.shade400,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: Text('Registar'),
                ),
              ),
              SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
