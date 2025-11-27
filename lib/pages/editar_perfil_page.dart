import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import '../models/formando_completo.dart';
import '../API/api_service.dart';
import '../API/session_manager.dart';
import 'package:http_parser/http_parser.dart';

class EditarPerfilPage extends StatefulWidget {
  final int idUtilizador;
  final int idFormando;

  const EditarPerfilPage({
    Key? key,
    required this.idUtilizador,
    required this.idFormando,
  }) : super(key: key);

  @override
  State<EditarPerfilPage> createState() => _EditarPerfilPageState();
}

class _EditarPerfilPageState extends State<EditarPerfilPage> {
  final _formKey = GlobalKey<FormState>();
  final _nomeController = TextEditingController();
  final _telemovelController = TextEditingController();

  
  String? _genero;
  String? _fotoPerfil; 
  File? _localFoto; 

  bool _isLoading = true;
  bool _isSaving = false;

  final List<String> _generosDisponiveis = ['Masculino', 'Feminino', 'Outro'];

  @override
  void initState() {
    super.initState();
    _carregarDados();
  }

 
  Future<void> _carregarDados() async {
    try {
      final dados = await ApiService.getFormandoCompleto(
        widget.idUtilizador,
        widget.idFormando,
      );

      final formando = FormandoCompleto.fromJson(dados);

      if (!mounted) return;
      setState(() {
        _nomeController.text = formando.nome;
        _telemovelController.text = formando.telemovel;
        _genero = formando.genero;
        _fotoPerfil = formando.fotoPerfil?.isNotEmpty == true &&
                formando.fotoPerfil!.startsWith('http')
            ? formando.fotoPerfil
            : null; 
        _localFoto = null; 
        _isLoading = false;
      });
      print('Dados carregados: foto_perfil=${formando.fotoPerfil}');
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao carregar dados: $e'),
          backgroundColor: Colors.red,
        ),
      );
      print('Erro ao carregar dados: $e');
    }
  }


  Future<void> _alterarFoto() async {
    final ImagePicker picker = ImagePicker();
    final XFile? pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 50,
    );

    if (pickedFile == null) return;

    final file = File(pickedFile.path);
    final fileSize = await file.length();
    const maxSize = 5 * 1024 * 1024; // 5MB
    if (fileSize > maxSize) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Imagem muito grande. Escolha uma menor que 5MB.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _localFoto = file;
      _fotoPerfil = null; 
    });

    try {
      final uri =
          Uri.parse('https://pint-backend-t819.onrender.com/api/upload/');

      var request = http.MultipartRequest('POST', uri);

     
      request.files.add(
        await http.MultipartFile.fromPath(
          'image', // chave que o backend espera
          file.path,
          contentType: MediaType('image', 'jpeg'), // ou 'png'
        ),
      );

      // Adicionar token se necessário
      final token = await SessionManager.getToken();
      if (token != null) {
        request.headers['Authorization'] = 'Bearer $token';
      }

      final response =
          await request.send().timeout(const Duration(seconds: 60));
      final respStr = await response.stream.bytesToString();

      print('Upload status=${response.statusCode}, body=$respStr');

      if (response.statusCode == 200) {
        final jsonResp = jsonDecode(respStr);
        if (jsonResp['url'] == null) {
          throw Exception('Servidor não retornou URL da imagem');
        }

        setState(() {
          _fotoPerfil = jsonResp['url'];
          _localFoto = null;
        });

        // Atualiza o perfil com a nova foto
        await _salvarAlteracoes();

        
      } else {
        throw Exception(
            'Erro no upload: status=${response.statusCode}, body=$respStr');
      }
    } catch (e) {
      print('Erro durante o upload: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao enviar foto: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _salvarAlteracoes() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      final token = await SessionManager.getToken();
      if (token == null) throw Exception('Token não encontrado');

      final uri = Uri.parse(
          'https://pint-backend-t819.onrender.com/api/formandos/${widget.idUtilizador}/${widget.idFormando}/full');

      final payload = {
        'nome': _nomeController.text.trim(),
        'telemovel': _telemovelController.text.trim(),
        'genero': _genero ?? '',
        'foto_perfil': _fotoPerfil ?? '',
      };
      print('Enviando payload para atualizar perfil: $payload');

      final response = await http.put(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(payload),
      );

      print(
          'Resposta do perfil: status=${response.statusCode}, body=${response.body}');

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Perfil atualizado com sucesso!'),
            backgroundColor: Color(0xFF486CA4),
          ),
        );
        Navigator.pop(context, _fotoPerfil);
      } else {
        throw Exception(
            'Erro ao atualizar perfil: status=${response.statusCode}, body=${response.body}');
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao atualizar perfil: $e'),
          backgroundColor: Colors.red,
        ),
      );
      print('Erro ao atualizar perfil: $e');
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  ImageProvider<Object> _getProfileImage() {
    if (_localFoto != null) {
      print('Using local file for preview: ${_localFoto!.path}');
      return FileImage(_localFoto!);
    }
    if (_fotoPerfil != null && _fotoPerfil!.startsWith('http')) {
      print('Using network image: $_fotoPerfil');
      return NetworkImage(
          '$_fotoPerfil?_=${DateTime.now().millisecondsSinceEpoch}');
    }
    print('Using default avatar');
    return const AssetImage('assets/images/poo.png');
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Editar Perfil'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              Center(
                child: Stack(
                  children: [
                    CircleAvatar(
                      radius: 50,
                      backgroundImage: _getProfileImage(),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: InkWell(
                        onTap: _alterarFoto,
                        child: const CircleAvatar(
                          radius: 15,
                          child: Icon(Icons.camera_alt, size: 18),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              TextFormField(
                controller: _nomeController,
                decoration: const InputDecoration(labelText: 'Nome'),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'O nome é obrigatório';
                  }
                  if (!RegExp(r"^[A-Za-zÀ-ÿ\s'-]+$").hasMatch(value.trim())) {
                    return 'Nome inválido';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _telemovelController,
                decoration: const InputDecoration(labelText: 'Telemóvel'),
                keyboardType: TextInputType.phone,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Telemóvel obrigatório';
                  }
                  if (!RegExp(r'^\d{9}$').hasMatch(value.trim())) {
                    return 'Telemóvel inválido';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: _genero,
                items: _generosDisponiveis
                    .map((g) => DropdownMenuItem(value: g, child: Text(g)))
                    .toList(),
                onChanged: (v) => setState(() => _genero = v),
                decoration: const InputDecoration(labelText: 'Género'),
                validator: (v) => v == null ? 'Escolha um género' : null,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _isSaving ? null : _salvarAlteracoes,
                child: _isSaving
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Salvar Alterações'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _nomeController.dispose();
    _telemovelController.dispose();
    super.dispose();
  }
}
