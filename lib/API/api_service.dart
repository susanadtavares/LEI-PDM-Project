import 'dart:convert';
import 'package:http/http.dart' as http;
import 'dart:io';


// modelos existentes
import '../models/curso.dart';
import '../models/aula.dart';
import '../models/notificacao.dart';

// novos: gerir token + exceções “limpas”
import 'session_manager.dart';
import 'exceptions.dart';

class ApiService {
  static const String baseUrl = 'https://pint-backend-t819.onrender.com';

  // =====================================================================
  // AUTH HELPERS
  // =====================================================================

  static Future<Map<String, String>> _authHeaders() async {
    final token = await SessionManager.getToken();
    if (token == null) {
      throw ApiException('Sessão expirada. Inicie sessão novamente.');
    }
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  // =====================================================================
  // META (apenas mobile) — cache id -> nome + listas completas
  // =====================================================================

  static bool _metaLoaded = false;

  // Mapas id -> nome
  static final Map<int, String> _catNome = {};
  static final Map<int, String> _areaNome = {};
  static final Map<int, String> _topicoNome = {};

  // Listas completas para hierarquia (cada item é um Map com ids e nomes)
  static List<Map<String, dynamic>> _areasFull = [];
  static List<Map<String, dynamic>> _topicosFull = [];

  static int? _toInt(dynamic v) {
    if (v == null) return null;
    if (v is int) return v;
    if (v is String) return int.tryParse(v);
    return null;
  }

  static Future<void> _carregarCategoriasFull() async {
    final res = await http.get(
      Uri.parse('$baseUrl/api/categorias'),
      headers: await _authHeaders(),
    );
    if (res.statusCode == 200) {
      final b = jsonDecode(res.body);
      final list = (b is Map && b['sucesso'] == true && b['data'] is List)
          ? (b['data'] as List)
          : const [];
      _catNome
        ..clear()
        ..addEntries(list.map((e) {
          final m = Map<String, dynamic>.from(e as Map);
          return MapEntry<int, String>(
            _toInt(m['id_categoria']) ?? -1,
            (m['nome_categoria'] ?? '').toString(),
          );
        }).where((kv) => kv.key != -1));
      return;
    }
    throw ApiException('Falha categorias (${res.statusCode})');
  }

  static Future<void> _carregarAreasFull() async {
    final res = await http.get(
      Uri.parse('$baseUrl/api/areas'),
      headers: await _authHeaders(),
    );
    if (res.statusCode == 200) {
      final b = jsonDecode(res.body);
      final list = (b is Map && b['sucesso'] == true && b['data'] is List)
          ? (b['data'] as List)
          : const [];
      _areaNome
        ..clear();
      _areasFull = list.map<Map<String, dynamic>>((e) {
        final m = Map<String, dynamic>.from(e as Map);
        final id = _toInt(m['id_area']) ?? -1;
        final nome = (m['nome_area'] ?? '').toString();
        final idCat = _toInt(m['id_categoria']) ??
            _toInt((m['categoria'] is Map) ? (m['categoria']['id_categoria']) : null);
        if (id != -1) _areaNome[id] = nome;
        return {
          'id_area': id,
          'nome_area': nome,
          'id_categoria': idCat,
        };
      }).toList();
      return;
    }
    throw ApiException('Falha áreas (${res.statusCode})');
  }

  static Future<void> _carregarTopicosFull() async {
    final res = await http.get(
      Uri.parse('$baseUrl/api/topicos'),
      headers: await _authHeaders(),
    );
    if (res.statusCode == 200) {
      final b = jsonDecode(res.body);
      final list = (b is Map && b['sucesso'] == true && b['data'] is List)
          ? (b['data'] as List)
          : const [];
      _topicoNome
        ..clear();
      _topicosFull = list.map<Map<String, dynamic>>((e) {
        final m = Map<String, dynamic>.from(e as Map);
        final id = _toInt(m['id_topico']) ?? -1;
        final nome = (m['nome_topico'] ?? '').toString();
        // id_area pode vir direto ou dentro de m['area']
        final idArea = _toInt(m['id_area']) ??
            _toInt((m['area'] is Map) ? (m['area']['id_area']) : null);
        if (id != -1) _topicoNome[id] = nome;
        return {
          'id_topico': id,
          'nome_topico': nome,
          'id_area': idArea,
        };
      }).toList();
      return;
    }
    throw ApiException('Falha tópicos (${res.statusCode})');
  }

  static Future<void> _ensureMeta() async {
    if (_metaLoaded) return;
    await Future.wait([
      _carregarCategoriasFull(),
      _carregarAreasFull(),
      _carregarTopicosFull(),
    ]);
    _metaLoaded = true;
  }

  static String? _nomeCategoria(int? id) => id != null ? _catNome[id] : null;
  static String? _nomeArea(int? id) => id != null ? _areaNome[id] : null;
  static String? _nomeTopico(int? id) => id != null ? _topicoNome[id] : null;

  // Helpers públicos para os botões dependentes
  static Future<List<String>> getAreasByCategoriaNome(String? categoriaNome) async {
    await _ensureMeta();
    if (categoriaNome == null || categoriaNome == 'Todas') return [];
    // descobrir id da categoria pelo nome
    final idCat = _catNome.entries
        .firstWhere((e) => e.value == categoriaNome, orElse: () => const MapEntry(-1, ''))
        .key;
    if (idCat == -1) return [];
    final nomes = _areasFull
        .where((a) => a['id_categoria'] == idCat)
        .map((a) => (a['nome_area'] ?? '').toString())
        .where((s) => s.isNotEmpty)
        .toSet()
        .toList()
      ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
    return nomes;
  }

  static Future<List<String>> getTopicosByAreaNome(String? areaNome) async {
    await _ensureMeta();
    if (areaNome == null || areaNome == 'Todas') return [];
    // descobrir id da área pelo nome
    final idArea = _areasFull
        .firstWhere(
          (a) => (a['nome_area'] ?? '').toString() == areaNome,
          orElse: () => const {'id_area': -1},
        )['id_area'] as int;
    if (idArea == -1) return [];
    final nomes = _topicosFull
        .where((t) => t['id_area'] == idArea)
        .map((t) => (t['nome_topico'] ?? '').toString())
        .where((s) => s.isNotEmpty)
        .toSet()
        .toList()
      ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
    return nomes;
  }

  static Map<String, dynamic> _enriquecerCursoMap(Map<String, dynamic> m) {
    m['categoria'] ??= _nomeCategoria(_toInt(m['id_categoria']));
    m['area']      ??= _nomeArea(_toInt(m['id_area']));
    m['topico']    ??= _nomeTopico(_toInt(m['id_topico']));
    m['categoria'] ??= 'Todas';
    m['area']      ??= 'Todas';
    m['topico']    ??= 'Todos';
    return m;
  }

  static Future<List<Curso>> _mapCursosComMeta(List list) async {
    await _ensureMeta();
    return list.map((e) {
      final m = Map<String, dynamic>.from(e as Map);
      return Curso.fromJson(_enriquecerCursoMap(m));
    }).toList();
  }

  static Future<Curso> _mapCursoComMeta(Map<String, dynamic> obj) async {
    await _ensureMeta();
    return Curso.fromJson(_enriquecerCursoMap(obj));
  }

  // =====================================================================
  // LOGIN  (MANTIDO COMO TINHAS)
  // =====================================================================

  static Future<Map<String, dynamic>> login(String email, String password) async {
    final url = Uri.parse('$baseUrl/api/auth/login');

    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'password': password}),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else if (response.statusCode == 401) {
      throw ApiException('Credenciais inválidas');
    } else {
      throw ApiException('Erro ao fazer login: ${response.statusCode}');
    }
  }

  //utilizador por id 
  static Future<Map<String, dynamic>> getUtilizadorById(int id) async {
  final res = await http.get(
    Uri.parse('$baseUrl/api/utilizadores/$id'),
    headers: await _authHeaders(),
  );

  if (res.statusCode == 200) {
    return jsonDecode(res.body) as Map<String, dynamic>; // <-- remover ['data']
  } else {
    throw ApiException('Erro ao obter utilizador (${res.statusCode})');
  }
}
//Formando por id_utilizador
static Future<Map<String, dynamic>> getFormandoByIdUtilizador(int idUtilizador, int idFormando) async {
  final res = await http.get(
    Uri.parse('$baseUrl/api/formandos/$idUtilizador/$idFormando'),
    headers: await _authHeaders(),
  );

  if (res.statusCode == 200) {
    return jsonDecode(res.body) as Map<String, dynamic>;
  } else {
    throw ApiException('Erro ao obter formando (${res.statusCode})');
  }
}

