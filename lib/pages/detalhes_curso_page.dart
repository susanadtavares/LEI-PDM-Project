import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import '../models/curso.dart';
import '../API/api_service.dart';
import 'aulas_curso_page.dart';

class DetalhesCursoPage extends StatefulWidget {
  final Curso curso;

  const DetalhesCursoPage({Key? key, required this.curso}) : super(key: key);

  @override
  State<DetalhesCursoPage> createState() => _DetalhesCursoPageState();
}

class _DetalhesCursoPageState extends State<DetalhesCursoPage> {
  Curso? cursoDetalhado;
  Map<String, dynamic>? dadosExtras;
  bool isLoading = true;
  bool hasError = false;
  bool inscrito = false;

  @override
  void initState() {
    super.initState();
    carregarDetalhesCurso();
    verificarInscricao();
  }

  Future<void> verificarInscricao() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final email = prefs.getString('email_logado');
      if (email != null) {
        final inscricoes = await ApiService.getInscricoes(email);
        if (mounted) {
          setState(() {
            inscrito = inscricoes.any((c) => c['id_curso'] == widget.curso.id_curso);
          });
        }
      }
    } catch (e) {
      print('[DEBUG] Erro ao verificar inscrição: $e');
    }
  }

  Future<void> carregarDetalhesCurso() async {
    try {
      // Usa só o método moderno com JWT
      final curso = await ApiService.apiGetCursoById(widget.curso.id_curso, backoffice: false);
      if (mounted) {
        setState(() {
          cursoDetalhado = curso;
          dadosExtras = curso.toJson(); // Usa o toJson do modelo
          isLoading = false;
        });
      }
    } catch (e) {
      print('[DEBUG] Erro ao carregar curso: $e');
      if (mounted) {
        setState(() {
          hasError = true;
          isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Scaffold(
        appBar: AppBar(title: Text(widget.curso.titulo)),
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 20),
              Text('Carregando detalhes do curso...'),
            ],
          ),
        ),
      );
    }

    if (hasError) {
      return Scaffold(
        appBar: AppBar(title: Text(widget.curso.titulo)),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error, color: Colors.red, size: 50),
              const SizedBox(height: 20),
              const Text('Erro ao carregar detalhes'),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: carregarDetalhesCurso,
                child: const Text('Tentar novamente'),
              ),
            ],
          ),
        ),
      );
    }

    final curso = cursoDetalhado ?? widget.curso;
    final dados = dadosExtras ?? curso.toJson();

    return WillPopScope(
      onWillPop: () async {
        Navigator.pop(context, inscrito);
        return false;
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF8F5FB),
        appBar: AppBar(
          title: Text(curso.titulo),
          backgroundColor: const Color(0xFF295C99),
        ),
        body: _buildBody(dados),
      ),
    );
  }

  Widget _buildBody(Map<String, dynamic> dados) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            dados['descricao']?.toString() ?? widget.curso.descricao,
            style: const TextStyle(fontSize: 16),
          ),
          const SizedBox(height: 20),
          _buildInscricaoButtons(),
          const SizedBox(height: 20),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                children: [
                  _buildCursoImage(dados),
                  const SizedBox(height: 12),
                  _buildCursoInfo(dados),
                ],
              ),
            ),
          ),
          if (dados['objetivos'] != null) _buildSection('Objetivos', dados['objetivos']),
          if (dados['publicoAlvo'] != null) _buildSection('Público-Alvo', dados['publicoAlvo']),
        ],
      ),
    );
  }

  Widget _buildInscricaoButtons() {
    if (inscrito) {
      return Row(
        children: [
          Expanded(
            child: ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => AulasCursoPage(
                      id_curso: widget.curso.id_curso,
                      curso_titulo: widget.curso.titulo,
                    ),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: const Text('Continuar'),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: ElevatedButton(
              onPressed: () async {
                try {
                  final prefs = await SharedPreferences.getInstance();
                  final email = prefs.getString('email_logado');
                  if (email != null) {
                    await ApiService.cancelarInscricao(email, widget.curso.id_curso);
                    if (mounted) {
                      setState(() => inscrito = false);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Inscrição anulada.')),
                      );
                      Navigator.pop(context, true);
                    }
                  }
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Erro ao anular inscrição: $e')),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: const Text('Anular Inscrição'),
            ),
          ),
        ],
      );
    } else {
      return ElevatedButton(
        onPressed: () async {
          try {
            final prefs = await SharedPreferences.getInstance();
            final email = prefs.getString('email_logado');
            if (email != null) {
              await ApiService.inscreverCurso(email, widget.curso.id_curso);
              if (mounted) {
                setState(() => inscrito = true);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Inscrição confirmada!')),
                );
              }
            }
          } catch (e) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Erro ao inscrever: $e')),
            );
          }
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF295C99),
          padding: const EdgeInsets.symmetric(vertical: 14),
          minimumSize: const Size(double.infinity, 50),
        ),
        child: const Text('Inscrever-se'),
      );
    }
  }

  Widget _buildCursoImage(Map<String, dynamic> dados) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Image.network(
        dados['thumbnail']?.toString() ?? 'https://via.placeholder.com/300x150',
        height: 150,
        width: double.infinity,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => Container(
          height: 150,
          color: Colors.grey[200],
          child: const Icon(Icons.image_not_supported, size: 50),
        ),
      ),
    );
  }

  Widget _buildCursoInfo(Map<String, dynamic> dados) {
    String formatarData(dynamic data) {
      if (data == null) return 'Não disponível';
      try {
        DateTime dt;
        if (data is DateTime) {
          dt = data;
        } else if (data is String) {
          dt = DateTime.parse(data);
        } else {
          return 'Formato inválido';
        }
        return DateFormat('dd/MM/yyyy').format(dt);
      } catch (e) {
        return 'Data inválida';
      }
    }

    return Column(
      children: [
        _buildInfoRow('Duração', '${dados['duracao'] ?? widget.curso.duracao ?? 0} horas'),
        _buildInfoRow('Início', formatarData(dados['data_inicio'] ?? widget.curso.data_inicio)),
        _buildInfoRow('Formador', dados['formador']?.toString() ?? 'Não informado'),
        _buildInfoRow('Avaliação', (dados['avaliacao'] is num)
            ? (dados['avaliacao'] as num).toStringAsFixed(1)
            : (widget.curso.avaliacao?.toStringAsFixed(1) ?? '0.0')),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          const Icon(Icons.info_outline, size: 20, color: Colors.blue),
          const SizedBox(width: 10),
          Text('$label: ', style: const TextStyle(fontWeight: FontWeight.bold)),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  Widget _buildSection(String title, dynamic content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 20),
        Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        if (content is List)
          ...content.map((item) => Padding(
                padding: const EdgeInsets.only(left: 8, bottom: 4),
                child: Text('• ${item.toString()}'),
              )).toList()
        else
          Text(content.toString()),
      ],
    );
  }
}