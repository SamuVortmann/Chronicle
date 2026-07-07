import 'dart:io';
import 'package:flutter/material.dart';
import 'package:travel/database/database_helper.dart';
import 'package:travel/utils/app_constants.dart';
import 'package:travel/screens/registro_detail_screen.dart';

class TimelineScreen extends StatefulWidget {
  const TimelineScreen({super.key});
  @override
  State<TimelineScreen> createState() => _TimelineScreenState();
}

class _TimelineScreenState extends State<TimelineScreen> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  List<Registro> _all      = [];
  List<Registro> _filtered = [];
  List<String>   _albuns   = [];
  bool   _loading = true;
  String _search  = '';
  String? _tagFilter;
  String? _albumFilter;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final r = await DatabaseHelper.instance.listarRegistros();
      final a = (await DatabaseHelper.instance.listarAlbuns()) as List<String>;
      if (mounted) setState(() { _all = r; _albuns = a; _loading = false; _applyFilters(); });
    } catch (e) {
      if (mounted) { setState(() => _loading = false); showError(context, e.toString()); }
    }
  }

  void _applyFilters() {
    setState(() {
      _filtered = _all.where((r) {
        final matchSearch = _search.isEmpty ||
            r.titulo.toLowerCase().contains(_search.toLowerCase()) ||
            r.local.toLowerCase().contains(_search.toLowerCase()) ||
            r.descricao.toLowerCase().contains(_search.toLowerCase());
        final matchTag   = _tagFilter == null || r.tagList.contains(_tagFilter);
        final matchAlbum = _albumFilter == null || r.album == _albumFilter;
        return matchSearch && matchTag && matchAlbum;
      }).toList();
    });
  }

  // Group by date
  Map<String, List<Registro>> get _grouped {
    final map = <String, List<Registro>>{};
    for (final r in _filtered) {
      final key = _dayKey(r.dataHora);
      map.putIfAbsent(key, () => []).add(r);
    }
    return map;
  }

  String _dayKey(String iso) {
    final dt = DateTime.tryParse(iso);
    if (dt == null) return '';
    const dias = ['Dom','Seg','Ter','Qua','Qui','Sex','Sáb'];
    return '${dias[dt.weekday % 7]}, ${dt.day} ${['Jan','Fev','Mar','Abr','Mai','Jun','Jul','Ago','Set','Out','Nov','Dez'][dt.month-1]} ${dt.year}';
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final grouped = _grouped;
    final dateKeys = grouped.keys.toList();

    return Scaffold(
      backgroundColor: kBg,
      appBar: AppBar(
        backgroundColor: kGreen, elevation: 0, automaticallyImplyLeading: false,
        title: const Text('Timeline', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
        actions: [
          IconButton(icon: const Icon(Icons.search, color: Colors.white), onPressed: _showSearch),
          IconButton(icon: const Icon(Icons.tune, color: Colors.white), onPressed: _showFilters),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: kGreen))
          : Column(children: [
              // Active filters bar
              if (_tagFilter != null || _albumFilter != null || _search.isNotEmpty)
                _filtersBar(),
              Expanded(child: _filtered.isEmpty
                  ? EmptyState(icon: Icons.timeline, title: 'Nenhum registro encontrado',
                      subtitle: _all.isEmpty ? 'Adicione seu primeiro registro.' : 'Tente outros filtros.')
                  : RefreshIndicator(
                      color: kGreen, onRefresh: _load,
                      child: ListView.builder(
                        padding: const EdgeInsets.fromLTRB(12, 8, 12, 80),
                        itemCount: dateKeys.length,
                        itemBuilder: (_, i) {
                          final key      = dateKeys[i];
                          final dayItems = grouped[key]!;
                          return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Padding(padding: const EdgeInsets.symmetric(vertical: 8),
                                child: Text(key, style: const TextStyle(
                                    fontSize: 11, fontWeight: FontWeight.w700,
                                    color: kTextTertiary, letterSpacing: 0.4))),
                            ...dayItems.map((r) => _entryCard(r)),
                          ]);
                        },
                      ),
                    )),
            ]),
    );
  }

  Widget _filtersBar() => Container(
    color: kCard, padding: const EdgeInsets.fromLTRB(12, 6, 12, 6),
    child: Row(children: [
      const Icon(Icons.filter_list, size: 16, color: kTextTertiary),
      const SizedBox(width: 6),
      Expanded(child: Wrap(spacing: 6, children: [
        if (_search.isNotEmpty) _filterChip('Busca: $_search', () { _search = ''; _applyFilters(); }),
        if (_tagFilter != null) _filterChip(_tagFilter!, () { _tagFilter = null; _applyFilters(); }),
        if (_albumFilter != null) _filterChip(_albumFilter!, () { _albumFilter = null; _applyFilters(); }),
      ])),
      GestureDetector(
        onTap: () { _search = ''; _tagFilter = null; _albumFilter = null; _applyFilters(); },
        child: const Text('Limpar', style: TextStyle(color: kGreen, fontSize: 12, fontWeight: FontWeight.w600)),
      ),
    ]),
  );

  Widget _filterChip(String label, VoidCallback onRemove) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    decoration: BoxDecoration(color: kGreenLight, borderRadius: BorderRadius.circular(20)),
    child: Row(mainAxisSize: MainAxisSize.min, children: [
      Text(label, style: const TextStyle(fontSize: 11, color: kGreenDark, fontWeight: FontWeight.w500)),
      const SizedBox(width: 4),
      GestureDetector(onTap: onRemove,
          child: const Icon(Icons.close, size: 13, color: kGreenDark)),
    ]),
  );

  Widget _entryCard(Registro r) {
    final temFoto = r.fotos.isNotEmpty && File(r.fotos.first).existsSync();
    final dt      = DateTime.tryParse(r.dataHora);
    final hora    = dt != null ? '${dt.hour.toString().padLeft(2,'0')}:${dt.minute.toString().padLeft(2,'0')}' : '';

    return GestureDetector(
      onTap: () => Navigator.push(context,
          MaterialPageRoute(builder: (_) => RegistroDetailScreen(registro: r))).then((_) => _load()),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(color: kCard, borderRadius: BorderRadius.circular(14), border: Border.all(color: kBorder)),
        child: Row(children: [
          Container(
            width: 68, height: 68,
            decoration: BoxDecoration(color: temFoto ? Colors.transparent : kGreenLight,
                borderRadius: const BorderRadius.horizontal(left: Radius.circular(13)),
                border: const Border(right: BorderSide(color: kBorderLight))),
            child: temFoto
                ? ClipRRect(borderRadius: const BorderRadius.horizontal(left: Radius.circular(13)),
                    child: Image.file(File(r.fotos.first), fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const Icon(Icons.broken_image_outlined, color: kTextTertiary, size: 24)))
                : const Icon(Icons.camera_alt_outlined, size: 26, color: kGreen),
          ),
          Expanded(child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Expanded(child: Text(r.titulo, style: const TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w600, color: kTextPrimary),
                    maxLines: 1, overflow: TextOverflow.ellipsis)),
                Text(hora, style: const TextStyle(fontSize: 10, color: kTextTertiary)),
              ]),
              const SizedBox(height: 2),
              if (r.local.isNotEmpty) Row(children: [
                const Icon(Icons.location_on_outlined, size: 11, color: kTextTertiary),
                const SizedBox(width: 3),
                Text(r.local, style: const TextStyle(fontSize: 11, color: kTextSecondary),
                    maxLines: 1, overflow: TextOverflow.ellipsis),
              ]),
              if (r.descricao.isNotEmpty) ...[
                const SizedBox(height: 2),
                Text(r.descricao, style: const TextStyle(fontSize: 11, color: kTextSecondary),
                    maxLines: 1, overflow: TextOverflow.ellipsis),
              ],
              if (r.tagList.isNotEmpty) ...[
                const SizedBox(height: 5),
                Wrap(spacing: 4, children: r.tagList.take(3).map((t) => Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
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

  void _showSearch() async {
    final result = await showDialog<String>(
      context: context,
      builder: (_) => _SearchDialog(initial: _search),
    );
    if (result != null) { _search = result; _applyFilters(); }
  }

  void _showFilters() {
    showModalBottomSheet(
      context: context, backgroundColor: kCard,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => _FilterSheet(
        albuns: _albuns,
        allTags: _all.expand((r) => r.tagList).toSet().toList(),
        selectedTag: _tagFilter,
        selectedAlbum: _albumFilter,
        onApply: (tag, album) {
          setState(() { _tagFilter = tag; _albumFilter = album; });
          _applyFilters();
        },
      ),
    );
  }
}

// ── Search dialog ─────────────────────────────────────────────────────────────
class _SearchDialog extends StatefulWidget {
  final String initial;
  const _SearchDialog({required this.initial});
  @override
  State<_SearchDialog> createState() => _SearchDialogState();
}
class _SearchDialogState extends State<_SearchDialog> {
  late final TextEditingController _ctrl;
  @override
  void initState() { super.initState(); _ctrl = TextEditingController(text: widget.initial); }
  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('Buscar registros'),
    content: TextField(controller: _ctrl, autofocus: true,
        decoration: const InputDecoration(hintText: 'Título, local ou descrição...',
            prefixIcon: Icon(Icons.search, color: kGreen))),
    actions: [
      TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
      ElevatedButton(
        onPressed: () => Navigator.pop(context, _ctrl.text.trim()),
        style: ElevatedButton.styleFrom(backgroundColor: kGreen, foregroundColor: Colors.white),
        child: const Text('Buscar'),
      ),
    ],
  );
}

// ── Filter bottom sheet ───────────────────────────────────────────────────────
class _FilterSheet extends StatefulWidget {
  final List<String>  albuns;
  final List<String>  allTags;
  final String?       selectedTag;
  final String?       selectedAlbum;
  final void Function(String? tag, String? album) onApply;
  const _FilterSheet({required this.albuns, required this.allTags,
      required this.selectedTag, required this.selectedAlbum, required this.onApply});
  @override
  State<_FilterSheet> createState() => _FilterSheetState();
}
class _FilterSheetState extends State<_FilterSheet> {
  String? _tag;
  String? _album;
  @override
  void initState() { super.initState(); _tag = widget.selectedTag; _album = widget.selectedAlbum; }
  @override
  Widget build(BuildContext context) => SafeArea(child: Padding(
    padding: const EdgeInsets.all(16),
    child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
      Center(child: Container(width: 36, height: 4, decoration: BoxDecoration(color: kBorder, borderRadius: BorderRadius.circular(2)))),
      const SizedBox(height: 14),
      const Text('Filtrar por álbum', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: kTextTertiary, letterSpacing: 0.4)),
      const SizedBox(height: 8),
      Wrap(spacing: 6, runSpacing: 6, children: [
        _chip('Todos', _album == null, () => setState(() => _album = null)),
        ...widget.albuns.map((a) => _chip(a, _album == a, () => setState(() => _album = a))),
      ]),
      if (widget.allTags.isNotEmpty) ...[
        const SizedBox(height: 14),
        const Text('Filtrar por tag', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: kTextTertiary, letterSpacing: 0.4)),
        const SizedBox(height: 8),
        Wrap(spacing: 6, runSpacing: 6, children: [
          _chip('Todas', _tag == null, () => setState(() => _tag = null)),
          ...widget.allTags.map((t) => _chip(t, _tag == t, () => setState(() => _tag = t))),
        ]),
      ],
      const SizedBox(height: 16),
      SizedBox(width: double.infinity, child: ElevatedButton(
        onPressed: () { Navigator.pop(context); widget.onApply(_tag, _album); },
        style: ElevatedButton.styleFrom(backgroundColor: kGreen, foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
        child: const Text('Aplicar filtros'),
      )),
    ]),
  ));

  Widget _chip(String label, bool sel, VoidCallback onTap) => GestureDetector(
    onTap: onTap,
    child: AnimatedContainer(duration: const Duration(milliseconds: 120),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: sel ? kGreenLight : kBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: sel ? kGreenBorder : kBorder),
      ),
      child: Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500,
          color: sel ? kGreenDark : kTextSecondary))),
  );
}
