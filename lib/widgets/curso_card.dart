import 'package:flutter/material.dart';
import '../models/curso.dart';

class CursoCard extends StatelessWidget {
  final Curso curso;
  final VoidCallback onTap;

  const CursoCard({
    Key? key,
    required this.curso,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 3,
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Imagem ou ícone school como default
            ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
              child: (curso.tumbnail != null && curso.tumbnail!.isNotEmpty)
                  ? Image.network(
                      'http://192.168.1.144:3000/${curso.tumbnail!.replaceFirst(RegExp(r'^/'), '')}',
                      height: 95,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        height: 95,
                        color: Colors.grey[200],
                        child: const Center(
                          child: Icon(Icons.school, size: 48, color: Color(0xFF295C99)),
                        ),
                      ),
                    )
                  : Container(
                      height: 95,
                      width: double.infinity,
                      color: Colors.grey[200],
                      child: const Center(
                        child: Icon(Icons.school, size: 48, color: Color(0xFF295C99)),
                      ),
                    ),
            ),
            // Conteúdo do card com menos espaçamento
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 6, 8, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    curso.titulo,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    curso.id_formador.toString(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[700],
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: List.generate(5, (index) {
                      return Icon(
                        index < (curso.avaliacao ?? 0).toInt() ? Icons.star : Icons.star_border,
                        size: 16,
                        color: Colors.amber,
                      );
                    }),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
