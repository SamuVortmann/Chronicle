// lib/screens/home_screen.dart
//
// Fixes vs RAR version:
//  1. Album section was hardcoded static list — now loads from DB
//  2. "Ver todos" did nothing — now navigates to AlbunsScreen
//  3. Bottom nav tapping didn't navigate — replaced with proper screen routing
//  4. duplicate main() removed (main is only in main.dart)
//  5. _AlbumData helper class replaced with real Album model

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:travel/database/database_helper.dart';
import 'package:travel/screens/novo_registro_screen.dart';
import 'package:travel/screens/timeline_screen.dart';
import 'package:travel/screens/albuns_screen.dart';
import 'package:travel/screens/album_detail_screen.dart';
import 'package:travel/utils/app_constants.dart';

// ─── Root widget that owns the bottom nav shell ───────────────────────────────
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _navIndex = 0;

  // Each tab keeps its own scroll / state via AutomaticKeepAliveClientMixin
  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _pages = [
      const _HomeTab(),
      const TimelineScreen(),
      const SizedBox(), // placeholder — Map / Insights not yet implemented
      const SizedBox(),
    ];
  }

  Future<void> _openNovoRegistro() async {
    final ok = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const NovoRegistroScreen()),
    );
    if (ok == true) setState(() {}); // trigger rebuild so _HomeTab refreshes
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _navIndex, children: _pages),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: FloatingActionButton(
        onPressed: _openNovoRegistro,
        backgroundColor: kGreen,
        elevation: 4,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      bottomNavigationBar: BottomAppBar(
        color: kCard,
        elevation: 8,
        notchMargin: 6,
        shape: const CircularNotchedRectangle(),
        child: SizedBox(
          height: 56,
          child: Row(children: [
            _navItem(0, Icons.home_outlined,      'Home'),
            _navItem(1, Icons.timeline_outlined,  'Timeline'),
            const Expanded(child: SizedBox()),
            _navItem(2, Icons.map_outlined,       'Mapa'),
            _navItem(3, Icons.show_chart_outlined,'Insights'),
          ]),
        ),
      ),
    );
  }

  Widget _navItem(int idx, IconData icon, String label) {
    final active = _navIndex == idx;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _navIndex = idx),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(icon, size: 22, color: active ? kGreen : kTextTertiary),
          const SizedBox(height: 2),
          Text(label, style: TextStyle(fontSize: 10,
              color: active ? kGreen : kTextTertiary,
              fontWeight: active ? FontWeight.w600 : FontWeight.normal)),
        ]),
      ),
    );
  }
}

