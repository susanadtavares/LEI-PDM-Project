class Aula {
  final int id_aula;
  final int id_curso;
  final String? url_video;
  final String titulo_aula;
  final String descricao_aula;
  final bool aula_ativa;
  

  Aula({
    required this.id_aula,
    required this.id_curso,
    this.url_video,
    required this.titulo_aula,
    required this.descricao_aula,
    required this.aula_ativa,

  });

  factory Aula.fromJson(Map<String, dynamic> json) {
    return Aula(
      id_aula: json['id_aula'],
      id_curso: json['id_curso'],
      titulo_aula: json['titulo_aula'],
      descricao_aula: json['descricao_aula'],
      url_video: json['url_video'],
      aula_ativa: json['aula_ativa'] == true || json['aula_ativa'] == 1,  
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id_aula': id_aula,
      'id_curso': id_curso,
      'titulo_aula': titulo_aula,
      'descricao_aula': descricao_aula,
      'url_video': url_video,
      'aula_ativa': aula_ativa,
    };
  }
}