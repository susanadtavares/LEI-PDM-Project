//enum, representação de curso
enum TipoCurso { Sincrono, Assincrono }

class Curso {
  final int id_curso;
  final int id_area;
  final int id_topico;
  final int id_categoria;
  final int? duracao;
  final int membros;
  final int? num_vagas;
  final String descricao;
  final String titulo;
  final double? avaliacao;
  final String? tumbnail;
  final DateTime? data_inicio;
  final DateTime? data_limite_inscricao;
  final DateTime? data_fim;
  final String introducao_curso;
  final TipoCurso tipo;
  final int? id_formador;
  final int criado_por;
  final bool curso_ativo;
  final bool curso_visivel;
  final String? categoria;
  final String? area;
  final String? topico;

  Curso({
    required this.id_curso,
    required this.id_area,
    required this.id_topico,
    required this.id_categoria,
    this.duracao,
    required this.membros,
    this.num_vagas,
    required this.descricao,
    required this.titulo,
    this.avaliacao,
    this.tumbnail,
    this.data_inicio,
    this.data_limite_inscricao,
    this.data_fim,
    required this.introducao_curso,
    required this.tipo,
    this.id_formador,
    required this.criado_por,
    this.curso_ativo = true,
    this.curso_visivel = true,
    this.categoria,
    this.area,
    this.topico,
  });

  // Método para converter o JSON da API para um objeto Curso
  factory Curso.fromJson(Map<String, dynamic> json) {
    return Curso(
      id_curso: json['id_curso'],
      id_area: json['id_area'],
      id_topico: json['id_topico'],
      id_categoria: json['id_categoria'],
      duracao: json['duracao'],
      membros: json['membros'] ?? 0,
      num_vagas: json['num_vagas'] ?? 0,
      descricao: json['descricao'],
      titulo: json['titulo'],
      avaliacao: json['avaliacao'] != null
          ? double.tryParse(json['avaliacao'].toString()) // Tenta converter a string para double
          : null,
      tumbnail: json['tumbnail'],
      data_inicio: json['data_inicio'] != null
          ? DateTime.tryParse(json['data_inicio'].toString())
          : null,
      data_limite_inscricao: json['data_limite_inscricao'] != null
          ? DateTime.tryParse(json['data_limite_inscricao'].toString())
          : null,
      data_fim: json['data_fim'] != null
          ? DateTime.tryParse(json['data_fim'].toString())
          : null,
      introducao_curso: json['introducao_curso'] ?? '',
      tipo: json['tipo'] == 'Sincrono'
          ? TipoCurso.Sincrono
          : TipoCurso.Assincrono,
      id_formador: json['id_formador'],
      criado_por: json['criado_por'],
      curso_ativo: json['curso_ativo'] ?? true, 
      curso_visivel: json['curso_visivel'] ?? true, 
      categoria: json['categoria'] as String?,
      area: json['area'] as String?,
      topico: json['topico'] as String?,
    );
  }


  Map<String, dynamic> toJson() {
    return {
      'id_curso': id_curso,
      'id_area': id_area,
      'id_topico': id_topico,
      'id_categoria': id_categoria,
      'duracao': duracao,
      'membros': membros,
      'num_vagas': num_vagas,
      'descricao': descricao,
      'titulo': titulo,
      'avaliacao': avaliacao,
      'tumbnail': tumbnail,
      'data_inicio': data_inicio?.toIso8601String(), 
      'data_limite_inscricao': data_limite_inscricao?.toIso8601String(), 
      'data_fim': data_fim?.toIso8601String(), 
      'introducao_curso': introducao_curso,
      'tipo': tipo.toString().split('.').last, 
      'criado_por': criado_por,
      'curso_ativo': curso_ativo,
      'curso_visivel': curso_visivel,
      'categoria': categoria,
      'area': area,
      'topico': topico,
    };
  }
}
