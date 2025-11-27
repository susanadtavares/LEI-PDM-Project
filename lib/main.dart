import 'package:flutter/material.dart';
import 'models/curso.dart';
import 'pages/loading_page.dart';
import 'pages/todos_cursos_page.dart';
import 'pages/detalhes_curso_page.dart';
import 'pages/email_input_page.dart';
import 'pages/email_enviado_page.dart';
import 'pages/login_page.dart';
import 'pages/mudar_password_page.dart';
import 'pages/principal_page.dart';
import 'pages/meu_perfil_page.dart';
import 'pages/notificacoes_page.dart';
import 'pages/editar_perfil_page.dart';
import 'pages/os_meus_cursos_page.dart';
import 'widgets/app_scaffold.dart';
import 'pages/forum_categorias_page.dart';
import 'pages/forum_individual_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'SoftSkills',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        fontFamily: 'Arial',
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => LoadingPage(),
        '/login': (context) => LoginPage(),
        '/registar': (context) => EmailInputPage(),
        '/verifique-email': (context) => EmailEnviadoPage(),
        '/mudar-password': (context) => MudarPasswordPage(),

        '/principal': (context) => PaginaPrincipal(),
        '/todosCursos': (context) => TodosCursosPage(),
        '/perfil': (context) => MeuPerfilPage(),
        '/notificacoes': (context) => NotificacoesPage(),

        '/editar-perfil': (context) {
  final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
  return EditarPerfilPage(
    idUtilizador: args['idUtilizador'],
    idFormando: args['idFormando'],
  );
},


        '/os-meus-cursos': (context) => OsMeusCursosPage(),
        '/detalhesCurso': (context) {
          final curso = ModalRoute.of(context)!.settings.arguments as Curso;
          return DetalhesCursoPage(curso: curso);
        },

        // ====== ROTAS DO FÓRUM ======
        '/forum': (context) => const AppScaffold(
              title: 'Fórum',
              body: ForumCategoriasPage(),
            ),
        '/forum/categoria': (context) {
          final categoria = ModalRoute.of(context)!.settings.arguments as String;
          return AppScaffold(
            title: 'Fórum',
            body: ForumCategoriaPage(categoria: categoria),
          );
        },
      },
    );
  }
}
