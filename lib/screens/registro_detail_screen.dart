import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:travel/database/database_helper.dart';
import 'package:travel/utils/app_constants.dart';

class NovoRegistroScreen extends StatefulWidget {
  final Registro? registroParaEditar; // null = novo, non-null = editar
  const NovoRegistroScreen({super.key, this.registroParaEditar});

  @override
  State<NovoRegistroScreen> createState() => _NovoRegistroScreenState();
}

class _NovoRegistroScreenState extends State<NovoRegistroScreen> {
  final _tituloCtrl    = TextEditingController();
  final _descricaoCtrl = TextEditingController();
  final _localCtrl     = TextEditingController();

  int?         _selectedMood     = 1;
  final Set<String> _selectedTags = {};
  Album?       _selectedAlbum;
  DateTime     _selectedDateTime = DateTime.now();
  bool         _saving           = false;
  bool         _loading          = true;

  List<XFile>  _fotos  = [];
  List<Album>  _albuns = [];

  final _picker   = ImagePicker();
  final _allTags  = ['Viagem', 'Família', 'Comida', 'Natureza', 'Trabalho', 'Esporte', 'Arte', 'Música'];

  bool get _editando => widget.registroParaEditar != null;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final albuns = await DatabaseHelper.instance.listarAlbuns();
    if (mounted) {
      setState(() {
        _albuns  = albuns;
        _loading = false;
      });
    }
    // Preenche campos se editando
    if (_editando) {
      final r = widget.registroParaEditar!;
      _tituloCtrl.text    = r.titulo;
      _descricaoCtrl.text = r.descricao;
      _localCtrl.text     = r.local;
      _selectedDateTime   = DateTime.tryParse(r.dataHora) ?? DateTime.now();
      _selectedMood       = r.humor;
      _selectedTags.addAll(r.tagList);
      _fotos = r.fotos.map((p) => XFile(p)).toList();
      if (r.albumId != null) {
        _selectedAlbum = albuns.firstWhere((a) => a.id == r.albumId,
            orElse: () => albuns.isEmpty ? Album(nome: r.album, criadoEm: '') : albuns.first);
      }
      if (mounted) setState(() {});
    }
  }

  @override
  void dispose() {
    _tituloCtrl.dispose();
    _descricaoCtrl.dispose();
    _localCtrl.dispose();
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
              : TextButton(onPressed: _handleSave,
                  child: const Text('Salvar', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500))),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: kGreen))
          : SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(12, 14, 12, 100),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                _label('Fotos'),
                const SizedBox(height: 6),
                _photoGrid(),
                const SizedBox(height: 16),
                _label('Título *'),
                const SizedBox(height: 6),
                _textField(controller: _tituloCtrl, hint: 'Ex: Tarde no parque...'),
                const SizedBox(height: 16),
                _label('Descrição'),
                const SizedBox(height: 6),
                _textField(controller: _descricaoCtrl, hint: 'O que aconteceu hoje?', maxLines: 4, minLines: 3),
                const SizedBox(height: 16),
                _label('Local'),
                const SizedBox(height: 6),
                _iconTextField(controller: _localCtrl, icon: Icons.location_on_outlined, hint: 'Cidade, ponto de referência...'),
                const SizedBox(height: 16),
                _label('Data & Hora'),
                const SizedBox(height: 6),
                _dateTimeTile(),
                const SizedBox(height: 16),
                _label('Humor'),
                const SizedBox(height: 6),
                _moodPicker(),
                const SizedBox(height: 16),
                _label('Tags'),
                const SizedBox(height: 6),
                _tagPicker(),
                const SizedBox(height: 16),
                _label('Álbum'),
                const SizedBox(height: 6),
                _albumPicker(),
                const SizedBox(height: 24),
                _saveButton(),
              ]),
            ),
    );
  }

  // ── Photo grid ─────────────────────────────────────────────────────────────
  Widget _photoGrid() {
    final slots = <Widget>[
      for (int i = 0; i < _fotos.length; i++) _photoPreview(i),
      if (_fotos.length < 6) _addPhotoBtn(),
    ];
    while (slots.length < 3) slots.add(_emptySlot());

    final rows = <Widget>[];
    for (int i = 0; i < slots.length; i += 3) {
      final row = slots.sublist(i, (i + 3).clamp(0, slots.length));
      while (row.length < 3) row.add(_emptySlot());
      rows.add(Row(children: [
        Expanded(child: AspectRatio(aspectRatio: 1, child: row[0])),
        const SizedBox(width: 5),
        Expanded(child: AspectRatio(aspectRatio: 1, child: row[1])),
        const SizedBox(width: 5),
        Expanded(child: AspectRatio(aspectRatio: 1, child: row[2])),
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

  Widget _addPhotoBtn() => GestureDetector(
    onTap: _showPhotoSheet,
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
    decoration: BoxDecoration(color: kCard, borderRadius: BorderRadius.circular(12), border: Border.all(color: kBorder)),
    child: const Icon(Icons.image_outlined, size: 22, color: kTextTertiary),
  );

  void _showPhotoSheet() {
    showModalBottomSheet(
      context: context, backgroundColor: kCard,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => SafeArea(child: Column(mainAxisSize: MainAxisSize.min, children: [
        const SizedBox(height: 8),
        Container(width: 36, height: 4, decoration: BoxDecoration(color: kBorder, borderRadius: BorderRadius.circular(2))),
        const SizedBox(height: 16),
        ListTile(leading: const Icon(Icons.camera_alt_outlined, color: kGreen),
            title: const Text('Tirar foto', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
            onTap: () { Navigator.pop(context); _pickImage(ImageSource.camera); }),
        ListTile(leading: const Icon(Icons.photo_library_outlined, color: kGreen),
            title: const Text('Escolher da galeria', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
            onTap: () { Navigator.pop(context); _pickImage(ImageSource.gallery); }),
        const SizedBox(height: 8),
      ])),
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      if (source == ImageSource.gallery) {
        final picked = await _picker.pickMultiImage(imageQuality: 80);
        if (picked.isNotEmpty) setState(() => _fotos.addAll(picked.take(6 - _fotos.length)));
      } else {
        final picked = await _picker.pickImage(source: source, imageQuality: 80);
        if (picked != null && _fotos.length < 6) setState(() => _fotos.add(picked));
      }
    } catch (_) {
      if (mounted) showError(context, 'Não foi possível acessar as fotos. Verifique as permissões.');
    }
  }

  // ── Form fields ────────────────────────────────────────────────────────────
  Widget _label(String t) => Text(t.toUpperCase(),
      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: kTextTertiary, letterSpacing: 0.5));

  Widget _textField({required TextEditingController controller, required String hint, int maxLines = 1, int minLines = 1}) =>
      Container(
        decoration: BoxDecoration(color: kCard, borderRadius: BorderRadius.circular(12), border: Border.all(color: kBorder)),
        child: TextField(
          controller: controller, maxLines: maxLines, minLines: minLines,
          style: const TextStyle(fontSize: 13, color: kTextPrimary),
          decoration: InputDecoration(hintText: hint,
              hintStyle: const TextStyle(fontSize: 13, color: kTextTertiary),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              border: InputBorder.none, enabledBorder: InputBorder.none, focusedBorder: InputBorder.none),
        ),
      );

  Widget _iconTextField({required TextEditingController controller, required IconData icon, required String hint}) =>
      Container(
        decoration: BoxDecoration(color: kCard, borderRadius: BorderRadius.circular(12), border: Border.all(color: kBorder)),
        child: Row(children: [
          const SizedBox(width: 12),
          Icon(icon, size: 16, color: kTextTertiary),
          Expanded(child: TextField(
            controller: controller,
            style: const TextStyle(fontSize: 13, color: kTextPrimary),
            decoration: InputDecoration(hintText: hint,
                hintStyle: const TextStyle(fontSize: 13, color: kTextTertiary),
                contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                border: InputBorder.none, enabledBorder: InputBorder.none, focusedBorder: InputBorder.none),
          )),
        ]),
      );

  Widget _dateTimeTile() => GestureDetector(
    onTap: _pickDateTime,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(color: kCard, borderRadius: BorderRadius.circular(12), border: Border.all(color: kBorder)),
      child: Row(children: [
        const Icon(Icons.calendar_today_outlined, size: 16, color: kTextTertiary),
        const SizedBox(width: 8),
        Text(formatDateTime(_selectedDateTime), style: const TextStyle(fontSize: 13, color: kTextSecondary)),
        const Spacer(),
        const Icon(Icons.edit_outlined, size: 14, color: kTextTertiary),
      ]),
    ),
  );

  Future<void> _pickDateTime() async {
    final date = await showDatePicker(
      context: context, initialDate: _selectedDateTime,
      firstDate: DateTime(2020), lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (ctx, child) => Theme(data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(primary: kGreen)), child: child!),
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(
      context: context, initialTime: TimeOfDay.fromDateTime(_selectedDateTime),
      builder: (ctx, child) => Theme(data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(primary: kGreen)), child: child!),
    );
    if (time == null) return;
    setState(() => _selectedDateTime = DateTime(date.year, date.month, date.day, time.hour, time.minute));
  }

  Widget _moodPicker() => Row(
    children: List.generate(kMoods.length, (i) {
      final sel = _selectedMood == i;
      return Expanded(child: GestureDetector(
        onTap: () => setState(() => _selectedMood = i),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          margin: EdgeInsets.only(right: i < kMoods.length - 1 ? 6 : 0),
          padding: const EdgeInsets.symmetric(vertical: 9),
          decoration: BoxDecoration(
            color: sel ? kGreenLight : kCard,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: sel ? kGreen : kBorder, width: sel ? 1.5 : 1),
          ),
          child: Center(child: Text(kMoods[i], style: const TextStyle(fontSize: 20))),
        ),
      ));
    }),
  );

  Widget _tagPicker() => Wrap(spacing: 6, runSpacing: 6, children: [
    ..._allTags.map((t) {
      final sel = _selectedTags.contains(t);
      return GestureDetector(
        onTap: () => setState(() => sel ? _selectedTags.remove(t) : _selectedTags.add(t)),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 130),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: sel ? kGreenLight : kCard,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: sel ? kGreenBorder : kBorder),
          ),
          child: Text(t, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500,
              color: sel ? kGreenDark : kTextSecondary)),
        ),
      );
    }),
  ]);

  Widget _albumPicker() => GestureDetector(
    onTap: _showAlbumSheet,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(color: kCard, borderRadius: BorderRadius.circular(12), border: Border.all(color: kBorder)),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Row(children: [
          if (_selectedAlbum != null) ...[
            Icon(iconFromString(_selectedAlbum!.icone), size: 18, color: hexToColor(_selectedAlbum!.cor)),
            const SizedBox(width: 8),
          ] else ...[
            const Icon(Icons.photo_album_outlined, size: 18, color: kTextTertiary),
            const SizedBox(width: 8),
          ],
          Text(_selectedAlbum?.nome ?? 'Sem álbum',
              style: TextStyle(fontSize: 13, color: _selectedAlbum != null ? kTextPrimary : kTextTertiary)),
        ]),
        const Icon(Icons.keyboard_arrow_down, size: 18, color: kTextTertiary),
      ]),
    ),
  );

  void _showAlbumSheet() {
    showModalBottomSheet(
      context: context, backgroundColor: kCard,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => SafeArea(child: Column(mainAxisSize: MainAxisSize.min, children: [
        const SizedBox(height: 8),
        Container(width: 36, height: 4, decoration: BoxDecoration(color: kBorder, borderRadius: BorderRadius.circular(2))),
        const SizedBox(height: 14),
        const Padding(padding: EdgeInsets.symmetric(horizontal: 16),
            child: Align(alignment: Alignment.centerLeft,
                child: Text('Escolher Álbum', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: kTextPrimary)))),
        const SizedBox(height: 6),
        ListTile(dense: true,
            leading: const Icon(Icons.do_not_disturb_alt_outlined, color: kTextTertiary),
            title: const Text('Sem álbum', style: TextStyle(fontSize: 14, color: kTextSecondary)),
            trailing: _selectedAlbum == null ? const Icon(Icons.check, color: kGreen, size: 18) : null,
            onTap: () { setState(() => _selectedAlbum = null); Navigator.pop(context); }),
        ..._albuns.map((a) {
          final active = _selectedAlbum?.id == a.id;
          final color  = hexToColor(a.cor);
          return ListTile(dense: true,
              leading: Icon(iconFromString(a.icone), color: active ? color : kTextTertiary),
              title: Text(a.nome, style: TextStyle(fontSize: 14,
                  fontWeight: active ? FontWeight.w600 : FontWeight.normal,
                  color: active ? color : kTextPrimary)),
              trailing: active ? Icon(Icons.check, color: color, size: 18) : null,
              onTap: () { setState(() => _selectedAlbum = a); Navigator.pop(context); });
        }),
        const SizedBox(height: 12),
      ])),
    );
  }

  // ── Save ───────────────────────────────────────────────────────────────────
  Widget _saveButton() => SizedBox(
    width: double.infinity,
    child: ElevatedButton(
      onPressed: _saving ? null : _handleSave,
      style: ElevatedButton.styleFrom(
        backgroundColor: kGreen, disabledBackgroundColor: kGreen.withOpacity(0.5),
        foregroundColor: Colors.white, elevation: 0,
        padding: const EdgeInsets.symmetric(vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      child: _saving
          ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
          : Text(_editando ? 'Salvar alterações' : 'Salvar registro',
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
    ),
  );

  Future<void> _handleSave() async {
    final titulo = _tituloCtrl.text.trim();
    if (titulo.isEmpty) { showError(context, 'Por favor, adicione um título ao registro.'); return; }
    setState(() => _saving = true);
    try {
      final registro = Registro(
        id:        _editando ? widget.registroParaEditar!.id : null,
        albumId:   _selectedAlbum?.id,
        titulo:    titulo,
        descricao: _descricaoCtrl.text.trim(),
        local:     _localCtrl.text.trim(),
        dataHora:  _selectedDateTime.toIso8601String(),
        humor:     _selectedMood ?? 0,
        tags:      _selectedTags.join(','),
        album:     _selectedAlbum?.nome ?? '',
        fotos:     _fotos.map((f) => f.path).toList(),
      );
      if (_editando) {
        await DatabaseHelper.instance.atualizarRegistro(registro);
      } else {
        await DatabaseHelper.instance.inserirRegistro(registro);
      }
      if (!mounted) return;
      showSuccess(context, _editando ? '✓ Registro atualizado!' : '✓ Registro salvo com sucesso!');
      Navigator.pop(context, true);
    } catch (e) {
      if (mounted) showError(context, 'Erro ao salvar: $e');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}