// Enviar pedido de registo
  static Future<void> criarPedido(Map<String, dynamic> pedido) async {
  final url = Uri.parse('$baseUrl/api/pedidos-registo'); // endpoint correto
  final response = await http.post(
    url,
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode(pedido),
  );

  if (response.statusCode != 201) {
    throw Exception('Falha ao criar pedido: ${response.body}');
  }
}


  // =====================================================================
  // ENDPOINTS ANTIGOS (MANTIDOS)  — sem /api e sem JWT
  // =====================================================================

  static Future<List<dynamic>> getCursos() async {
    final response = await http.get(Uri.parse('$baseUrl/cursos'));
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw ApiException('Erro ao carregar cursos');
    }
  }

  static Future<void> inscreverCurso(String email, int idCurso) async {
    final response = await http.post(
      Uri.parse('$baseUrl/inscricoes'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'id_curso': idCurso}),
    );
    if (response.statusCode != 200) {
      throw ApiException('Erro ao inscrever-se');
    }
  }

  static Future<void> cancelarInscricao(String email, int idCurso) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/inscricoes/$email/$idCurso'),
    );
    if (response.statusCode != 200) {
      throw ApiException('Erro ao cancelar inscrição');
    }
  }

  static Future<List<dynamic>> getInscricoes(String email) async {
    final response = await http.get(Uri.parse('$baseUrl/inscricoes/$email'));
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw ApiException('Erro ao carregar inscrições');
    }
  }

  static Future<List<Curso>> obterCursosInscritos(String email) async {
    final response = await http.get(Uri.parse('$baseUrl/inscricoes/$email'));
    if (response.statusCode == 200) {
      final listaJson = jsonDecode(response.body) as List;
      return listaJson.map((c) => Curso.fromJson(c)).toList();
    } else {
      throw ApiException('Erro ao carregar cursos inscritos');
    }
  }

  static Future<Map<String, dynamic>> getUtilizador(String email) async {
    final response = await http.get(Uri.parse('$baseUrl/utilizadores/$email'));
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw ApiException('Erro ao obter utilizador');
    }
  }

  // Obter dados completos do formando 
