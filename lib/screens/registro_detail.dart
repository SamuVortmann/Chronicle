import 'dart:io';
import 'package:flutter/material.dart';
import 'package:travel/database/database_helper.dart';
import 'package:travel/utils/app_constants.dart';
import 'package:travel/screens/novo_registro_screen.dart';

class RegistroDetailScreen extends StatefulWidget {
  final Registro registro;
  const RegistroDetailScreen({super.key, required this.registro});
  @override
  State<RegistroDetailScreen> createState() => _RegistroDetailScreenState();
}

class _RegistroDetailScreenState extends State<RegistroDetailScreen> {
  late Registro _r;
  int _photoPage = 0;

  @override
  void initState() { super.initState(); _r = widget.registro; }

  Future<void> _refresh() async {
    final updated = await DatabaseHelper.instance.buscarRegistro(_r.id!);
    if (updated != null && mounted) setState(() => _r = updated);
  }

  Future<void> _delete() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Excluir registro'),
        content: const Text('Deseja excluir este registro permanentemente?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
          TextButton(onPressed: () => Navigator.pop(context, true),
              child: const Text('Excluir', style: TextStyle(color: kRed))),
        ],
      ),
    );
    if (confirm == true) {
      await DatabaseHelper.instance.deletarRegistro(_r.id!);
      if (mounted) Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBg,
      body: CustomScrollView(slivers: [
        // ── AppBar ──
        SliverAppBar(
          pinned: true,
          backgroundColor: kGreen,
          foregroundColor: Colors.white,
          expandedHeight: _r.fotos.isNotEmpty ? 260 : 0,
          flexibleSpace: _r.fotos.isNotEmpty
              ? FlexibleSpaceBar(background: _photoCarousel())
              : null,
          title: Text(_r.titulo,
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 15),
              maxLines: 1, overflow: TextOverflow.ellipsis),
          actions: [
            IconButton(icon: const Icon(Icons.edit_outlined, color: Colors.white),
                onPressed: () async {
                  final ok = await Navigator.push<bool>(context,
                      MaterialPageRoute(builder: (_) => NovoRegistroScreen(registroParaEditar: _r)));
                  if (ok == true) _refresh();
                }),
            IconButton(icon: const Icon(Icons.delete_outline, color: Colors.white),
                onPressed: _delete),
          ],
        ),

        // ── Content ──
        SliverToBoxAdapter(child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

            // Title + mood
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Expanded(child: Text(_r.titulo,
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: kTextPrimary))),
              Column(children: [
                Text(kMoods[_r.humor.clamp(0, 4)], style: const TextStyle(fontSize: 28)),
                Text(kMoodLabels[_r.humor.clamp(0, 4)],
                    style: const TextStyle(fontSize: 10, color: kTextTertiary)),
              ]),
            ]),
            const SizedBox(height: 8),

            // Meta chips
            Wrap(spacing: 6, runSpacing: 6, children: [
              _chip(Icons.calendar_today_outlined, formatDate(_r.dataHora)),
              if (_r.local.isNotEmpty) _chip(Icons.location_on_outlined, _r.local),
              if (_r.album.isNotEmpty) _chip(Icons.photo_album_outlined, _r.album),
            ]),

            // Tags
            if (_r.tagList.isNotEmpty) ...[
              const SizedBox(height: 12),
              Wrap(spacing: 5, runSpacing: 5, children: _r.tagList.map((t) => Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: kGreenLight, borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: kGreenBorder)),
                child: Text(t, style: const TextStyle(fontSize: 12, color: kGreenDark, fontWeight: FontWeight.w500)),
              )).toList()),
            ],

            // Description
            if (_r.descricao.isNotEmpty) ...[
              const SizedBox(height: 16),
              Container(padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(color: kCard, borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: kBorder)),
                child: Text(_r.descricao,
                    style: const TextStyle(fontSize: 14, color: kTextSecondary, height: 1.6))),
            ],

            // Photo strip (if more than 1)
            if (_r.fotos.length > 1) ...[
              const SizedBox(height: 16),
              const Text('FOTOS', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700,
                  color: kTextTertiary, letterSpacing: 0.5)),
              const SizedBox(height: 8),
              SizedBox(height: 80, child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _r.fotos.length,
                separatorBuilder: (_, __) => const SizedBox(width: 6),
                itemBuilder: (_, i) {
                  final exists = File(_r.fotos[i]).existsSync();
                  return GestureDetector(
                    onTap: () => setState(() => _photoPage = i),
                    child: ClipRRect(borderRadius: BorderRadius.circular(10),
                      child: exists
                          ? Image.file(File(_r.fotos[i]), width: 80, height: 80, fit: BoxFit.cover)
                          : Container(width: 80, height: 80, color: kBg,
                              child: const Icon(Icons.broken_image_outlined, color: kTextTertiary))),
                  );
                },
              )),
            ],

            const SizedBox(height: 32),
          ]),
        )),
      ]),
    );
  }

  Widget _photoCarousel() {
    final validPhotos = _r.fotos.where((p) => File(p).existsSync()).toList();
    if (validPhotos.isEmpty) return Container(color: kGreenLight,
        child: const Center(child: Icon(Icons.camera_alt_outlined, size: 48, color: kGreen)));

    return Stack(fit: StackFit.expand, children: [
      PageView.builder(
        itemCount: validPhotos.length,
        onPageChanged: (i) => setState(() => _photoPage = i),
        itemBuilder: (_, i) => Image.file(File(validPhotos[i]), fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Container(color: kGreenLight,
                child: const Icon(Icons.broken_image_outlined, size: 40, color: kGreen))),
      ),
      if (validPhotos.length > 1)
        Positioned(bottom: 12, left: 0, right: 0,
          child: Row(mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(validPhotos.length, (i) => AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: _photoPage == i ? 18 : 6,
              height: 6, margin: const EdgeInsets.symmetric(horizontal: 3),
              decoration: BoxDecoration(
                color: _photoPage == i ? Colors.white : Colors.white54,
                borderRadius: BorderRadius.circular(3),
              ),
            ))),
        ),
    ]);
  }

  Widget _chip(IconData icon, String label) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
    decoration: BoxDecoration(color: kCard, borderRadius: BorderRadius.circular(20), border: Border.all(color: kBorder)),
    child: Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(icon, size: 13, color: kTextTertiary),
      const SizedBox(width: 5),
      Text(label, style: const TextStyle(fontSize: 12, color: kTextSecondary)),
    ]),
  );
}