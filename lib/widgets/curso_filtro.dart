import 'package:flutter/material.dart';

class CursoFiltroWidget extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onFiltroTipo;
  final String tipo;
  final VoidCallback onFiltroCategoria;
  final VoidCallback onFiltroArea;
  final VoidCallback onFiltroTopico;
  final String categoria;
  final String area;
  final String topico;
  final Function(String) onPesquisaChanged;

  const CursoFiltroWidget({
    Key? key,
    required this.controller,
    required this.onFiltroTipo,
    required this.tipo,
    required this.onFiltroCategoria,
    required this.onFiltroArea,
    required this.onFiltroTopico,
    required this.categoria,
    required this.area,
    required this.topico,
    required this.onPesquisaChanged,
  }) : super(key: key);

  Widget filtroBotao(String texto, VoidCallback onPressed) {
    return ElevatedButton(
      onPressed: onPressed,
      child: Text(texto, style: const TextStyle(fontSize: 13)),
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        backgroundColor: Colors.grey.shade200,
        foregroundColor: Colors.black,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: controller,
                onChanged: onPesquisaChanged,
                decoration: InputDecoration(
                  hintText: 'Pesquisar curso...',
                  prefixIcon: const Icon(Icons.search),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            ElevatedButton.icon(
              onPressed: onFiltroTipo,
              icon: const Icon(Icons.filter_alt),
              label: Text(tipo),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                elevation: 2,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              filtroBotao('Categoria: $categoria', onFiltroCategoria),
              const SizedBox(width: 8),
              filtroBotao('Área: $area', onFiltroArea),
              const SizedBox(width: 8),
              filtroBotao('Tópico: $topico', onFiltroTopico),
            ],
          ),
        ),
      ],
    );
  }
}
