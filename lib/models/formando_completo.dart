class FormandoCompleto {
  final int idFormando;
  final int idUtilizador;
  final String nome;
  final String email;
  final String telemovel;
  final String? genero;
  final DateTime? dataNascimento;
  final String? fotoPerfil;

  FormandoCompleto({
    required this.idFormando,
    required this.idUtilizador,
    required this.nome,
    required this.email,
    required this.telemovel,
    this.genero,
    this.dataNascimento,
    this.fotoPerfil,
  });

  factory FormandoCompleto.fromJson(Map<String, dynamic> json) {
    DateTime? parseDate(dynamic value) {
      if (value == null || value.toString().isEmpty) return null;
      try {
        return DateTime.parse(value.toString());
      } catch (_) {
        return null;
      }
    }

    int parseInt(dynamic value) {
      if (value == null) return 0;
      if (value is int) return value;
      if (value is String) return int.tryParse(value) ?? 0;
      return 0;
    }

    return FormandoCompleto(
      idFormando: parseInt(json['id_formando']),
      idUtilizador: parseInt(json['id_utilizador']),
      nome: json['nome']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      telemovel: json['telemovel']?.toString() ?? '',
      genero: json['genero']?.toString(),
      dataNascimento: parseDate(json['data_nascimento']),
      fotoPerfil: json['foto_perfil']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id_formando': idFormando,
      'id_utilizador': idUtilizador,
      'nome': nome,
      'email': email,
      'telemovel': telemovel,
      'genero': genero,
      'data_nascimento': dataNascimento?.toIso8601String(),
      'foto_perfil': fotoPerfil,
    };
  }

  FormandoCompleto copyWith({
    String? nome,
    String? email,
    String? telemovel,
    String? genero,
    DateTime? dataNascimento,
    String? fotoPerfil,
  }) {
    return FormandoCompleto(
      idFormando: idFormando,
      idUtilizador: idUtilizador,
      nome: nome ?? this.nome,
      email: email ?? this.email,
      telemovel: telemovel ?? this.telemovel,
      genero: genero ?? this.genero,
      dataNascimento: dataNascimento ?? this.dataNascimento,
      fotoPerfil: fotoPerfil ?? this.fotoPerfil,
    );
  }
}