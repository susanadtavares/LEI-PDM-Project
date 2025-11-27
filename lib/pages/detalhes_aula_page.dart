import 'package:flutter/material.dart';
import '../models/aula.dart';
class DetalhesAulaPage extends StatelessWidget {
  final Aula aula;

  const DetalhesAulaPage({Key? key, required this.aula}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(aula.titulo_aula),
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text(aula.titulo_aula, style: TextStyle(fontSize: 24)),
            SizedBox(height: 8),
            Text(aula.descricao_aula),
            // Aqui você pode adicionar mais detalhes conforme necessário
          ],
        ),
      ),
    );
  }
}
