import 'package:flutter/material.dart';

class EmailEnviadoPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Spacer(),
              Image.asset('assets/images/logosoftinsa.png', height: 60),
              SizedBox(height: 24),
              Text(
                'Verifique o seu email',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 12),
              Text(
                'Enviámos um email com a sua palavra-passe temporária',
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pushNamed(context, '/login');
                  },
                  child: Text('Iniciar Sessão'),
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
