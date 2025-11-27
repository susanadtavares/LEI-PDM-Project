class Utilizadores {
  final int idUtilizador;
  final String nome;
  final String email;
  final String palavraPass;
  final bool primeiroLogin;
  final String telemovel;
  final DateTime? dataNascimento; // <-- opcional
  final String? genero;           // <-- opcional
  final bool utilizadorAtivo;
  

  Utilizadores({
    required this.idUtilizador,
    required this.nome,
    required this.email,
    required this.palavraPass,
    this.primeiroLogin = true,
    required this.telemovel,
    this.dataNascimento,
    this.genero,
    this.utilizadorAtivo = true,
  });

  factory Utilizadores.fromJson(Map<String, dynamic> json) {
    DateTime? parseDate(String? value) {
      if (value == null || value.isEmpty) return null;
      try {
        return DateTime.parse(value);
      } catch (_) {
        return null;
      }
    }

    bool parseBool(dynamic value) {
      if (value == null) return false;
      if (value is bool) return value;
      if (value is int) return value == 1;
      if (value is String) return value.toLowerCase() == 'true' || value == '1';
      return false;
    }

    int parseInt(dynamic value) {
      if (value == null) return 0;
      if (value is int) return value;
      if (value is String) return int.tryParse(value) ?? 0;
      return 0;
    }

    return Utilizadores(
      idUtilizador: parseInt(json['id_utilizador']),
      nome: json['nome'] ?? '',
      email: json['email'] ?? '',
      palavraPass: json['palavra_pass'] ?? '',
      primeiroLogin: parseBool(json['primeiro_login']),
      telemovel: json['telemovel'] ?? '',
      dataNascimento: parseDate(json['data_nascimento']),
      genero: json['genero'],
      utilizadorAtivo: parseBool(json['utilizador_ativo']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id_utilizador': idUtilizador,
      'nome': nome,
      'email': email,
      'palavra_pass': palavraPass,
      'primeiro_login': primeiroLogin,
      'telemovel': telemovel,
      'data_nascimento': dataNascimento?.toIso8601String(),
      'genero': genero,
      'utilizador_ativo': utilizadorAtivo ? 1 : 0,
    };
  }
}
