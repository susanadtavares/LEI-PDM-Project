class NotificacaoModel {
  final int idNotificacao;
  String titulo;
  DateTime data;
  String estado;
  String? cursoTitulo;
  bool notificacaoAtiva;

  NotificacaoModel({
    required this.idNotificacao,
    required this.titulo,
    required this.data,
    required this.estado,
    this.cursoTitulo,
    required this.notificacaoAtiva,
  });

  factory NotificacaoModel.fromJson(Map<String, dynamic> json) {
    return NotificacaoModel(
      idNotificacao: json['id_notificacao'],
      titulo: json['titulo_notificacao'],
      data: DateTime.parse(json['data_notificacao']),
      estado: json['estado'],
      cursoTitulo: json['curso']?['titulo'],
      notificacaoAtiva: json['notificar']?['notificacao_ativa'] ?? false,
    );
  }
}
