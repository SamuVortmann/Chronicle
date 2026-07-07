import 'dart:io';
import 'package:flutter/material.dart';
import 'package:travel/database/database_helper.dart';
import 'package:travel/utils/app_constants.dart';
import 'package:travel/screens/novo_registro_screen.dart';
import 'package:travel/screens/registro_detail_screen.dart';

class AlbumDetailScreen extends StatefulWidget {
  final Album album;
  const AlbumDetailScreen({super.key, required this.album});
  @override
  State<AlbumDetailScreen> createState() => _AlbumDetailScreenState();
}

class _AlbumDetailScreenState extends State<AlbumDetailScreen> {
  List<Registro> _registros = [];
  bool _loading = true;
  late Album _album;

  @override
  void initState() { super.initState(); _album = widget.album; _load(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final r = await DatabaseHelper.instance.listarRegistrosPorAlbum(_album.id!);
      if (mounted) setState(() { _registros = r; _loading = false; });
    } catch (e) {
      if (mounted) { setState(() => _loading = false); showError(context, e.toString()); }
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = hexToColor(_album.cor);
    final light = Color.alphaBlend(color.withOpacity(0.12), Colors.white);

    return Scaffold(
      backgroundColor: kBg,
      body: CustomScrollView(slivers: [
        // ── SliverAppBar with album color ──
        SliverAppBar(
          expandedHeight: 160,
          pinned: true,
          backgroundColor: color,
          foregroundColor: Colors.white,
          actions: [
            IconButton(
              icon: const Icon(Icons.add, color: Colors.white),
              onPressed: () async {
                final ok = await Navigator.push<bool>(context,
                    MaterialPageRoute(builder: (_) => const NovoRegistroScreen()));
                if (ok == true) _load();
              },
            ),
          ],
          flexibleSpace: FlexibleSpaceBar(
            background: Container(
              color: light,
              child: Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                const SizedBox(height: 40),
                Icon(iconFromString(_album.icone), size: 52, color: color),
                const SizedBox(height: 8),
                Text(_album.nome, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: kTextPrimary)),
                if (_album.descricao.isNotEmpty)
                  Padding(padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Text(_album.descricao, style: const TextStyle(fontSize: 12, color: kTextSecondary),
                          textAlign: TextAlign.center, maxLines: 2, overflow: TextOverflow.ellipsis)),
              ])),
            ),
            title: Text(_album.nome, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 16)),
            titlePadding: const EdgeInsets.only(left: 56, bottom: 14),
          ),
        ),

        // ── Stats bar ──
        SliverToBoxAdapter(child: Container(
          color: kCard,
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
            _statItem('${_registros.length}', 'Registros'),
            _divider(),
            _statItem('${_registros.where((r) => r.fotos.isNotEmpty).length}', 'Com fotos'),
            _divider(),
            _statItem(_registros.isNotEmpty ? formatDateShort(_registros.last.dataHora) : '--', 'Primeiro'),
          ]),
        )),
        const SliverToBoxAdapter(child: SizedBox(height: 8)),

        // ── Entries ──
        _loading
            ? const SliverFillRemaining(child: Center(child: CircularProgressIndicator(color: kGreen)))
            : _registros.isEmpty
                ? SliverFillRemaining(child: EmptyState(
                    icon: Icons.camera_alt_outlined,
                    title: 'Álbum vazio',
                    subtitle: 'Adicione um registro e selecione este álbum.',
                    actionLabel: 'Adicionar registro',
                    onAction: () async {
                      final ok = await Navigator.push<bool>(context,
                          MaterialPageRoute(builder: (_) => const NovoRegistroScreen()));
                      if (ok == true) _load();
                    },
                  ))
                : SliverPadding(
                    padding: const EdgeInsets.fromLTRB(12, 0, 12, 80),
                    sliver: SliverList(delegate: SliverChildBuilderDelegate(
                      (_, i) => _registroCard(_registros[i]),
                      childCount: _registros.length,
                    )),
                  ),
      ]),
    );
  }

  Widget _statItem(String value, String label) => Column(children: [
    Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: kTextPrimary)),
    const SizedBox(height: 2),
    Text(label, style: const TextStyle(fontSize: 11, color: kTextTertiary)),
  ]);

  Widget _divider() => Container(height: 32, width: 1, color: kBorder);

  Widget _registroCard(Registro r) {
    final temFoto = r.fotos.isNotEmpty && File(r.fotos.first).existsSync();
    return GestureDetector(
      onTap: () => Navigator.push(context,
          MaterialPageRoute(builder: (_) => RegistroDetailScreen(registro: r))).then((_) => _load()),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(color: kCard, borderRadius: BorderRadius.circular(14), border: Border.all(color: kBorder)),
        child: Row(children: [
          // Foto ou placeholder
          Container(
            width: 72, height: 72,
            decoration: BoxDecoration(
              color: temFoto ? Colors.transparent : kGreenLight,
              borderRadius: const BorderRadius.horizontal(left: Radius.circular(13)),
              border: const Border(right: BorderSide(color: kBorderLight)),
            ),
            child: temFoto
                ? ClipRRect(borderRadius: const BorderRadius.horizontal(left: Radius.circular(13)),
                    child: Image.file(File(r.fotos.first), fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const Icon(Icons.broken_image_outlined, color: kTextTertiary)))
                : const Icon(Icons.camera_alt_outlined, size: 28, color: kGreen),
          ),
          Expanded(child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Expanded(child: Text(r.titulo,
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: kTextPrimary),
                    maxLines: 1, overflow: TextOverflow.ellipsis)),
                Text(kMoods[r.humor.clamp(0, 4)], style: const TextStyle(fontSize: 15)),
              ]),
              const SizedBox(height: 3),
              if (r.local.isNotEmpty) Row(children: [
                const Icon(Icons.location_on_outlined, size: 12, color: kTextTertiary),
                const SizedBox(width: 3),
                Text(r.local, style: const TextStyle(fontSize: 11, color: kTextSecondary),
                    maxLines: 1, overflow: TextOverflow.ellipsis),
              ]),
              const SizedBox(height: 3),
              Text(formatDate(r.dataHora), style: const TextStyle(fontSize: 11, color: kTextTertiary)),
              if (r.tagList.isNotEmpty) ...[
                const SizedBox(height: 5),
                Wrap(spacing: 4, children: r.tagList.take(3).map((t) => Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(color: kGreenLight, borderRadius: BorderRadius.circular(20)),
                  child: Text(t, style: const TextStyle(fontSize: 10, color: kGreenDark, fontWeight: FontWeight.w500)),
                )).toList()),
              ],
            ]),
          )),
        ]),
      ),
    );
  }
}