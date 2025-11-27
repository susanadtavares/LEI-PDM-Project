import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../models/curso.dart';
import '../widgets/curso_card.dart';
import '../widgets/app_scaffold.dart';
import '../widgets/curso_filtro.dart';
import 'detalhes_curso_page.dart';
import 'package:pint/API/api_service.dart';
import 'package:pint/API/session_manager.dart';

class TodosCursosPage extends StatefulWidget {
  const TodosCursosPage({super.key});

  @override
  _TodosCursosPageState createState() => _TodosCursosPageState();
}

class _TodosCursosPageState extends State<TodosCursosPage> {
  // --- dados ---
  List<Curso> todosOsCursos = [];
  List<Curso> cursosFiltrados = [];
  bool isLoading = true;

  // --- pesquisa + filtro por tipo ---
  final TextEditingController pesquisaController = TextEditingController();
  String tipoSelecionado = 'Todos';
  String categoriaSelecionada = 'Todas';
  String areaSelecionada = 'Todas';
  String topicoSelecionado = 'Todos';

  final List<String> tipos = ['Todos', 'Síncrono', 'Assíncrono'];
  List<String> categorias = ['Todas'];
  List<String> areas = ['Todas']; // dependem da categoria
  List<String> topicos = ['Todos']; // dependem da área

  bool _debugListMode = false;

  @override
  void initState() {
    super.initState();
    carregarCursos();
    carregarCategorias();
    // Áreas e tópicos começam vazios (dependentes)
    carregarAreas();   // com categoria 'Todas' -> mantém ['Todas']
    carregarTopicos(); // com área 'Todas' -> mantém ['Todos']
  }

  @override
  void dispose() {
    pesquisaController.dispose();
    super.dispose();
  }

  Future<void> carregarCursos() async {
    final token = await SessionManager.getToken();
    debugPrint('[DEBUG] Token JWT atual: $token');

    try {
      final List<Curso> data = await ApiService.apiGetCursos(backoffice: true);

      if (kDebugMode) {
        debugPrint('[Cursos] recebidos: ${data.length}');
        if (data.isNotEmpty) {
          final c = data.first;
          debugPrint('[Cursos] exemplo: ${c.titulo} | visível=${c.curso_visivel} | tipo=${c.tipo} | cat=${c.categoria} | area=${c.area} | top=${c.topico}');
        }
      }

      setState(() {
        todosOsCursos = data;
        aplicarFiltros();
        isLoading = false;
      });
    } catch (e) {
      debugPrint('[DEBUG] Erro ao carregar cursos: $e');
      if (mounted) {
        setState(() => isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao carregar cursos: $e')),
        );
      }
    }
  }

  Future<void> carregarCategorias() async {
    try {
      final lista = await ApiService.getCategorias();
      setState(() => categorias = ['Todas', ...lista]);
    } catch (e) {
      setState(() => categorias = ['Todas']);
      debugPrint('Erro ao carregar categorias: $e');
    }
  }

  Future<void> carregarAreas() async {
    try {
      // Hierárquico: depende da categoriaSelecionada
      if (categoriaSelecionada == 'Todas') {
        setState(() => areas = ['Todas']);
        return;
      }
      final lista = await ApiService.getAreasByCategoriaNome(categoriaSelecionada);
      setState(() => areas = ['Todas', ...lista]);
    } catch (e) {
      setState(() => areas = ['Todas']);
      debugPrint('Erro ao carregar áreas: $e');
    }
  }

  Future<void> carregarTopicos() async {
    try {
      // Hierárquico: depende da areaSelecionada
      if (areaSelecionada == 'Todas') {
        setState(() => topicos = ['Todos']);
        return;
      }
      final lista = await ApiService.getTopicosByAreaNome(areaSelecionada);
      setState(() => topicos = ['Todos', ...lista]);
    } catch (e) {
      setState(() => topicos = ['Todos']);
      debugPrint('Erro ao carregar tópicos: $e');
    }
  }

  // traduz o enum para texto
  String _tipoLabel(TipoCurso t) =>
      t == TipoCurso.Sincrono ? 'Síncrono' : 'Assíncrono';

  bool _correspondeTipo(Curso curso) {
    switch (tipoSelecionado) {
      case 'Síncrono':
        return curso.tipo == TipoCurso.Sincrono;
      case 'Assíncrono':
        return curso.tipo == TipoCurso.Assincrono;
      case 'Todos':
      default:
        return true;
    }
  }

  void aplicarFiltros() {
    final q = pesquisaController.text.toLowerCase().trim();
    setState(() {
      cursosFiltrados = todosOsCursos.where((c) {
        final matchTexto =
            (c.titulo.toLowerCase() ?? '').contains(q) ||
            (c.descricao.toLowerCase() ?? '').contains(q);
        final matchTipo = _correspondeTipo(c);

        final matchCategoria = categoriaSelecionada == 'Todas'
            || (c.categoria ?? 'Todas') == categoriaSelecionada;

        final matchArea = areaSelecionada == 'Todas'
            || (c.area ?? 'Todas') == areaSelecionada;

        final matchTopico = topicoSelecionado == 'Todos'
            || (c.topico ?? 'Todos') == topicoSelecionado;

        return matchTexto && matchTipo && matchCategoria && matchArea && matchTopico;
      }).toList();
    });
  }

