import 'package:flutter/material.dart';
import '../API/api_service.dart';
import '../API/session_manager.dart';
import '../models/curso.dart';
import '../models/utilizador.dart';
import '../models/formando.dart';
import '../widgets/app_scaffold.dart';
import '../widgets/curso_card.dart';
import 'dart:io';

class MeuPerfilPage extends StatefulWidget {
  @override
  State<MeuPerfilPage> createState() => _MeuPerfilPageState();
}

class _MeuPerfilPageState extends State<MeuPerfilPage> {
  Utilizadores? utilizador;
  Formando? formando;
  List<Curso> cursosInscritos = [];
  bool carregando = true;

  @override
  void initState() {
    super.initState();
    carregarDados();
  }

  Future<void> carregarDados({bool retry = false}) async {
    final idUtilizador = await SessionManager.getIdUtilizador() ?? 0;
    print('ID Utilizador: $idUtilizador');

    if (idUtilizador == 0) {
      setState(() => carregando = false);
      return;
    }

    try {
      // Dados do utilizador
      final userJson = await ApiService.getUtilizadorById(idUtilizador);
      final user = Utilizadores.fromJson(userJson);

      print('Dados do utilizador: $userJson'); 

      // Cursos inscritos
      final inscritos = userJson['inscritos'] as List<dynamic>? ?? [];
      final cursos = inscritos
          .map((c) => Curso.fromJson(c as Map<String, dynamic>))
          .toList();

      // Dados do formando
      Formando? f;
      try {
        print('Verificando se utilizador tem dados de formando...');

        
        if (userJson.containsKey('formando') && userJson['formando'] != null) {
          f = Formando.fromJson(userJson['formando']);
          print(
              'Formando encontrado no JSON do utilizador: ${userJson['formando']}');
        } else if (userJson.containsKey('id_formando') &&
            userJson['id_formando'] != null &&
            userJson['id_formando'] != 0) {
          final idFormando = userJson['id_formando'];
          print(
              'Tentando buscar formando com idUtilizador: $idUtilizador e idFormando: $idFormando');
          final formandoJson = await ApiService.getFormandoByIdUtilizador(
              idUtilizador, idFormando);
          f = Formando.fromJson(formandoJson);
          print('Formando encontrado pela API: $formandoJson');
        } else {
          print('Utilizador não tem id_formando ou dados de formando');
          print('Estrutura do userJson: ${userJson.keys.toList()}');

          print(
              'Tentando buscar formando usando idUtilizador como parâmetro...');
          try {
            final formandoJson = await ApiService.getFormandoByIdUtilizador(
                idUtilizador, idUtilizador);
            f = Formando.fromJson(formandoJson);
            print(
                'SUCESSO: Formando encontrado usando idUtilizador: $formandoJson');
          } catch (e) {
            print('FALHOU: Erro ao buscar com idUtilizador: $e');

            
            print('Tentando outras combinações...');
            for (int testId = 1; testId <= 5; testId++) {
              try {
                final formandoJson = await ApiService.getFormandoByIdUtilizador(
                    idUtilizador, testId);
                f = Formando.fromJson(formandoJson);
                print('SUCESSO com id $testId: $formandoJson');
                break;
              } catch (e) {
                print('Falhou com id $testId: $e');
              }
            }
          }
        }

        
        if (retry && f != null && (f.foto_perfil == null || f.foto_perfil!.isEmpty)) {
          print('foto_perfil vazio após atualização, tentando novamente...');
          final formandoJson = await ApiService.getFormandoCompleto(idUtilizador, f.id_formando);
          f = Formando.fromJson(formandoJson);
          print('Retry bem-sucedido: $formandoJson');
        }
      } catch (formandoError) {
        print('Erro ao encontrar formando: $formandoError');
      }

      if (!mounted) return;
      setState(() {
        utilizador = user;
        cursosInscritos = cursos;
        formando = f;
        carregando = false;
      });
    } catch (e) {
      print('Erro ao carregar utilizador: $e');
      if (!mounted) return;
      setState(() => carregando = false);
    }
  }

