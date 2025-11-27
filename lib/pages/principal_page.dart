import 'package:flutter/material.dart';
import 'package:pint/API/api_service.dart';
import 'package:pint/API/session_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/curso.dart';
import '../widgets/app_scaffold.dart';
import '../widgets/curso_card.dart';
import 'detalhes_curso_page.dart';

class PaginaPrincipal extends StatefulWidget {
  @override
  State<PaginaPrincipal> createState() => _PaginaPrincipalState();
}

class _PaginaPrincipalState extends State<PaginaPrincipal> {
  List<Curso> cursosInscritos = [];
  String? emailLogado;
  String nome = '';
  String apelido = '';
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    carregarDados();
  }

  Future<void> carregarDados() async {
    setState(() => isLoading = true);
    try {
      // email (para cursos – endpoint legacy)
      final prefs = await SharedPreferences.getInstance();
      emailLogado = prefs.getString('email_logado');

      // nome/apelido (igual ao Perfil – via idUtilizador)
      final idUtilizador = await SessionManager.getIdUtilizador();
      if (idUtilizador != null && idUtilizador != 0) {
        final userJson = await ApiService.getUtilizadorById(idUtilizador);
        nome = (userJson['nome'] ?? '').toString();
        apelido = (userJson['apelido'] ?? '').toString();
      }

      // cursos inscritos (legacy por email)
      if (emailLogado != null) {
        cursosInscritos = await ApiService.obterCursosInscritos(emailLogado!);
      }

      setState(() => isLoading = false);
    } catch (e) {
      setState(() => isLoading = false);
    }
  }

  // Title Case simples
  String _titleCase(String s) {
    if (s.trim().isEmpty) return '';
    final lower = s.toLowerCase().trim();
    return lower[0].toUpperCase() + lower.substring(1);
  }

  // Nome para mostrar: nome+apelido; se faltar, gera a partir do email
  String get _displayName {
    final full = ('$nome $apelido').trim();
    if (full.isNotEmpty) {
      return full
          .split(RegExp(r'\s+'))
          .map(_titleCase)
          .join(' ')
          .trim();
    }
    final e = emailLogado ?? '';
    if (e.contains('@')) {
      final local = e.split('@').first;
      final parts = local.split(RegExp(r'[._\-]+')).where((p) => p.isNotEmpty);
      final pretty = parts.map(_titleCase).join(' ');
      if (pretty.isNotEmpty) return pretty;
    }
    return e;
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Página Inicial',
      body: RefreshIndicator(
        onRefresh: carregarDados,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16.0),
          children: [
            // Saudação
            if (isLoading)
              Row(
                children: const [
                  Text(
                    'Bem-vindo/a, ',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(width: 4),
                  SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ],
              )
            else
              Text(
                'Bem-vindo/a, $_displayName!',
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: Colors.black, // agora a preto
                ),
              ),

            const SizedBox(height: 20),

            if (isLoading) ...[
              const Center(child: CircularProgressIndicator()),
            ] else if (cursosInscritos.isEmpty) ...[
              const Text('Ainda não está inscrito em cursos.'),
            ] else ...[
              const Text(
                'Os meus cursos:',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              GridView.builder(
                itemCount: cursosInscritos.length,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 3 / 4,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                ),
                itemBuilder: (context, index) {
                  final curso = cursosInscritos[index];
                  return CursoCard(
                    curso: curso,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => DetalhesCursoPage(curso: curso),
                        ),
                      );
                    },
                  );
                },
              ),
            ],
          ],
        ),
      ),
    );
  }
}
