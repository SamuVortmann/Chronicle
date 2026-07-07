// lib/screens/novo_registro_screen.dart
//
// Fixes vs RAR version:
//  1. _albums was a hardcoded static list — now loads from DB
//  2. albumId never saved to Registro — now wired properly
//  3. _photoGrid used broken Expanded inside Row (caused render overflow)
//  4. Tags stored as int indices — now stored as strings directly
//  5. Supports edit mode (registroParaEditar param)

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:travel/database/database_helper.dart';
import 'package:travel/utils/app_constants.dart';

class NovoRegistroScreen extends StatefulWidget {
  final Registro? registroParaEditar;
  const NovoRegistroScreen({super.key, this.registroParaEditar});

  @override
  State<NovoRegistroScreen> createState() => _NovoRegistroScreenState();
}

class _NovoRegistroScreenState extends State<NovoRegistroScreen> {
  final _tituloCtrl    = TextEditingController();
  final _descricaoCtrl = TextEditingController();
  final _localCtrl     = TextEditingController();

  int?              _mood          = 1;
  final Set<String> _tags          = {};
  Album?            _album;
  DateTime          _dt            = DateTime.now();
  bool              _saving        = false;
  bool              _loadingAlbuns = true;

  List<XFile> _fotos  = [];
  List<Album> _albuns = [];

  final _picker  = ImagePicker();
  final _allTags = ['Viagem', 'Família', 'Comida', 'Natureza', 'Trabalho', 'Esporte', 'Arte', 'Música'];

  bool get _editando => widget.registroParaEditar != null;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final albuns = await DatabaseHelper.instance.listarAlbuns();
    if (!mounted) return;
    setState(() { _albuns = albuns; _loadingAlbuns = false; });

