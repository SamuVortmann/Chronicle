// lib/screens/home_screen.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:travel/database/database_helper.dart';
import 'package:travel/screens/albuns_screen.dart';
import 'package:travel/screens/album_detail_screen.dart';
import 'package:travel/screens/novo_registro_screen.dart';

const _green     = Color(0xFF2E9E50);
const _greenLight = Color(0xFFE6F4EC);
const _bg        = Color(0xFFF2F2F7);
const _card      = Color(0xFFFFFFFF);
const _border    = Color(0xFFE5E5EA);
const _t1        = Color(0xFF1C1C1E);
const _t2        = Color(0xFF6C6C70);
const _t3        = Color(0xFFAEAEB2);

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Album>    _albuns    = [];
  List<Registro> _recentes  = [];
  bool           _loading   = true;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final a = await DatabaseHelper.instance.listarAlbuns();
      final r = await DatabaseHelper.instance.listarRegistros();
      if (mounted) setState(() {
        _albuns   = a;
        _recentes = r.take(5).toList();
        _loading  = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _go(Widget page) {
    Future.microtask(() async {
      if (!mounted) return;
      await Navigator.push(context, MaterialPageRoute(builder: (_) => page));
      if (mounted) _load();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _green,
        elevation: 0,
        title: const Text('Chronicle',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 18)),
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: Colors.white, size: 28),
            tooltip: 'Novo momento',
            onPressed: () => _go(const NovoRegistroScreen()),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: _green))
          : RefreshIndicator(
              color: _green,
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 40),
                children: [
                  // ── Albums ──────────────────────────────────────────────
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Álbuns',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: _t1)),
                      GestureDetector(
                        onTap: () => _go(const AlbunsScreen()),
                        child: const Text('Gerenciar',
                            style: TextStyle(color: _green, fontSize: 13, fontWeight: FontWeight.w600)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (_albuns.isEmpty)
                    _emptyCard(
                      'Nenhum álbum ainda',
                      'Crie um álbum para começar a salvar seus momentos.',
                      icon: Icons.photo_album_outlined,
                      onTap: () => _go(const AlbunsScreen()),
                    )
                  else
                    SizedBox(
                      height: 110,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: _albuns.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 10),
                        itemBuilder: (_, i) => _AlbumChip(
                          album: _albuns[i],
                          onTap: () => _go(AlbumDetailScreen(album: _albuns[i])),
                        ),
                      ),
                    ),

                  const SizedBox(height: 28),

                  // ── Recent moments ───────────────────────────────────────
                  const Text('Momentos recentes',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: _t1)),
                  const SizedBox(height: 12),
                  if (_recentes.isEmpty)
                    _emptyCard(
                      'Nenhum momento ainda',
                      'Toque no + para registrar seu primeiro momento.',
                      icon: Icons.camera_alt_outlined,
                      onTap: () => _go(const NovoRegistroScreen()),
                    )
                  else
                    ...(_recentes.map((r) => _MomentTile(
                      registro: r,
                      onTap: () => _go(AlbumDetailScreen(
                        album: Album(
                          id: r.albumId,
                          nome: r.album.isNotEmpty ? r.album : 'Sem álbum',
                          criadoEm: r.dataHora,
                        ),
                      )),
                    ))),
                ],
              ),
            ),
    );
  }

  Widget _emptyCard(String title, String sub,
      {required IconData icon, VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: _card,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _border),
        ),
        child: Row(children: [
          Icon(icon, color: _green, size: 32),
          const SizedBox(width: 14),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: _t1)),
            const SizedBox(height: 3),
            Text(sub, style: const TextStyle(fontSize: 12, color: _t2)),
          ])),
          const Icon(Icons.chevron_right, color: _t3),
        ]),
      ),
    );
  }
}

// ── Small album chip ──────────────────────────────────────────────────────────
class _AlbumChip extends StatelessWidget {
  final Album album;
  final VoidCallback onTap;
  const _AlbumChip({required this.album, required this.onTap});

  static const _icons = <String, IconData>{
    'snowflake': Icons.ac_unit,
    'wb_sunny': Icons.wb_sunny_outlined,
    'eco': Icons.eco_outlined,
    'local_florist': Icons.local_florist_outlined,
    'flight': Icons.flight_outlined,
    'restaurant': Icons.restaurant_outlined,
    'favorite': Icons.favorite_outline,
    'camera': Icons.camera_alt_outlined,
    'photo_album': Icons.photo_album_outlined,
  };

  Color get _color {
    try {
      return Color(int.parse('FF${album.cor.replaceAll('#', '')}', radix: 16));
    } catch (_) { return _green; }
  }

  @override
  Widget build(BuildContext context) {
    final color = _color;
    final bg = Color.alphaBlend(color.withOpacity(0.13), Colors.white);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 90,
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(_icons[album.icone] ?? Icons.photo_album_outlined, color: color, size: 28),
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: Text(album.nome,
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: _t1),
                maxLines: 2,
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis),
          ),
        ]),
      ),
    );
  }
}

// ── Recent moment tile ────────────────────────────────────────────────────────
class _MomentTile extends StatelessWidget {
  final Registro registro;
  final VoidCallback onTap;
  const _MomentTile({required this.registro, required this.onTap});

  String _fmt(String iso) {
    final dt = DateTime.tryParse(iso);
    if (dt == null) return '';
    const m = ['Jan','Fev','Mar','Abr','Mai','Jun','Jul','Ago','Set','Out','Nov','Dez'];
    return '${dt.day} ${m[dt.month-1]} ${dt.year}';
  }

  @override
  Widget build(BuildContext context) {
    final r        = registro;
    final hasPhoto = r.fotos.isNotEmpty && File(r.fotos.first).existsSync();
    const moods    = ['😊','😄','😐','😢','😍'];

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: _card,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _border),
        ),
        child: Row(children: [
          // Photo or placeholder
          ClipRRect(
            borderRadius: const BorderRadius.horizontal(left: Radius.circular(13)),
            child: SizedBox(
              width: 64, height: 64,
              child: hasPhoto
                  ? Image.file(File(r.fotos.first), fit: BoxFit.cover)
                  : Container(color: _greenLight,
                      child: const Icon(Icons.camera_alt_outlined, color: _green, size: 26)),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(r.titulo,
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: _t1),
                  maxLines: 1, overflow: TextOverflow.ellipsis),
              const SizedBox(height: 2),
              Text(
                [if (r.album.isNotEmpty) r.album, _fmt(r.dataHora)]
                    .where((s) => s.isNotEmpty).join(' · '),
                style: const TextStyle(fontSize: 12, color: _t2),
              ),
            ]),
          )),
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Text(moods[r.humor.clamp(0, 4)],
                style: const TextStyle(fontSize: 18)),
          ),
        ]),
      ),
    );
  }
}
