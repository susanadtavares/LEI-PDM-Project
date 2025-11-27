import 'package:flutter/material.dart';
import 'package:pint/API/api_service.dart';

class EmailInputPage extends StatefulWidget {
  @override
  State<EmailInputPage> createState() => _EmailInputPageState();
}

class _EmailInputPageState extends State<EmailInputPage> {
  final TextEditingController nomeController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController telemovelController = TextEditingController();
  DateTime? dataNascimento;
  String? genero;
  String tipo = 'formando';

  void selecionarDataNascimento() async {
    DateTime? data = await showDatePicker(
      context: context,
      initialDate: DateTime(2000),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (data != null) {
      setState(() {
        dataNascimento = data;
      });
    }
  }

  void enviarPedido() async {
    final nome = nomeController.text.trim();
    final email = emailController.text.trim().toLowerCase();
    final telemovel = telemovelController.text.trim();

    if (nome.isEmpty ||
        email.isEmpty ||
        telemovel.isEmpty ||
        dataNascimento == null ||
        genero == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Por favor, preencha todos os campos.')),
      );
      return;
    }

    //validação do email
    final regExpEmail = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,8}$');
    if (!regExpEmail.hasMatch(email)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Por favor, insira um email válido.')),
      );
      return;
    }

    //validação do telemovel
    final regExpTelefone = RegExp(r'^9\d{8}$'); 
    if (!regExpTelefone.hasMatch(telemovel)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content:
                Text('O número de telemóvel deve ter o formato [9XXXXXXXX].')),
      );
      return;
    }

    try {
      // Verifica se email já existe
      final existe = await ApiService.emailExiste(email);

      if (existe) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content:
                  Text('Este email já está registado ou o pedido já foi enviado.')),
        );
        return;
      }

      // Criar pedido de registo
      await ApiService.criarPedido({
        "nome": nome,
        "email": email,
        "telemovel": telemovel,
        "data_nascimento": dataNascimento!.toIso8601String(),
        "genero": genero,
        "tipo": tipo,
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Pedido enviado com sucesso! Aguarde aprovação.')),
      );

      Navigator.pushNamed(context, '/verifique-email');
    } catch (e) {
      print('Falha ao enviar pedido: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ocorreu um erro. Tente novamente.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              Image.asset('assets/images/logosoftinsa.png', height: 60),
              SizedBox(height: 24),
              Text(
                'Registar',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 24),
              TextField(
                controller: nomeController,
                decoration: InputDecoration(
                  labelText: 'Nome',
                  border: OutlineInputBorder(),
                ),
              ),
              SizedBox(height: 12),
              TextField(
                controller: emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(),
                ),
              ),
              SizedBox(height: 12),
              TextField(
                controller: telemovelController,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                  labelText: 'Telemóvel',
                  border: OutlineInputBorder(),
                ),
              ),
              SizedBox(height: 12),
              ListTile(
                title: Text(dataNascimento == null
                    ? 'Selecionar Data de Nascimento'
                    : 'Data: ${dataNascimento!.day}/${dataNascimento!.month}/${dataNascimento!.year}'),
                trailing: Icon(Icons.calendar_today),
                onTap: selecionarDataNascimento,
              ),
              SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: genero,
                items: ['Masculino', 'Feminino', 'Outro']
                    .map((g) => DropdownMenuItem(value: g, child: Text(g)))
                    .toList(),
                hint: Text('Selecione o género'),
                onChanged: (value) => setState(() => genero = value),
              ),
              SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: enviarPedido,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFFE8E2F8),
                    foregroundColor: Colors.black,
                    padding: EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                  ),
                  child: Text('Enviar Pedido'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