  ImageProvider<Object> _obterImagemPerfil() {
    if (formando?.foto_perfil == null || formando!.foto_perfil!.isEmpty) {
      print('Imagem de perfil: usando default (foto_perfil é nulo ou vazio)');
      return const AssetImage('assets/images/poo.png');
    } else if (formando!.foto_perfil!.startsWith('http')) {
      print('Imagem de perfil: usando NetworkImage (${formando!.foto_perfil})');
      return NetworkImage('${formando!.foto_perfil!}?_=${DateTime.now().millisecondsSinceEpoch}');
    } else {
      print('Imagem de perfil: tentando FileImage (${formando!.foto_perfil})');
      final file = File(formando!.foto_perfil!);
      if (file.existsSync()) {
        return FileImage(file);
      } else {
        print('Arquivo local não encontrado: ${formando!.foto_perfil}');
        return const AssetImage('assets/images/.png');
      }
    }
  }

  void terminarSessao() async {
    await SessionManager.logout();
    Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Meu Perfil',
      appBarColor: const Color(0xFF486CA4), 
      customLogo: 'assets/images/logosoftinsabranco.png', 
      customDrawer: Drawer(
        child: ListView(
          padding: const EdgeInsets.symmetric(vertical: 40),
          children: [
            const Divider(height: 1),
            ListTile(
              contentPadding:
                  const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
              leading: const Icon(Icons.home),
              title: const Text('Página Principal'),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/principal');
              },
            ),
            const Divider(height: 1),
            ListTile(
              contentPadding:
                  const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
              leading: const Icon(Icons.edit_outlined),
              title: const Text('Editar Perfil'),
              onTap: () async {
                if (utilizador != null && formando != null) {
                  final result = await Navigator.pushNamed(
                    context,
                    '/editar-perfil',
                    arguments: {
                      'idUtilizador': formando!.id_utilizador,
                      'idFormando': formando!.id_formando,
                    },
                  );
                  if (result != null) {
                    setState(() => carregando = true);
                    await carregarDados(retry: true);
                    print('Perfil atualizado, dados recarregados: foto_perfil=${formando?.foto_perfil}');
                  }
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Dados do perfil ainda não carregados.'),
                    ),
                  );
                }
              },
            ),
            const Divider(height: 1),
            ListTile(
              contentPadding:
                  const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
              leading: const Icon(Icons.logout),
              title: const Text('Terminar Sessão'),
              onTap: terminarSessao,
            ),
            const Divider(height: 1),
          ],
        ),
      ),
      body: carregando
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(0.0),
              child: Column(
                children: [
                  // Header do perfil
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Color(0xFF486CA4),
                          Color(0xFF486CA4),
                        ],
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Nome
                              Text(
                                utilizador?.nome ?? 'Sem nome',
                                style: const TextStyle(
                                  fontSize: 35,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 20),
                              // Email
                              Text(
                                utilizador?.email ?? 'Sem email',
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.8),
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 30),
                              // Cursos Acabados
                              Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Cursos Acabados',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 24,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 0),
                                    Text(
                                      '${formando?.n_cursosacabados ?? 0}',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 22,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 30),
                              // Cursos Inscritos
                              Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Cursos Inscritos',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 24,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 0),
                                    Text(
                                      '${formando?.n_cursosinscritos ?? 0}',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 22,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),
                        CircleAvatar(
                          radius: 50,
                          backgroundImage: _obterImagemPerfil(),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  Container(
                    alignment: Alignment.centerLeft,
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: const Text(
                      'Cursos Inscritos',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  cursosInscritos.isEmpty
                      ? const Text('Ainda não está inscrito em nenhum curso.')
                      : GridView.builder(
                          itemCount: cursosInscritos.length,
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
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
                                Navigator.pushNamed(
                                  context,
                                  '/curso-detalhes',
                                  arguments: curso,
                                );
                              },
                            );
                          },
                        ),
                ],
              ),
            ),
    );
  }
}