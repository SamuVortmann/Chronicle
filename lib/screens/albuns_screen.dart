// lib/screens/albuns_screen.dart
// Manage albums: list, create, edit, delete

import 'package:flutter/material.dart';
import 'package:travel/database/database_helper.dart';
import 'package:travel/utils/app_constants.dart';
import 'package:travel/screens/album_detail_screen.dart';

class AlbunsScreen extends StatefulWidget {
  const AlbunsScreen({super.key});
  @override
  State<AlbunsScreen> createState() => _AlbunsScreenState();
}

class _AlbunsScreenState extends State<AlbunsScreen> {
  List<Album> _albuns = [];
  bool _loading = true;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final a = await DatabaseHelper.instance.listarAlbuns();
      if (mounted) setState(() { _albuns = a; _loading = false; });
    } catch (e) {
      if (mounted) { setState(() => _loading = false); showError(context, e.toString()); }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBg,
      appBar: AppBar(
        backgroundColor: kGreen, elevation: 0, foregroundColor: Colors.white,
        title: const Text('Álbuns', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
        actions: [
          IconButton(icon: const Icon(Icons.add, color: Colors.white),
              onPressed: () => _showAlbumForm(context)),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: kGreen))
          : _albuns.isEmpty
              ? EmptyState(
                  icon: Icons.photo_album_outlined,
                  title: 'Nenhum álbum ainda',
                  subtitle: 'Crie álbuns para organizar seus registros por estação, viagem ou tema.',
                  actionLabel: 'Criar álbum',
                  onAction: () => _showAlbumForm(context),
                )
              : RefreshIndicator(
                  color: kGreen,
                  onRefresh: _load,
                  child: GridView.builder(
                    padding: const EdgeInsets.all(16),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2, crossAxisSpacing: 12, mainAxisSpacing: 12, childAspectRatio: 0.85),
                    itemCount: _albuns.length,
                    itemBuilder: (_, i) => _albumGridCard(_albuns[i]),
                  ),
                ),
    );
  }

  Widget _albumGridCard(Album a) {
    final color = hexToColor(a.cor);
    final light = Color.alphaBlend(color.withOpacity(0.12), Colors.white);
    return GestureDetector(
      onTap: () => Navigator.push(context,
          MaterialPageRoute(builder: (_) => AlbumDetailScreen(album: a))).then((_) => _load()),
      child: Container(
        decoration: BoxDecoration(color: kCard, borderRadius: BorderRadius.circular(16),
            border: Border.all(color: kBorder),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2))]),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // Thumbnail area
          Expanded(
            child: Container(
              decoration: BoxDecoration(color: light,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(15))),
              child: Center(child: Icon(iconFromString(a.icone), size: 44, color: color)),
            ),
          ),
          // Info
          Padding(
            padding: const EdgeInsets.all(10),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Expanded(child: Text(a.nome,
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: kTextPrimary),
                    maxLines: 1, overflow: TextOverflow.ellipsis)),
                GestureDetector(
                  onTap: () => _showOptions(a),
                  child: const Icon(Icons.more_horiz, size: 18, color: kTextTertiary),
                ),
              ]),
              const SizedBox(height: 2),
              FutureBuilder<int>(
                future: DatabaseHelper.instance.totalRegistrosPorAlbum(a.id!),
                builder: (_, snap) => Text(
                  snap.hasData ? '${snap.data} registros' : '...',
                  style: const TextStyle(fontSize: 11, color: kTextTertiary),
                ),
              ),
            ]),
          ),
        ]),
      ),
    );
  }

  void _showOptions(Album a) {
    showModalBottomSheet(
      context: context, backgroundColor: kCard,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => SafeArea(child: Column(mainAxisSize: MainAxisSize.min, children: [
        const SizedBox(height: 8),
        Container(width: 36, height: 4, decoration: BoxDecoration(color: kBorder, borderRadius: BorderRadius.circular(2))),
        const SizedBox(height: 8),
        ListTile(leading: const Icon(Icons.edit_outlined, color: kGreen),
            title: const Text('Editar álbum'),
            onTap: () { Navigator.pop(context); _showAlbumForm(context, album: a); }),
        ListTile(leading: const Icon(Icons.delete_outline, color: kRed),
            title: const Text('Excluir álbum', style: TextStyle(color: kRed)),
            onTap: () { Navigator.pop(context); _confirmDelete(a); }),
        const SizedBox(height: 8),
      ])),
    );
  }

  Future<void> _confirmDelete(Album a) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Excluir álbum'),
        content: Text('Deseja excluir "${a.nome}"? Os registros não serão excluídos.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
          TextButton(onPressed: () => Navigator.pop(context, true),
              child: const Text('Excluir', style: TextStyle(color: kRed))),
        ],
      ),
    );
    if (confirm == true) {
      await DatabaseHelper.instance.deletarAlbum(a.id!);
      _load();
    }
  }

  void _showAlbumForm(BuildContext context, {Album? album}) {
    showModalBottomSheet(
      context: context, isScrollControlled: true, backgroundColor: kCard,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => _AlbumFormSheet(album: album, onSaved: _load),
    );
  }
}

// ─── Album Form Sheet ─────────────────────────────────────────────────────────
class _AlbumFormSheet extends StatefulWidget {
  final Album? album;
  final VoidCallback onSaved;
  const _AlbumFormSheet({this.album, required this.onSaved});
  @override
  State<_AlbumFormSheet> createState() => _AlbumFormSheetState();
}

class _AlbumFormSheetState extends State<_AlbumFormSheet> {
  final _nomeCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  String _selectedIcon = 'photo_album';
  String _selectedCor  = '#2E9E50';
  bool   _saving = false;

  bool get _editando => widget.album != null;

