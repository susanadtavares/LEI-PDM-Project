import 'package:flutter/material.dart';
import 'package:pint/API/api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/curso.dart';
import '../widgets/app_scaffold.dart';
import '../widgets/curso_card.dart';
import '../widgets/curso_filtro.dart';
import 'detalhes_curso_page.dart';

class OsMeusCursosPage extends StatefulWidget {
  @override
  State<OsMeusCursosPage> createState() => _OsMeusCursosPageState();
}

class _OsMeusCursosPageState extends State<OsMeusCursosPage> {
  List<Curso> cursosInscritos = [];
  List<Curso> cursosFiltrados = [];
  bool isLoading = true;

  final TextEditingController pesquisaController = TextEditingController();

  // filtros (ui)
  String tipoSelecionado = 'Todos';
  String categoriaSelecionada = 'Todas';
  String areaSelecionada = 'Todas';
  String topicoSelecionado = 'Todos';

  // opções
  final List<String> _tipos = ['Todos', 'Síncrono', 'Assíncrono'];
  List<String> categorias = ['Todas'];
  List<String> areas = ['Todas'];   // dependem da categoria
  List<String> topicos = ['Todos']; // dependem da área

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      carregarCategorias(); // meta da API
      carregarCursos();     // cursos do utilizador (enriquecidos)
    });
  }

  @override
  void dispose() {
    pesquisaController.dispose();
    super.dispose();
  }

  // ---------------------------
  // Carregamento de meta (API)
  // ---------------------------

  Future<void> carregarCategorias() async {
    try {
      final lista = await ApiService.getCategorias();
      setState(() => categorias = ['Todas', ...lista]);
    } catch (e) {
      debugPrint('Erro ao carregar categorias (meta): $e');
      setState(() => categorias = ['Todas']);
    }
  }

  Future<void> carregarAreas() async {
    try {
      if (categoriaSelecionada == 'Todas') {
        setState(() => areas = ['Todas']);
        return;
      }
      final lista = await ApiService.getAreasByCategoriaNome(categoriaSelecionada);
      setState(() => areas = ['Todas', ...lista]);
    } catch (e) {
      debugPrint('Erro ao carregar áreas (meta): $e');
      setState(() => areas = ['Todas']);
    }
  }

  Future<void> carregarTopicos() async {
    try {
      if (areaSelecionada == 'Todas') {
        setState(() => topicos = ['Todos']);
        return;
      }
      final lista = await ApiService.getTopicosByAreaNome(areaSelecionada);
      setState(() => topicos = ['Todos', ...lista]);
    } catch (e) {
      debugPrint('Erro ao carregar tópicos (meta): $e');
      setState(() => topicos = ['Todos']);
    }
  }

  // ---------------------------
  // Cursos do utilizador
  // ---------------------------

  Future<void> carregarCursos() async {
    setState(() => isLoading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final email = prefs.getString('email_logado');

      if (email == null) {
        setState(() => isLoading = false);
        return;
      }

      // 1) busca “bruta” (endpoint antigo)
      final lista = await ApiService.obterCursosInscritos(email);

      // 2) enriquecer cada curso com dados completos do /api/cursos/:id
      //    para garantir categoria/área/tópico (e nomes legíveis)
      final enriquecidos = <Curso>[];
      for (final c in lista) {
        try {
          // backoffice=true para não falhar caso algum curso esteja oculto
          final cheio = await ApiService.apiGetCursoById(c.id_curso!, backoffice: true);
          enriquecidos.add(cheio);
        } catch (e) {
          // fallback: se falhar, mantém o curso original
          debugPrint('[OsMeusCursos] falha a enriquecer ${c.id_curso}: $e');
          enriquecidos.add(c);
        }
      }

      setState(() {
        cursosInscritos = enriquecidos;
        cursosFiltrados = enriquecidos;
        isLoading = false;

        // reset de seleções dependentes
        categoriaSelecionada = 'Todas';
        areaSelecionada = 'Todas';
        topicoSelecionado = 'Todos';
        // áreas e tópicos ficam no estado base
        areas = ['Todas'];
        topicos = ['Todos'];
      });
    } catch (e) {
      debugPrint('Erro a carregar cursos inscritos: $e');
      setState(() => isLoading = false);
    }
  }

  // ---------------------------
  // Lógica de filtros
  // ---------------------------

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
      cursosFiltrados = cursosInscritos.where((c) {
        final matchTexto =
            (c.titulo?.toLowerCase() ?? '').contains(q) ||
            (c.descricao?.toLowerCase() ?? '').contains(q);

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

  // ---------------------------
  // BottomSheets dos filtros
  // ---------------------------

  Future<void> abrirFiltroTipo() async {
    final resultado = await showModalBottomSheet<String>(
      context: context,
      builder: (context) => ListView(
        children: _tipos
            .map((tipo) => ListTile(
                  title: Text(tipo),
                  onTap: () => Navigator.pop(context, tipo),
                ))
            .toList(),
      ),
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
        children: categorias
            .map((cat) => ListTile(
                  title: Text(cat),
                  onTap: () => Navigator.pop(context, cat),
                ))
            .toList(),
      ),
    );
    if (resultado != null) {
      setState(() {
        categoriaSelecionada = resultado;

        // reset dependentes
        areaSelecionada = 'Todas';
        topicoSelecionado = 'Todos';
      });
      await carregarAreas();   // usa meta da API
      await carregarTopicos(); // reseta para ['Todos']
      aplicarFiltros();
    }
  }

  Future<void> abrirFiltroArea() async {
    final resultado = await showModalBottomSheet<String>(
      context: context,
      builder: (context) => ListView(
        children: areas
            .map((area) => ListTile(
                  title: Text(area),
                  onTap: () => Navigator.pop(context, area),
                ))
            .toList(),
      ),
    );
    if (resultado != null) {
      setState(() {
        areaSelecionada = resultado;
        topicoSelecionado = 'Todos';
      });
      await carregarTopicos(); // usa meta da API
      aplicarFiltros();
    }
  }

  Future<void> abrirFiltroTopico() async {
    final resultado = await showModalBottomSheet<String>(
      context: context,
      builder: (context) => ListView(
        children: topicos
            .map((topico) => ListTile(
                  title: Text(topico),
                  onTap: () => Navigator.pop(context, topico),
                ))
            .toList(),
      ),
    );
    if (resultado != null) {
      setState(() => topicoSelecionado = resultado);
      aplicarFiltros();
    }
  }

  // ---------------------------
  // UI
  // ---------------------------

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Os Meus Cursos',
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Os Meus Cursos',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
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
                  : cursosFiltrados.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.school, size: 50, color: Colors.grey),
                              const SizedBox(height: 16),
                              const Text('Nenhum curso inscrito', style: TextStyle(fontSize: 18)),
                              TextButton(onPressed: carregarCursos, child: const Text('Recarregar')),
                            ],
                          ),
                        )
                      : RefreshIndicator(
                          onRefresh: carregarCursos,
                          child: GridView.builder(
                            itemCount: cursosFiltrados.length,
                            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              crossAxisSpacing: 12,
                              mainAxisSpacing: 12,
                              childAspectRatio: 0.75,
                            ),
                            itemBuilder: (context, index) {
                              final curso = cursosFiltrados[index];
                              return CursoCard(
                                curso: curso,
                                onTap: () async {
                                  final precisaAtualizar = await Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => DetalhesCursoPage(curso: curso),
                                    ),
                                  );

                                  if (precisaAtualizar == true) {
                                    await carregarCursos();
                                    if (mounted) setState(() {});
                                  }
                                },
                              );
                            },
                          ),
                        ),
            ),
          ],
        ),
      ),
    );
  }
}
