import 'package:flutter/material.dart';
import '../API/api_service.dart';
import '../API/session_manager.dart';
import '../models/notificacao.dart';
import '../widgets/app_scaffold.dart';

class NotificacoesPage extends StatefulWidget {
  const NotificacoesPage({Key? key}) : super(key: key);

  @override
  _NotificacoesPageState createState() => _NotificacoesPageState();
}

class _NotificacoesPageState extends State<NotificacoesPage> {
  late Future<List<NotificacaoModel>> futureNotificacoes;

  @override
  void initState() {
    super.initState();
    _loadNotificacoes();
  }

  void _loadNotificacoes() async {
    final idUtilizador = await SessionManager.getIdUtilizador();
    if (idUtilizador != null) {
      setState(() {
        futureNotificacoes = ApiService().getNotificacoes(idUtilizador);
      });
    } else {
      setState(() {
        futureNotificacoes = Future.error("Usuário não autenticado");
      });
    }
  }

  Future<void> _marcarComoLida(NotificacaoModel notif) async {
    final idUtilizador = await SessionManager.getIdUtilizador();
    if (idUtilizador == null) return;

    try {
      await ApiService().marcarNotificacaoComoLida(idUtilizador, notif.idNotificacao);

      setState(() {
        notif.estado = 'lida';
        notif.notificacaoAtiva = false;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Erro ao marcar como lida: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Notificações',
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: FutureBuilder<List<NotificacaoModel>>(
          future: futureNotificacoes,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            } else if (snapshot.hasError) {
              return Center(child: Text("Erro: ${snapshot.error}"));
            } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return const Center(child: Text("Sem notificações"));
            }

            final notificacoes = snapshot.data!;

            return ListView.separated(
              itemCount: notificacoes.length,
              separatorBuilder: (_, __) => const Divider(),
              itemBuilder: (context, index) {
                final notif = notificacoes[index];

                return ListTile(
                  leading: Icon(
                    notif.notificacaoAtiva
                        ? Icons.notifications_active
                        : Icons.notifications_none,
                    color: notif.notificacaoAtiva ? Colors.blue : Colors.grey,
                  ),
                  title: Text(notif.titulo),
                  subtitle: notif.cursoTitulo != null
                      ? Text("Curso: ${notif.cursoTitulo}")
                      : null,
                  trailing: Text(
                    "${notif.data.day}/${notif.data.month}/${notif.data.year}",
                  ),
                  onTap: () => _marcarComoLida(notif),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
