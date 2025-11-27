
class Formando {
  final int id_formando;
  final int id_utilizador;
  final int n_cursosacabados;
  final int n_cursosinscritos;
  final String descricao_formando;
  final String educacao_formando;
  final String habilidades_formando;
  final String certificacoes_formando;
  String? foto_perfil;
  final DateTime data_inscricao;
  final bool formando_ativo;

Formando({
  required this.id_formando,
  required this.id_utilizador,
  required this.n_cursosacabados,
  required this.n_cursosinscritos,
  required this.descricao_formando,
  required this.educacao_formando,
  required this.habilidades_formando,
  required this.certificacoes_formando,
  this.foto_perfil,
  required this.data_inscricao,
  this.formando_ativo = true,
});

factory Formando.fromJson(Map<String, dynamic> json) {
  return Formando(
    id_formando: json['id_formando'],
    id_utilizador: json['id_utilizador'],
    n_cursosacabados: json['n_cursosacabados'] ?? 0,
    n_cursosinscritos: json['n_cursosinscritos'] ?? 0,
    descricao_formando: json['descricao_formando'],
    educacao_formando: json['educacao_formando'],
    habilidades_formando: json['habilidades_formando'],
    certificacoes_formando: json['certificacoes_formando'],
    foto_perfil: json['foto_perfil'],
    data_inscricao: DateTime.parse(json['data_inscricao']),
    formando_ativo: json['formando_ativo'] == true || json['formando_ativo'] == 1,
  );
}

Map<String, dynamic> toJson() {
  return {
    'id_formando': id_formando,
    'id_utilizador': id_utilizador,
    'n_cursosacabados': n_cursosacabados,
    'n_cursosinscritos': n_cursosinscritos,
    'descricao_formando': descricao_formando,
    'educacao_formando': educacao_formando,
    'habilidades_formando': habilidades_formando,
    'certificacoes_formando': certificacoes_formando,
    'foto_perfil': foto_perfil,
    'data_inscricao': data_inscricao.toIso8601String(),
    'formando_ativo': formando_ativo ? 1 : 0,
  };
}
}