static Future<Map<String, dynamic>> getFormandoCompleto(int idUtilizador, int idFormando) async {
  final res = await http.get(
    Uri.parse('$baseUrl/api/formandos/$idUtilizador/$idFormando/full'),
    headers: await _authHeaders(),
  );

  if (res.statusCode == 200) {
    return jsonDecode(res.body) as Map<String, dynamic>;
  } else {
    throw ApiException('Erro ao obter dados completos do formando (${res.statusCode}): ${res.body}');
  }
}


//Atualizar a foto de perfil
Future<String?> uploadImagem(File imageFile) async {
  final uri = Uri.parse('https://pint-backend-t819.onrender.com/api/upload/');

  final request = http.MultipartRequest('POST', uri);

  // basta isto, não precisas de lookupMimeType
  request.files.add(await http.MultipartFile.fromPath(
    'image',
    imageFile.path,
  ));

  final response = await request.send();

  if (response.statusCode == 200) {
    final respStr = await response.stream.bytesToString();
    final data = jsonDecode(respStr);
    return data['url']; // Cloudinary devolve o link seguro
  } else {
    throw Exception('Erro ao enviar imagem: ${response.statusCode}');
  }
}

 //Atualizar dados do formando
 static Future<void> updateFormandoCompleto({
  required int idUtilizador,
  required int idFormando,
  String? nome,
  String? email,
  String? telemovel,
  String? genero,
  String? dataNascimento,
  String? fotoPerfil,
}) async {
  final body = <String, dynamic>{};
  
  if (nome != null) body['nome'] = nome;
  if (email != null) body['email'] = email;
  if (telemovel != null) body['telemovel'] = telemovel;
  if (genero != null) body['genero'] = genero;
  if (dataNascimento != null) body['data_nascimento'] = dataNascimento;
  if (fotoPerfil != null) body['foto_perfil'] = fotoPerfil;

  final res = await http.put(
    Uri.parse('$baseUrl/api/formandos/$idUtilizador/$idFormando/full'),
    headers: await _authHeaders(),
    body: jsonEncode(body),
  );

  if (res.statusCode != 200) {
    throw ApiException('Erro ao atualizar formando (${res.statusCode}): ${res.body}');
  }
}
static Future<void> updateFormandoFoto(int idUtilizador, int idFormando, String url, String token) async {
  final response = await http.put(
    Uri.parse('https://pint-backend-t819.onrender.com/api/formandos/$idUtilizador/$idFormando/full'),
    headers: {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    },
    body: jsonEncode({'foto_perfil': url}),
  );

  if (response.statusCode != 200) {
    throw Exception('Falha ao atualizar foto: ${response.body}');
  }
}