    if (_editando) {
      final r = widget.registroParaEditar!;
      _tituloCtrl.text    = r.titulo;
      _descricaoCtrl.text = r.descricao;
      _localCtrl.text     = r.local;
      _dt                 = DateTime.tryParse(r.dataHora) ?? DateTime.now();
      _mood               = r.humor;
      _tags.addAll(r.tagList);
      _fotos              = r.fotos.map(XFile.new).toList();
      if (r.albumId != null) {
        _album = albuns.where((a) => a.id == r.albumId).firstOrNull;
      }
      setState(() {});
    }
  }

  @override
  void dispose() {
    _tituloCtrl.dispose(); _descricaoCtrl.dispose(); _localCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBg,
      appBar: AppBar(
        backgroundColor: kGreen, elevation: 0, centerTitle: true,
        leading: IconButton(icon: const Icon(Icons.close, color: Colors.white, size: 22),
            onPressed: () => Navigator.maybePop(context)),
        title: Text(_editando ? 'Editar Registro' : 'Novo Registro',
            style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600)),
        actions: [
          _saving
              ? const Padding(padding: EdgeInsets.symmetric(horizontal: 16),
                  child: SizedBox(width: 18, height: 18,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)))
              : TextButton(onPressed: _save,
                  child: const Text('Salvar', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500))),
        ],
      ),
      body: _loadingAlbuns
          ? const Center(child: CircularProgressIndicator(color: kGreen))
          : SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(12, 14, 12, 100),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                _label('Fotos'),         const SizedBox(height: 6),  _photoGrid(),      const SizedBox(height: 16),
                _label('Título *'),      const SizedBox(height: 6),  _field(_tituloCtrl, 'Ex: Tarde no parque...'), const SizedBox(height: 16),
                _label('Descrição'),     const SizedBox(height: 6),  _field(_descricaoCtrl, 'O que aconteceu hoje?', maxLines: 4, minLines: 3), const SizedBox(height: 16),
                _label('Local'),         const SizedBox(height: 6),  _iconField(_localCtrl, Icons.location_on_outlined, 'Cidade, ponto de referência...'), const SizedBox(height: 16),
                _label('Data & Hora'),   const SizedBox(height: 6),  _dateTile(),       const SizedBox(height: 16),
                _label('Humor'),         const SizedBox(height: 6),  _moodRow(),        const SizedBox(height: 16),
                _label('Tags'),          const SizedBox(height: 6),  _tagWrap(),        const SizedBox(height: 16),
                _label('Álbum'),         const SizedBox(height: 6),  _albumTile(),      const SizedBox(height: 24),
                _saveBtn(),
              ]),
            ),
    );
  }

  // ── Photo grid ─────────────────────────────────────────────────────────────
  Widget _photoGrid() {
    final slots = <Widget>[
      for (int i = 0; i < _fotos.length; i++) _photoPreview(i),
      if (_fotos.length < 6) _addBtn(),
    ];
    while (slots.length < 3) slots.add(_emptySlot());

    final rows = <Widget>[];
    for (int i = 0; i < slots.length; i += 3) {
      final chunk = slots.sublist(i, (i + 3).clamp(0, slots.length));
      while (chunk.length < 3) chunk.add(_emptySlot());
      rows.add(Row(children: [
        Expanded(child: AspectRatio(aspectRatio: 1, child: chunk[0])),
        const SizedBox(width: 5),
        Expanded(child: AspectRatio(aspectRatio: 1, child: chunk[1])),
        const SizedBox(width: 5),
        Expanded(child: AspectRatio(aspectRatio: 1, child: chunk[2])),
      ]));
      if (i + 3 < slots.length) rows.add(const SizedBox(height: 5));
    }
    return Column(children: rows);
  }

  Widget _photoPreview(int i) => Stack(fit: StackFit.expand, children: [
    ClipRRect(borderRadius: BorderRadius.circular(12),
        child: Image.file(File(_fotos[i].path), fit: BoxFit.cover)),
    Positioned(top: 4, right: 4,
        child: GestureDetector(
          onTap: () => setState(() => _fotos.removeAt(i)),
          child: Container(width: 22, height: 22,
              decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
              child: const Icon(Icons.close, size: 14, color: Colors.white)),
        )),
  ]);

  Widget _addBtn() => GestureDetector(
    onTap: _photoSheet,
    child: Container(
      decoration: BoxDecoration(color: kCard, borderRadius: BorderRadius.circular(12),
          border: Border.all(color: kGreen, width: 1.5)),
      child: const Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(Icons.add_a_photo_outlined, size: 24, color: kGreen),
        SizedBox(height: 4),
        Text('Adicionar', style: TextStyle(fontSize: 10, color: kGreen, fontWeight: FontWeight.w500)),
      ]),
    ),
  );

  Widget _emptySlot() => Container(
    decoration: BoxDecoration(color: kCard, borderRadius: BorderRadius.circular(12),
        border: Border.all(color: kBorder)),
    child: const Icon(Icons.image_outlined, size: 22, color: kTextTertiary),
  );

  void _photoSheet() => showModalBottomSheet(
    context: context, backgroundColor: kCard,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
    builder: (_) => SafeArea(child: Column(mainAxisSize: MainAxisSize.min, children: [
      const SizedBox(height: 8),
      Container(width: 36, height: 4, decoration: BoxDecoration(color: kBorder, borderRadius: BorderRadius.circular(2))),
      const SizedBox(height: 16),
      ListTile(leading: const Icon(Icons.camera_alt_outlined, color: kGreen),
          title: const Text('Tirar foto'),
          onTap: () { Navigator.pop(context); _pick(ImageSource.camera); }),
      ListTile(leading: const Icon(Icons.photo_library_outlined, color: kGreen),
          title: const Text('Escolher da galeria'),
          onTap: () { Navigator.pop(context); _pick(ImageSource.gallery); }),
      const SizedBox(height: 8),
    ])),
  );

  Future<void> _pick(ImageSource src) async {
    try {
      if (src == ImageSource.gallery) {
        final picked = await _picker.pickMultiImage(imageQuality: 80);
        if (picked.isNotEmpty) setState(() => _fotos.addAll(picked.take(6 - _fotos.length)));
      } else {
        final f = await _picker.pickImage(source: src, imageQuality: 80);
        if (f != null && _fotos.length < 6) setState(() => _fotos.add(f));
      }
    } catch (_) {
      if (mounted) showError(context, 'Não foi possível acessar as fotos. Verifique as permissões.');
    }
  }

  // ── Form helpers ───────────────────────────────────────────────────────────
  Widget _label(String t) => Text(t.toUpperCase(),
      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600,
          color: kTextTertiary, letterSpacing: 0.5));

  Widget _field(TextEditingController ctrl, String hint,
      {int maxLines = 1, int minLines = 1}) =>
      Container(
        decoration: BoxDecoration(color: kCard, borderRadius: BorderRadius.circular(12),
            border: Border.all(color: kBorder)),
        child: TextField(controller: ctrl, maxLines: maxLines, minLines: minLines,
            style: const TextStyle(fontSize: 13, color: kTextPrimary),
            decoration: InputDecoration(hintText: hint,
                hintStyle: const TextStyle(fontSize: 13, color: kTextTertiary),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                border: InputBorder.none, enabledBorder: InputBorder.none, focusedBorder: InputBorder.none)),
      );

  Widget _iconField(TextEditingController ctrl, IconData icon, String hint) =>
      Container(
        decoration: BoxDecoration(color: kCard, borderRadius: BorderRadius.circular(12),
            border: Border.all(color: kBorder)),
        child: Row(children: [
          const SizedBox(width: 12),
          Icon(icon, size: 16, color: kTextTertiary),
          Expanded(child: TextField(controller: ctrl,
              style: const TextStyle(fontSize: 13, color: kTextPrimary),
              decoration: InputDecoration(hintText: hint,
                  hintStyle: const TextStyle(fontSize: 13, color: kTextTertiary),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                  border: InputBorder.none, enabledBorder: InputBorder.none, focusedBorder: InputBorder.none))),
        ]),
      );

  Widget _dateTile() => GestureDetector(
    onTap: _pickDate,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(color: kCard, borderRadius: BorderRadius.circular(12),
          border: Border.all(color: kBorder)),
      child: Row(children: [
        const Icon(Icons.calendar_today_outlined, size: 16, color: kTextTertiary),
        const SizedBox(width: 8),
        Text(formatDateTime(_dt), style: const TextStyle(fontSize: 13, color: kTextSecondary)),
        const Spacer(),
        const Icon(Icons.edit_outlined, size: 14, color: kTextTertiary),
      ]),
    ),
  );

  Future<void> _pickDate() async {
    final d = await showDatePicker(context: context, initialDate: _dt,
        firstDate: DateTime(2020), lastDate: DateTime.now().add(const Duration(days: 365)),
        builder: (ctx, child) => Theme(data: Theme.of(ctx).copyWith(
            colorScheme: const ColorScheme.light(primary: kGreen)), child: child!));
    if (d == null || !mounted) return;
    final t = await showTimePicker(context: context, initialTime: TimeOfDay.fromDateTime(_dt),
        builder: (ctx, child) => Theme(data: Theme.of(ctx).copyWith(
            colorScheme: const ColorScheme.light(primary: kGreen)), child: child!));
    if (t == null) return;
    setState(() => _dt = DateTime(d.year, d.month, d.day, t.hour, t.minute));
  }

  Widget _moodRow() => Row(
    children: List.generate(kMoods.length, (i) {
      final sel = _mood == i;
      return Expanded(child: GestureDetector(
        onTap: () => setState(() => _mood = i),
        child: AnimatedContainer(duration: const Duration(milliseconds: 150),
          margin: EdgeInsets.only(right: i < kMoods.length - 1 ? 6 : 0),
          padding: const EdgeInsets.symmetric(vertical: 9),
          decoration: BoxDecoration(color: sel ? kGreenLight : kCard,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: sel ? kGreen : kBorder, width: sel ? 1.5 : 1)),
          child: Center(child: Text(kMoods[i], style: const TextStyle(fontSize: 20)))),
      ));
    }),
  );

  Widget _tagWrap() => Wrap(spacing: 6, runSpacing: 6, children: [
    ..._allTags.map((t) {
      final sel = _tags.contains(t);
      return GestureDetector(
        onTap: () => setState(() => sel ? _tags.remove(t) : _tags.add(t)),
        child: AnimatedContainer(duration: const Duration(milliseconds: 130),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(color: sel ? kGreenLight : kCard,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: sel ? kGreenBorder : kBorder)),
          child: Text(t, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500,
              color: sel ? kGreenDark : kTextSecondary))),
      );
    }),
  ]);

  Widget _albumTile() => GestureDetector(
    onTap: _albumSheet,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(color: kCard, borderRadius: BorderRadius.circular(12),
          border: Border.all(color: kBorder)),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Row(children: [
          Icon(_album != null ? iconFromString(_album!.icone) : Icons.photo_album_outlined,
              size: 18, color: _album != null ? hexToColor(_album!.cor) : kTextTertiary),
          const SizedBox(width: 8),
          Text(_album?.nome ?? 'Sem álbum',
              style: TextStyle(fontSize: 13, color: _album != null ? kTextPrimary : kTextTertiary)),
        ]),
        const Icon(Icons.keyboard_arrow_down, size: 18, color: kTextTertiary),
      ]),
    ),
  );

  void _albumSheet() => showModalBottomSheet(
    context: context, backgroundColor: kCard,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
    builder: (_) => SafeArea(child: Column(mainAxisSize: MainAxisSize.min, children: [
      const SizedBox(height: 8),
      Container(width: 36, height: 4, decoration: BoxDecoration(color: kBorder, borderRadius: BorderRadius.circular(2))),
      const SizedBox(height: 14),
      const Padding(padding: EdgeInsets.symmetric(horizontal: 16),
          child: Align(alignment: Alignment.centerLeft,
              child: Text('Escolher Álbum', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)))),
      const SizedBox(height: 6),
      ListTile(dense: true,
          leading: const Icon(Icons.do_not_disturb_alt_outlined, color: kTextTertiary),
          title: const Text('Sem álbum', style: TextStyle(color: kTextSecondary)),
          trailing: _album == null ? const Icon(Icons.check, color: kGreen, size: 18) : null,
          onTap: () { setState(() => _album = null); Navigator.pop(context); }),
      ..._albuns.map((a) {
        final sel   = _album?.id == a.id;
        final color = hexToColor(a.cor);
        return ListTile(dense: true,
            leading: Icon(iconFromString(a.icone), color: sel ? color : kTextTertiary),
            title: Text(a.nome, style: TextStyle(fontSize: 14,
                fontWeight: sel ? FontWeight.w600 : FontWeight.normal,
                color: sel ? color : kTextPrimary)),
            trailing: sel ? Icon(Icons.check, color: color, size: 18) : null,
            onTap: () { setState(() => _album = a); Navigator.pop(context); });
      }),
      const SizedBox(height: 12),
    ])),
  );

  // ── Save ───────────────────────────────────────────────────────────────────
  Widget _saveBtn() => SizedBox(
    width: double.infinity,
    child: ElevatedButton(
      onPressed: _saving ? null : _save,
      style: ElevatedButton.styleFrom(backgroundColor: kGreen,
          disabledBackgroundColor: kGreen.withOpacity(0.5),
          foregroundColor: Colors.white, elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
      child: _saving
          ? const SizedBox(height: 18, width: 18,
              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
          : Text(_editando ? 'Salvar alterações' : 'Salvar registro',
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
    ),
  );

  Future<void> _save() async {
    final titulo = _tituloCtrl.text.trim();
    if (titulo.isEmpty) { showError(context, 'Por favor, adicione um título ao registro.'); return; }
    setState(() => _saving = true);
    try {
      final r = Registro(
        id:        _editando ? widget.registroParaEditar!.id : null,
        albumId:   _album?.id,
        titulo:    titulo,
        descricao: _descricaoCtrl.text.trim(),
        local:     _localCtrl.text.trim(),
        dataHora:  _dt.toIso8601String(),
        humor:     _mood ?? 0,
        tags:      _tags.join(','),
        album:     _album?.nome ?? '',
        fotos:     _fotos.map((f) => f.path).toList(),
      );
      if (_editando) {
        await DatabaseHelper.instance.atualizarRegistro(r);
      } else {
        await DatabaseHelper.instance.inserirRegistro(r);
      }
      if (!mounted) return;
      showSuccess(context, _editando ? '✓ Registro atualizado!' : '✓ Registro salvo!');
      Navigator.pop(context, true);
    } catch (e) {
      if (mounted) showError(context, 'Erro ao salvar: $e');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}
