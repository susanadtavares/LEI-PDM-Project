import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:pint/API/session_manager.dart';
import 'dart:convert';

class MudarPasswordPage extends StatefulWidget {
  const MudarPasswordPage({Key? key}) : super(key: key);

  @override
  State<MudarPasswordPage> createState() => _MudarPasswordPageState();
}

class _MudarPasswordPageState extends State<MudarPasswordPage> {
  final TextEditingController novaPassController = TextEditingController();
  final TextEditingController confirmarPassController = TextEditingController();

  void confirmarMudanca() async {
    final novaPassword = novaPassController.text.trim();
    final confirmarPassword = confirmarPassController.text.trim();

    // Campos preencidos
    if (novaPassword.isEmpty || confirmarPassword.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Preencha todos os campos!')),
      );
      return;
    }
    //Senhas iguais
    if (novaPassword != confirmarPassword) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('As passwords não coincidem.')),
      );
      return;
    }

    // Senha forte
    final passwordRegex = RegExp(
        r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[@$!%*?&])[A-Za-z\d@$!%*?&]{8,}$');
    if (!passwordRegex.hasMatch(novaPassword)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'A password deve ter pelo menos 8 caracteres, incluindo maiúscula, minúscula, número e caracter especial.'
          ),
        ),
      );
      return;
    }

    try {
      //token e id utilizador
      final token = await SessionManager.getToken();
      final idUtilizador = await SessionManager.getIdUtilizador();

      if (token == null || idUtilizador == null) {
        throw Exception('Sessão expirada. Faça login novamente.');
      }

      
      final url = Uri.parse(
        'https://pint-backend-t819.onrender.com/api/auth/$idUtilizador/alterar-password-primeiro-login'
      );

      
      final response = await http.put(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'novaPassword': novaPassword}),
      );

      print('Status Code: ${response.statusCode}');
      print('Response Body: ${response.body}');

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Password atualizada com sucesso!')),
        );
        Navigator.pushReplacementNamed(context, '/login');
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao alterar password: ${response.body}')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(leading: BackButton()),
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(height: 120),
              Image.asset('assets/images/logosoftinsa.png', height: 60),
              const SizedBox(height: 24),
              const Text(
                'Alterar Palavra-passe',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              const Text(
                'Altere a sua palavra-passe antes de continuar',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              TextField(
                controller: novaPassController,
                obscureText: true,
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.lock_outline),
                  labelText: 'Nova Palavra-passe',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: confirmarPassController,
                obscureText: true,
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.lock_outline),
                  labelText: 'Confirmar Palavra-passe',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: confirmarMudanca,
                  child: const Text('Confirmar'),
                ),
              ),
              Spacer(),
            ],
          ),
        ),
      ),
    );
  }
}