Future<List<NotificacaoModel>> getNotificacoes(int idUtilizador) async {
    final url = Uri.parse('$baseUrl/api/notificacoes/minhas/$idUtilizador');

    final token = await SessionManager.getToken();
    if (token == null) {
      throw Exception("Usuário não autenticado");
    }

    final response = await http.get(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);
      return data.map((json) => NotificacaoModel.fromJson(json)).toList();
    } else {
      print('Erro ${response.statusCode}: ${response.body}');
      throw Exception("Erro ao carregar notificações");
    }
  }

  Future<void> marcarNotificacaoComoLida(int idUtilizador, int idNotificacao) async {
    final url = Uri.parse('$baseUrl/api/notificacoes/marcar-lida/$idUtilizador/$idNotificacao');
    final token = await SessionManager.getToken();

    if (token == null) throw Exception("Usuário não autenticado");

    final response = await http.put(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode != 200) {
      print('Erro ${response.statusCode}: ${response.body}');
      throw Exception("Erro ao marcar notificação como lida");
    }
  }







  static Future<List<Aula>> getAula(int idCurso) async {
    final response = await http.get(Uri.parse('$baseUrl/cursos/$idCurso/aulas'));
    if (response.statusCode == 200) {
      final listaJson = jsonDecode(response.body) as List;
      return listaJson.map((json) => Aula.fromJson(json)).toList();
    } else {
      throw ApiException('Erro ao carregar aulas');
    }
  }

  static Future<void> atualizarPassword({
    required int idUtilizador,
    required String token,
    required String novaPassword,
  }) async {
    final response = await http.put(
      Uri.parse('$baseUrl/utilizadores/$idUtilizador/alterar-password-primeiro-login'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({'novaPassword': novaPassword}),
    );
    if (response.statusCode != 200) {
      throw ApiException('Erro ao atualizar password: ${response.body}');
    }
  }
  
//verificação da existência do email
static Future<bool> emailExiste(String email) async {
  final url = Uri.parse('$baseUrl/api/pedidos-registo'); // endpoint correto
  final response = await http.get(url, headers: {'Content-Type': 'application/json'});

  if (response.statusCode != 200) {
    throw Exception('Erro ao verificar email: ${response.body}');
  }

  final List dados = jsonDecode(response.body); // agora é JSON
  return dados.any((u) => u['email'] == email);
}



  static Future<List<dynamic>> getTodos() async {
    final response = await http.get(Uri.parse('$baseUrl/utilizadores'));
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw ApiException('Erro ao carregar utilizadores');
    }
  }

  static Future<void> adicionarUtilizador(Map<String, dynamic> user) async {
    final response = await http.post(
      Uri.parse('$baseUrl/utilizadores'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(user),
    );

    if (response.statusCode != 200) {
      throw ApiException('Erro ao adicionar utilizador');
    }
  }

  // =====================================================================
  // NOVOS MÉTODOS /api/... com JWT
  // =====================================================================

  static Future<List<Curso>> apiGetCursos({bool backoffice = false}) async {
    final uri = Uri.parse('$baseUrl/api/cursos')
        .replace(queryParameters: backoffice ? {'backoffice': 'true'} : null);

    final res = await http.get(uri, headers: await _authHeaders());
    if (res.statusCode == 200) {
      final list = jsonDecode(res.body) as List;
      return _mapCursosComMeta(list);
    }
    throw ApiException('Erro ao carregar cursos (${res.statusCode}): ${res.body}');
  }

  static Future<Curso> apiGetCursoById(int id, {bool backoffice = false}) async {
    final uri = Uri.parse('$baseUrl/api/cursos/$id')
        .replace(queryParameters: backoffice ? {'backoffice': 'true'} : null);

    final res = await http.get(uri, headers: await _authHeaders());
    if (res.statusCode == 200) {
      final body = jsonDecode(res.body);
      final obj = Map<String, dynamic>.from(body['data'] as Map);
      return _mapCursoComMeta(obj);
    }
    throw ApiException('Erro ao carregar curso $id (${res.statusCode}): ${res.body}');
  }

  static Future<List<Curso>> apiGetCursosByCategoria(int id) async {
    final res = await http.get(
      Uri.parse('$baseUrl/api/cursos/categoria/$id'),
      headers: await _authHeaders(),
    );
    if (res.statusCode == 200) {
      final body = jsonDecode(res.body);
      final list = (body['data'] as List?) ?? const [];
      return _mapCursosComMeta(list);
    }
    throw ApiException('Erro por categoria (${res.statusCode}): ${res.body}');
  }

  static Future<List<Curso>> apiGetCursosByArea(int id) async {
    final res = await http.get(
      Uri.parse('$baseUrl/api/cursos/area/$id'),
      headers: await _authHeaders(),
    );
    if (res.statusCode == 200) {
      final body = jsonDecode(res.body);
      final list = (body['data'] as List?) ?? const [];
      return _mapCursosComMeta(list);
    }
    throw ApiException('Erro por área (${res.statusCode}): ${res.body}');
  }

  static Future<List<Curso>> apiGetCursosByTopico(int id) async {
    final res = await http.get(
      Uri.parse('$baseUrl/api/cursos/topico/$id'),
      headers: await _authHeaders(),
    );
    if (res.statusCode == 200) {
      final body = jsonDecode(res.body);
      final list = (body['data'] as List?) ?? const [];
      return _mapCursosComMeta(list);
    }
    throw ApiException('Erro por tópico (${res.statusCode}): ${res.body}');
  }

  static Future<Map<String, dynamic>> apiGetMembrosDoCurso(int idCurso) async {
    final res = await http.get(
      Uri.parse('$baseUrl/api/cursos/$idCurso/membros'),
      headers: await _authHeaders(),
    );
    if (res.statusCode == 200) {
      return jsonDecode(res.body) as Map<String, dynamic>;
    }
    throw ApiException('Erro ao obter membros (${res.statusCode}): ${res.body}');
  }

  static Future<void> apiAdicionarMembro({
    required int idCurso,
    required int idFormando,
    required int idUtilizador,
  }) async {
    final res = await http.post(
      Uri.parse('$baseUrl/api/cursos/$idCurso/adicionar-membro'),
      headers: await _authHeaders(),
      body: jsonEncode({
        'id_formando': idFormando,
        'id_utilizador': idUtilizador,
      }),
    );
    if (res.statusCode != 200 && res.statusCode != 201) {
      throw ApiException('Erro ao adicionar membro (${res.statusCode}): ${res.body}');
    }
  }

  static Future<void> apiRemoverMembro({
    required int idCurso,
    required int idFormando,
    required int idUtilizador,
  }) async {
    final res = await http.post(
      Uri.parse('$baseUrl/api/cursos/$idCurso/remover-membro'),
      headers: await _authHeaders(),
      body: jsonEncode({
        'id_formando': idFormando,
        'id_utilizador': idUtilizador,
      }),
    );
    if (res.statusCode != 200) {
      throw ApiException('Erro ao remover membro (${res.statusCode}): ${res.body}');
    }
  }

  // =====================================================================
  // Meta para os botões (tolerante a ambos os formatos)
  // =====================================================================

  static Future<List<String>> getCategorias() async {
    final res = await http.get(
      Uri.parse('$baseUrl/api/categorias'),
      headers: await _authHeaders(),
    );
    if (res.statusCode == 200) {
      final decoded = jsonDecode(res.body);
      if (decoded is Map && decoded['categorias'] is List) {
        return (decoded['categorias'] as List).map((e) => e.toString()).toList();
      }
      if (decoded is Map && decoded['sucesso'] == true && decoded['data'] is List) {
        final list = decoded['data'] as List;
        return list
            .map((e) => (e['nome_categoria'] ?? e['nome'] ?? '').toString())
            .where((s) => s.isNotEmpty)
            .toList();
      }
    }
    throw ApiException('Erro ao carregar categorias (${res.statusCode}): ${res.body}');
  }

  // Listagens “planas” (compatibilidade com outras páginas)
  static Future<List<String>> getAreas() async {
    await _ensureMeta();
    final nomes = _areasFull
        .map((a) => (a['nome_area'] ?? '').toString())
        .where((s) => s.isNotEmpty)
        .toSet()
        .toList()
      ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
    return nomes;
  }

  static Future<List<String>> getTopicos() async {
    await _ensureMeta();
    final nomes = _topicosFull
        .map((t) => (t['nome_topico'] ?? '').toString())
        .where((s) => s.isNotEmpty)
        .toSet()
        .toList()
      ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
    return nomes;
  }
}