  final _cores = ['#2E9E50','#5B8DEF','#F5A623','#E07B39','#9B59B6','#E74C3C','#1ABC9C','#34495E'];

  @override
  void initState() {
    super.initState();
    if (_editando) {
      _nomeCtrl.text  = widget.album!.nome;
      _descCtrl.text  = widget.album!.descricao;
      _selectedIcon   = widget.album!.icone;
      _selectedCor    = widget.album!.cor;
    }
  }

  @override
  void dispose() { _nomeCtrl.dispose(); _descCtrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final color = hexToColor(_selectedCor);
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SingleChildScrollView(child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
          Center(child: Container(width: 36, height: 4,
              decoration: BoxDecoration(color: kBorder, borderRadius: BorderRadius.circular(2)))),
          const SizedBox(height: 16),
          Text(_editando ? 'Editar Álbum' : 'Novo Álbum',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: kTextPrimary)),
          const SizedBox(height: 16),

          // Preview
          Center(child: Container(
            width: 72, height: 72,
            decoration: BoxDecoration(
              color: Color.alphaBlend(color.withOpacity(0.15), Colors.white),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: color.withOpacity(0.4), width: 1.5),
            ),
            child: Icon(iconFromString(_selectedIcon), size: 36, color: color),
          )),
          const SizedBox(height: 16),

          // Nome
          const Text('NOME', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: kTextTertiary, letterSpacing: 0.5)),
          const SizedBox(height: 5),
          Container(
            decoration: BoxDecoration(color: kBg, borderRadius: BorderRadius.circular(12), border: Border.all(color: kBorder)),
            child: TextField(controller: _nomeCtrl,
                style: const TextStyle(fontSize: 13, color: kTextPrimary),
                decoration: const InputDecoration(hintText: 'Nome do álbum',
                    hintStyle: TextStyle(color: kTextTertiary),
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    border: InputBorder.none)),
          ),
          const SizedBox(height: 14),

          // Descrição
          const Text('DESCRIÇÃO', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: kTextTertiary, letterSpacing: 0.5)),
          const SizedBox(height: 5),
          Container(
            decoration: BoxDecoration(color: kBg, borderRadius: BorderRadius.circular(12), border: Border.all(color: kBorder)),
            child: TextField(controller: _descCtrl, maxLines: 2, minLines: 2,
                style: const TextStyle(fontSize: 13, color: kTextPrimary),
                decoration: const InputDecoration(hintText: 'Descrição opcional...',
                    hintStyle: TextStyle(color: kTextTertiary),
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    border: InputBorder.none)),
          ),
          const SizedBox(height: 14),

          // Ícone
          const Text('ÍCONE', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: kTextTertiary, letterSpacing: 0.5)),
          const SizedBox(height: 8),
          Wrap(spacing: 8, runSpacing: 8, children: kIconMap.entries.map((e) {
            final sel = _selectedIcon == e.key;
            return GestureDetector(
              onTap: () => setState(() => _selectedIcon = e.key),
              child: AnimatedContainer(duration: const Duration(milliseconds: 130),
                width: 44, height: 44,
                decoration: BoxDecoration(
                  color: sel ? color.withOpacity(0.15) : kBg,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: sel ? color : kBorder, width: sel ? 1.5 : 1),
                ),
                child: Icon(e.value, size: 22, color: sel ? color : kTextTertiary)),
            );
          }).toList()),
          const SizedBox(height: 14),

          // Cor
          const Text('COR', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: kTextTertiary, letterSpacing: 0.5)),
          const SizedBox(height: 8),
          Row(children: _cores.map((c) {
            final sel = _selectedCor == c;
            final col = hexToColor(c);
            return GestureDetector(
              onTap: () => setState(() => _selectedCor = c),
              child: AnimatedContainer(duration: const Duration(milliseconds: 130),
                width: 30, height: 30, margin: const EdgeInsets.only(right: 8),
                decoration: BoxDecoration(
                  color: col, shape: BoxShape.circle,
                  border: sel ? Border.all(color: Colors.white, width: 2) : null,
                  boxShadow: sel ? [BoxShadow(color: col.withOpacity(0.5), blurRadius: 6)] : null,
                ),
                child: sel ? const Icon(Icons.check, size: 14, color: Colors.white) : null),
            );
          }).toList()),
          const SizedBox(height: 20),

          // Save
          SizedBox(width: double.infinity,
            child: ElevatedButton(
              onPressed: _saving ? null : _save,
              style: ElevatedButton.styleFrom(backgroundColor: kGreen, foregroundColor: Colors.white,
                  elevation: 0, padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
              child: _saving
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : Text(_editando ? 'Salvar alterações' : 'Criar álbum',
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
            ),
          ),
        ]),
      )),
    );
  }

  Future<void> _save() async {
    final nome = _nomeCtrl.text.trim();
    if (nome.isEmpty) { showError(context, 'O nome do álbum é obrigatório.'); return; }
    setState(() => _saving = true);
    try {
      final album = Album(
        id:        _editando ? widget.album!.id : null,
        nome:      nome,
        descricao: _descCtrl.text.trim(),
        icone:     _selectedIcon,
        cor:       _selectedCor,
        criadoEm:  _editando ? widget.album!.criadoEm : DateTime.now().toIso8601String(),
      );
      if (_editando) {
        await DatabaseHelper.instance.atualizarAlbum(album);
      } else {
        await DatabaseHelper.instance.inserirAlbum(album);
      }
      if (mounted) {
        widget.onSaved();
        Navigator.pop(context);
        showSuccess(context, _editando ? 'Álbum atualizado!' : 'Álbum criado!');
      }
    } catch (e) {
      if (mounted) showError(context, 'Erro: $e');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}
