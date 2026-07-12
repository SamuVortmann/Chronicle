// lib/screens/registro_detail_screen.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:travel/database/database_helper.dart';

const _green = Color(0xFF2E9E50);
const _bg    = Color(0xFFF2F2F7);
const _card  = Color(0xFFFFFFFF);
const _border= Color(0xFFE5E5EA);
const _t1    = Color(0xFF1C1C1E);
const _t2    = Color(0xFF6C6C70);
const _t3    = Color(0xFFAEAEB2);
const _red   = Color(0xFFFF3B30);
const _moods = ['😊','😄','😐','😢','😍'];

class RegistroDetailScreen extends StatelessWidget {
  final Registro registro;
  const RegistroDetailScreen({super.key, required this.registro});

  String _fmt(String iso) {
    final dt = DateTime.tryParse(iso);
    if (dt == null) return '';
    const m = ['Jan','Fev','Mar','Abr','Mai','Jun','Jul','Ago','Set','Out','Nov','Dez'];
    final h   = dt.hour.toString().padLeft(2,'0');
    final min = dt.minute.toString().padLeft(2,'0');
    return '${dt.day} ${m[dt.month-1]} ${dt.year} · $h:$min';
  }

  @override
  Widget build(BuildContext context) {
    final r        = registro;
    final photos   = r.fotos.where((p) => File(p).existsSync()).toList();

    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _green,
        foregroundColor: Colors.white,
        elevation: 0,
        title: Text(r.titulo,
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
            maxLines: 1, overflow: TextOverflow.ellipsis),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.white),
            onPressed: () => _confirmDelete(context),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
        children: [
          // Photos
          if (photos.isNotEmpty) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: Image.file(File(photos.first),
                  width: double.infinity, height: 220, fit: BoxFit.cover),
            ),
            if (photos.length > 1) ...[
              const SizedBox(height: 8),
              SizedBox(
                height: 72,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: photos.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 6),
                  itemBuilder: (_, i) => ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.file(File(photos[i]),
                        width: 72, height: 72, fit: BoxFit.cover),
                  ),
                ),
              ),
            ],
            const SizedBox(height: 16),
          ],

          // Title + mood
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Expanded(child: Text(r.titulo,
                style: const TextStyle(fontSize: 22,
                    fontWeight: FontWeight.w700, color: _t1))),
            Text(_moods[r.humor.clamp(0, 4)],
                style: const TextStyle(fontSize: 28)),
          ]),
          const SizedBox(height: 8),

          // Meta
          _chip(Icons.calendar_today_outlined, _fmt(r.dataHora)),
          if (r.local.isNotEmpty) _chip(Icons.location_on_outlined, r.local),
          if (r.album.isNotEmpty) _chip(Icons.photo_album_outlined, r.album),
          const SizedBox(height: 12),

          // Description
          if (r.descricao.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(color: _card,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: _border)),
              child: Text(r.descricao,
                  style: const TextStyle(fontSize: 15, color: _t2, height: 1.6)),
            ),
        ],
      ),
    );
  }

  Widget _chip(IconData icon, String label) => Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Row(children: [
      Icon(icon, size: 15, color: _t3),
      const SizedBox(width: 6),
      Text(label, style: const TextStyle(fontSize: 13, color: _t2)),
    ]),
  );

  void _confirmDelete(BuildContext context) {
    Future.microtask(() async {
      if (!context.mounted) return;
      final ok = await showDialog<bool>(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Excluir momento'),
          content: const Text('Deseja excluir este momento permanentemente?'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancelar')),
            TextButton(onPressed: () => Navigator.pop(context, true),
                child: const Text('Excluir',
                    style: TextStyle(color: _red))),
          ],
        ),
      );
      if (ok == true) {
        await DatabaseHelper.instance.deletarRegistro(registro.id!);
        if (context.mounted) Navigator.pop(context, true);
      }
    });
  }
}
