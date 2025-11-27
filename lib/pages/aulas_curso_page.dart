import 'package:flutter/material.dart';
import '../API/api_service.dart';
import '../models/aula.dart';
import '../widgets/app_scaffold.dart';
import 'detalhes_aula_page.dart';

class AulasCursoPage extends StatefulWidget {
  final int id_curso;
  final String curso_titulo;

  const AulasCursoPage({
    Key? key,
    required this.id_curso,
    required this.curso_titulo,
  }) : super(key: key);

  @override
  State<AulasCursoPage> createState() => _AulasCursoPageState();
}

class _AulasCursoPageState extends State<AulasCursoPage> {
  List<Aula> aulas = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    carregarAulas();
  }

  Future<void> carregarAulas() async {
    try {
      final aulasCarregadas = await ApiService.getAula(widget.id_curso);
      setState(() {
        aulas = aulasCarregadas;
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao carregar aulas: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Aulas - ${widget.curso_titulo}',
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : aulas.isEmpty
              ? Center(child: Text('Nenhuma aula disponível'))
              : ListView.builder(
                  itemCount: aulas.length,
                  itemBuilder: (context, index) {
                    final aula = aulas[index];
                    return Card(
                      margin: EdgeInsets.all(8),
                      child: ListTile(
                        leading: Icon(Icons.play_circle, color: Colors.blue),
                        title: Text(aula.titulo_aula),
                        subtitle: Text(aula.descricao_aula),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  DetalhesAulaPage(aula: aula),
                            ),
                          );
                        },
                      ),
                    );
                  },
                ),
    );
  }
}