  Future<void> abrirFiltroTipo() async {
    final resultado = await showModalBottomSheet<String>(
      context: context,
      builder: (context) {
        return SizedBox(
          height: 250,
          child: ListView(
            shrinkWrap: true,
            children: tipos
                .map((tipo) => ListTile(
                      title: Text(tipo),
                      onTap: () => Navigator.pop(context, tipo),
                    ))
                .toList(),
          ),
        );
      },
    );

    if (resultado != null) {
      setState(() => tipoSelecionado = resultado);
      aplicarFiltros();
    }
  }

  Future<void> abrirFiltroCategoria() async {
    final resultado = await showModalBottomSheet<String>(
      context: context,
      builder: (context) => ListView(
        children: categorias.map((cat) {
          return ListTile(
            title: Text(cat),
            onTap: () => Navigator.pop(context, cat),
          );
        }).toList(),
      ),
    );

    if (resultado != null) {
      setState(() {
        categoriaSelecionada = resultado;
        // reset dependentes
        areaSelecionada = 'Todas';
        topicoSelecionado = 'Todos';
      });
      await carregarAreas();   // carrega áreas da categoria (ou limpa)
      await carregarTopicos(); // limpa tópicos (área ainda 'Todas')
      aplicarFiltros();
    }
  }

  Future<void> abrirFiltroArea() async {
    final resultado = await showModalBottomSheet<String>(
      context: context,
      builder: (context) => ListView(
        children: areas.map((area) {
          return ListTile(
            title: Text(area),
            onTap: () => Navigator.pop(context, area),
          );
        }).toList(),
      ),
    );

    if (resultado != null) {
      setState(() {
        areaSelecionada = resultado;
        // reset dependente
        topicoSelecionado = 'Todos';
      });
      await carregarTopicos(); // carrega tópicos da área (ou limpa)
      aplicarFiltros();
    }
  }

  Future<void> abrirFiltroTopico() async {
    final resultado = await showModalBottomSheet<String>(
      context: context,
      builder: (context) => ListView(
        children: topicos.map((topico) {
          return ListTile(
            title: Text(topico),
            onTap: () => Navigator.pop(context, topico),
          );
        }).toList(),
      ),
    );
    if (resultado != null) {
      setState(() => topicoSelecionado = resultado);
      aplicarFiltros();
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Todos os Cursos',
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Todos os Cursos',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            CursoFiltroWidget(
              controller: pesquisaController,
              onPesquisaChanged: (_) => aplicarFiltros(),
              onFiltroTipo: abrirFiltroTipo,
              tipo: tipoSelecionado,
              onFiltroCategoria: abrirFiltroCategoria,
              onFiltroArea: abrirFiltroArea,
              onFiltroTopico: abrirFiltroTopico,
              categoria: categoriaSelecionada,
              area: areaSelecionada,
              topico: topicoSelecionado,
            ),
            const SizedBox(height: 10),
            Expanded(
              child: isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : RefreshIndicator(
                      onRefresh: carregarCursos,
                      child: cursosFiltrados.isEmpty
                          ? ListView(
                              physics: const AlwaysScrollableScrollPhysics(),
                              children: const [
                                SizedBox(height: 120),
                                Center(
                                  child: Text(
                                    'Nenhum curso encontrado',
                                    style: TextStyle(fontSize: 16, color: Colors.grey),
                                  ),
                                ),
                              ],
                            )
                          : (_debugListMode
                              ? ListView.builder(
                                  physics: const AlwaysScrollableScrollPhysics(),
                                  itemCount: cursosFiltrados.length,
                                  itemBuilder: (context, index) {
                                    final curso = cursosFiltrados[index];
                                    return ListTile(
                                      title: Text(curso.titulo ?? '—'),
                                      subtitle: Text(
                                        '${curso.categoria ?? '-'} · ${curso.area ?? '-'} · ${curso.topico ?? '-'} · ${_tipoLabel(curso.tipo)}',
                                      ),
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
                                )
                              : GridView.builder(
                                  physics: const AlwaysScrollableScrollPhysics(),
                                  itemCount: cursosFiltrados.length,
                                  gridDelegate:
                                      const SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: 2,
                                    crossAxisSpacing: 12,
                                    mainAxisSpacing: 12,
                                    childAspectRatio: 0.75,
                                  ),
                                  itemBuilder: (context, index) {
                                    final curso = cursosFiltrados[index];
                                    return CursoCard(
                                      curso: curso,
                                      onTap: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) =>
                                                DetalhesCursoPage(curso: curso),
                                          ),
                                        );
                                      },
                                    );
                                  },
                                )),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
