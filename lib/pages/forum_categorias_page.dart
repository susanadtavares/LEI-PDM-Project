import 'package:flutter/material.dart';
import 'package:pint/API/api_service.dart';

class ForumCategoriasPage extends StatefulWidget {
  const ForumCategoriasPage({super.key});

  @override
  State<ForumCategoriasPage> createState() => _ForumCategoriasPageState();
}

class _ForumCategoriasPageState extends State<ForumCategoriasPage> {
  List<String> categorias = [];
  bool isLoading = true;
  String? error;
  int? selectedIndex;

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  Future<void> _carregar() async {
    setState(() {
      isLoading = true;
      error = null;
    });
    try {
      final lista = await ApiService.getCategorias();
      setState(() {
        categorias = lista;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        error = 'Erro a carregar categorias: $e';
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const SafeArea(child: Center(child: CircularProgressIndicator()));
    }

    if (error != null) {
      return SafeArea(
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, color: Colors.red),
              const SizedBox(height: 8),
              Text(error!, textAlign: TextAlign.center),
              const SizedBox(height: 12),
              FilledButton(onPressed: _carregar, child: const Text('Tentar novamente')),
            ],
          ),
        ),
      );
    }

    if (categorias.isEmpty) {
      return const SafeArea(
        child: Center(child: Text('Sem categorias disponíveis')),
      );
    }

    return SafeArea(
      child: RefreshIndicator(
        onRefresh: _carregar,
        child: ListView.separated(
          padding: const EdgeInsets.symmetric(vertical: 8),
          itemCount: categorias.length,
          separatorBuilder: (_, __) => const Divider(height: 1),
          physics: const AlwaysScrollableScrollPhysics(),
          itemBuilder: (context, i) {
            final selecionada = selectedIndex == i;
            final item = categorias[i];

            final content = ListTile(
              title: Text(
                item,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: selecionada ? Colors.white : null,
                ),
              ),
              trailing: Icon(
                Icons.chevron_right,
                color: selecionada ? Colors.white : Theme.of(context).iconTheme.color,
              ),
              onTap: () {
                setState(() => selectedIndex = i);
                // ABRIR VIA ROTA NOMEADA para usar AppScaffold (AppBar da app)
                Navigator.pushNamed(
                  context,
                  '/forum/categoria',
                  arguments: item,
                );
              },
            );

            if (!selecionada) return content;

            return Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.blue, Colors.lightBlueAccent],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
              ),
              child: content,
            );
          },
        ),
      ),
    );
  }
}