// ─── Home tab content ─────────────────────────────────────────────────────────
class _HomeTab extends StatefulWidget {
  const _HomeTab();
  @override
  State<_HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<_HomeTab> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  List<Registro> _registros = [];
  List<Album>    _albuns    = [];
  int    _total   = 0;
  bool   _loading = true;
  String? _erro;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    if (mounted) setState(() { _loading = true; _erro = null; });
    try {
      final r = await DatabaseHelper.instance.listarRegistros();
      final a = await DatabaseHelper.instance.listarAlbuns();
      final t = await DatabaseHelper.instance.totalRegistros();
      if (mounted) setState(() {
        _registros = r; _albuns = a; _total = t; _loading = false;
      });
    } catch (e) {
      if (mounted) setState(() { _loading = false; _erro = e.toString(); });
    }
  }

  Future<void> _goToNovoRegistro() async {
    final ok = await Navigator.push<bool>(
        context, MaterialPageRoute(builder: (_) => const NovoRegistroScreen()));
    if (ok == true) _load();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      backgroundColor: kBg,
      appBar: AppBar(
        backgroundColor: kGreen, elevation: 0,
        title: const Row(children: [
          Icon(Icons.public, color: Colors.white, size: 20),
          SizedBox(width: 6),
          Text('Chronicle', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
        ]),
        actions: [
          IconButton(icon: const Icon(Icons.notifications_outlined, color: Colors.white), onPressed: () {}),
          IconButton(icon: const Icon(Icons.settings_outlined, color: Colors.white), onPressed: () {}),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: kGreen))
          : _erro != null ? _errorView() : _content(),
    );
  }

  Widget _errorView() => Center(child: Padding(
    padding: const EdgeInsets.all(24),
    child: Column(mainAxisSize: MainAxisSize.min, children: [
      const Icon(Icons.error_outline, size: 48, color: kRed),
      const SizedBox(height: 12),
      const Text('Não foi possível carregar os dados.',
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600), textAlign: TextAlign.center),
      const SizedBox(height: 6),
      Text(_erro!, style: const TextStyle(fontSize: 12, color: kTextSecondary), textAlign: TextAlign.center),
      const SizedBox(height: 20),
      ElevatedButton.icon(onPressed: _load,
          icon: const Icon(Icons.refresh), label: const Text('Tentar novamente'),
          style: ElevatedButton.styleFrom(backgroundColor: kGreen, foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)))),
    ]),
  ));

  Widget _content() => RefreshIndicator(
    color: kGreen, onRefresh: _load,
    child: SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.only(bottom: 80),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _sectionHeader('ÁLBUNS', action: 'Ver todos',
            onAction: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const AlbunsScreen())).then((_) => _load())),
        _albumsRow(),
        const _SectionHead('ÚLTIMOS ACESSOS'),
        _recentList(),
        const _SectionHead('CONTINUAR HOJE'),
        _continueTodayCard(),
        const _SectionHead('ESTATÍSTICAS'),
        _statsCard(),
      ]),
    ),
  );

  // ── Albums ─────────────────────────────────────────────────────────────────
  Widget _albumsRow() {
    if (_albuns.isEmpty) {
      return _emptyCard(Icons.add_circle_outline, 'Criar primeiro álbum',
          onTap: () => Navigator.push(context,
              MaterialPageRoute(builder: (_) => const AlbunsScreen())).then((_) => _load()));
    }
    return SizedBox(
      height: 130,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
        itemCount: _albuns.length + 1,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (_, i) => i < _albuns.length
            ? _albumTile(_albuns[i])
            : _addAlbumTile(),
      ),
    );
  }

  Widget _albumTile(Album a) {
    final color = hexToColor(a.cor);
    final bg    = Color.alphaBlend(color.withOpacity(0.12), Colors.white);
    return GestureDetector(
      onTap: () => Navigator.push(context,
          MaterialPageRoute(builder: (_) => AlbumDetailScreen(album: a))).then((_) => _load()),
      child: SizedBox(width: 90, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(height: 78, width: 90,
            decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(12),
                border: Border.all(color: color.withOpacity(0.3))),
            child: Center(child: Icon(iconFromString(a.icone), size: 30, color: color))),
        const SizedBox(height: 6),
        Text(a.nome, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: kTextPrimary),
            maxLines: 1, overflow: TextOverflow.ellipsis),
        const Text('2026 · Você', style: TextStyle(fontSize: 10, color: kTextTertiary)),
      ])),
    );
  }

  Widget _addAlbumTile() => GestureDetector(
    onTap: () => Navigator.push(context,
        MaterialPageRoute(builder: (_) => const AlbunsScreen())).then((_) => _load()),
    child: SizedBox(width: 90, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Container(height: 78, width: 90,
          decoration: BoxDecoration(color: kCard, borderRadius: BorderRadius.circular(12),
              border: Border.all(color: kBorder)),
          child: const Center(child: Icon(Icons.add, size: 28, color: kTextTertiary))),
      const SizedBox(height: 6),
      const Text('Novo álbum', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: kTextTertiary)),
    ])),
  );

  // ── Recent ─────────────────────────────────────────────────────────────────
  Widget _recentList() {
    if (_registros.isEmpty) return _emptyCard(Icons.history, 'Nenhum registro ainda.');
    final items = _registros.take(3).toList();
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Container(
        decoration: BoxDecoration(color: kCard, borderRadius: BorderRadius.circular(14),
            border: Border.all(color: kBorder)),
        child: Column(children: items.asMap().entries.map((e) => Column(children: [
          _recentTile(e.value),
          if (e.key < items.length - 1)
            const Divider(height: 1, indent: 16, endIndent: 16, color: kBorderLight),
        ])).toList()),
      ),
    );
  }

  Widget _recentTile(Registro r) {
    final hasPhoto = r.fotos.isNotEmpty && File(r.fotos.first).existsSync();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(children: [
        Container(
          width: 42, height: 42,
          decoration: BoxDecoration(
              color: hasPhoto ? Colors.transparent : kGreenLight,
              borderRadius: BorderRadius.circular(10), border: Border.all(color: kBorder)),
          child: hasPhoto
              ? ClipRRect(borderRadius: BorderRadius.circular(10),
                  child: Image.file(File(r.fotos.first), fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const Icon(Icons.broken_image_outlined, size: 18, color: kTextTertiary)))
              : const Icon(Icons.camera_alt_outlined, size: 20, color: kGreen),
        ),
        const SizedBox(width: 10),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(r.titulo, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: kTextPrimary),
              maxLines: 1, overflow: TextOverflow.ellipsis),
          Text(r.local.isNotEmpty ? '${r.local} · ${formatDateShort(r.dataHora)}' : formatDateShort(r.dataHora),
              style: const TextStyle(fontSize: 11, color: kTextSecondary)),
        ])),
        const SizedBox(width: 6),
        Text(kMoods[r.humor.clamp(0, 4)], style: const TextStyle(fontSize: 16)),
      ]),
    );
  }

  // ── Continue today ─────────────────────────────────────────────────────────
  Widget _continueTodayCard() {
    final hoje    = DateTime.now();
    final temHoje = _registros.any((r) {
      final dt = DateTime.tryParse(r.dataHora);
      return dt != null && dt.year == hoje.year && dt.month == hoje.month && dt.day == hoje.day;
    });
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: GestureDetector(
        onTap: _goToNovoRegistro,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: kGreen, borderRadius: BorderRadius.circular(14)),
          child: Row(children: [
            Container(width: 46, height: 46,
                decoration: BoxDecoration(color: Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12)),
                child: const Icon(Icons.camera_alt_outlined, color: Colors.white, size: 24)),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(temHoje ? 'Continuar o registro de hoje' : 'Adicionar registro diário',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14)),
              const SizedBox(height: 2),
              Text(temHoje ? 'Você já tem um registro hoje 🎉' : 'Ainda não há entrada para hoje',
                  style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 11)),
            ])),
            const Icon(Icons.chevron_right, color: Colors.white70, size: 20),
          ]),
        ),
      ),
    );
  }

  // ── Stats ──────────────────────────────────────────────────────────────────
  Widget _statsCard() => Padding(
    padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
    child: Container(
      decoration: BoxDecoration(color: kCard, borderRadius: BorderRadius.circular(14),
          border: Border.all(color: kBorder)),
      child: Column(children: [
        _statRow('Registros',        '$_total',                  isFirst: true),
        _statRow('Sequência',        '${_sequencia()} dias'),
        _statRow('Álbuns',           '${_albuns.length}',        valueColor: kGreen),
        _statRow('Locais visitados', '${_locaisUnicos()}',       isLast: true),
      ]),
    ),
  );

  Widget _statRow(String label, String value,
      {bool isFirst = false, bool isLast = false, Color? valueColor}) =>
      Column(children: [
        if (!isFirst) const Divider(height: 1, indent: 16, endIndent: 16, color: kBorderLight),
        Padding(padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
            child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Text(label, style: const TextStyle(fontSize: 13, color: kTextSecondary)),
              Text(value, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600,
                  color: valueColor ?? kTextPrimary)),
            ])),
      ]);

  // ── Helpers ────────────────────────────────────────────────────────────────
  Widget _emptyCard(IconData icon, String label, {VoidCallback? onTap}) => Padding(
    padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
    child: GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: kCard, borderRadius: BorderRadius.circular(14),
            border: Border.all(color: kBorder)),
        child: Row(children: [
          Icon(icon, color: onTap != null ? kGreen : kTextTertiary),
          const SizedBox(width: 10),
          Text(label, style: TextStyle(color: onTap != null ? kGreen : kTextSecondary,
              fontWeight: onTap != null ? FontWeight.w600 : FontWeight.normal)),
        ]),
      ),
    ),
  );

  Widget _sectionHeader(String title, {String? action, VoidCallback? onAction}) => Padding(
    padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
    child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Text(title, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700,
          color: kTextTertiary, letterSpacing: 0.5)),
      if (action != null)
        GestureDetector(onTap: onAction,
            child: Text(action, style: const TextStyle(color: kGreen, fontSize: 12, fontWeight: FontWeight.w600))),
    ]),
  );

  int _sequencia() {
    if (_registros.isEmpty) return 0;
    final dias = _registros.map((r) => DateTime.tryParse(r.dataHora))
        .whereType<DateTime>().map((d) => DateTime(d.year, d.month, d.day))
        .toSet().toList()..sort((a, b) => b.compareTo(a));
    int s = 1;
    for (int i = 1; i < dias.length; i++) {
      if (dias[i-1].difference(dias[i]).inDays == 1) s++; else break;
    }
    return s;
  }

  int _locaisUnicos() => _registros
      .map((r) => r.local.trim().toLowerCase())
      .where((l) => l.isNotEmpty).toSet().length;
}

class _SectionHead extends StatelessWidget {
  final String title;
  const _SectionHead(this.title);
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
    child: Text(title, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700,
        color: kTextTertiary, letterSpacing: 0.5)),
  );
}
