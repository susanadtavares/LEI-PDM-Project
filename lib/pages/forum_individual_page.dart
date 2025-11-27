import 'package:flutter/material.dart';
import 'package:pint/API/api_service.dart';

class ForumCategoriaPage extends StatefulWidget {
  final String categoria;
  const ForumCategoriaPage({super.key, required this.categoria});

  @override
  State<ForumCategoriaPage> createState() => _ForumCategoriaPageState();
}

class _ForumCategoriaPageState extends State<ForumCategoriaPage> {
  bool isLoading = true;
  String? error;

  List<String> areas = [];
  final Map<String, List<String>> topicosPorArea = {};

  @override
  void initState() {
    super.initState();
    _carregarTudo();
  }

  Future<void> _carregarTudo() async {
    setState(() {
      isLoading = true;
      error = null;
    });

    try {
      final areasLista = await ApiService.getAreasByCategoriaNome(widget.categoria);
      final mapa = <String, List<String>>{};
      for (final area in areasLista) {
        final t = await ApiService.getTopicosByAreaNome(area);
        mapa[area] = t;
      }
      setState(() {
        areas = areasLista;
        topicosPorArea
          ..clear()
          ..addAll(mapa);
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        error = 'Erro a carregar áreas/tópicos: $e';
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        color: const Color(0xFFF8F5FB),
        child: RefreshIndicator(
          onRefresh: _carregarTudo,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            children: [
              // Título por baixo da AppBar da app
              Text(
                widget.categoria,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black),
              ),
              const SizedBox(height: 12),

              // Cabeçalho "Tópicos | Posts" (texto normal, preto)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: kElevationToShadow[1],
                ),
                child: Row(
                  children: const [
                    Expanded(
                      child: Text(
                        'Tópicos',
                        softWrap: false,
                        overflow: TextOverflow.fade,
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.black),
                      ),
                    ),
                    SizedBox(width: 12),
                    Text(
                      'Posts',
                      softWrap: false,
                      overflow: TextOverflow.fade,
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.black),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),

              if (isLoading)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 32),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (error != null)
                _errorBox(error!, onRetry: _carregarTudo)
              else if (areas.isEmpty)
                _emptyBox('Sem áreas nesta categoria.')
              else
                ...areas.map((area) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _AreaTopicsCard(
                        area: area,
                        topicos: topicosPorArea[area] ?? const [],
                      ),
                    )),
            ],
          ),
        ),
      ),
    );
  }

  Widget _errorBox(String msg, {VoidCallback? onRetry}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline),
          const SizedBox(width: 8),
          Expanded(child: Text(msg)),
          if (onRetry != null)
            TextButton(onPressed: onRetry, child: const Text('Tentar novamente')),
        ],
      ),
    );
  }

  Widget _emptyBox(String msg) {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: kElevationToShadow[1],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          Icon(Icons.forum_outlined),
          SizedBox(width: 12),
          Expanded(child: Text('Sem posts para mostrar')),
        ],
      ),
    );
  }
}

class _AreaTopicsCard extends StatelessWidget {
  final String area;
  final List<String> topicos;

  const _AreaTopicsCard({
    required this.area,
    required this.topicos,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      elevation: 1,
      borderRadius: BorderRadius.circular(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Cabeçalho da área
          Container(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.5),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
            ),
            child: Row(
              children: [
                const CircleAvatar(radius: 16, child: Icon(Icons.chat_bubble_outline, size: 16)),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(area,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.w700, color: Colors.black)),
                      Text(
                        'Fórum geral da área',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Theme.of(context).textTheme.bodySmall?.color,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Tópicos (posts=0 por agora)
          if (topicos.isEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 16),
              child: Text(
                'Sem tópicos',
                style: TextStyle(color: Theme.of(context).textTheme.bodySmall?.color),
              ),
            )
          else
            ...List.generate(topicos.length, (i) {
              final t = topicos[i];
              return Column(
                children: [
                  if (i == 0) const Divider(height: 1),
                  _TopicRow(
                    icon: Icons.chat_bubble_outline,
                    titulo: t,
                    subtitulo: 'Tópico da área $area',
                    posts: 0,
                  ),
                  const Divider(height: 1),
                ],
              );
            }),
        ],
      ),
    );
  }
}

class _TopicRow extends StatelessWidget {
  final IconData icon;
  final String titulo;
  final String subtitulo;
  final int posts;

  const _TopicRow({
    required this.icon,
    required this.titulo,
    required this.subtitulo,
    required this.posts,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        children: [
          const CircleAvatar(radius: 18, child: Icon(Icons.forum_outlined, size: 18)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(titulo,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w700, color: Colors.black)),
                Text(
                  subtitulo,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Theme.of(context).textTheme.bodySmall?.color,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Text(posts.toString(), style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.black)),
        ],
      ),
    );
  }
}
