// lib/screens/novo_registro_screen.dart
//
// Correções aplicadas vs. versão anterior:
//  • TextEditingControllers reais (título, descrição, local) com dispose()
//  • DateTimePicker funcional
//  • image_picker: câmera + galeria com preview das fotos selecionadas
//  • Validação antes de salvar (título obrigatório)
//  • Persistência real via DatabaseHelper (SQLite)
//  • Tema consistente com home_screen (primarySwatch verde)
//  • _handleSave async com loading e pop após salvo

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:travel/database/database_helper.dart';

// ─── Constantes de cor (compartilhadas) ──────────────────────────────────────
const kGreen        = Color(0xFF2E9E50);
const kGreenLight   = Color(0xFFE6F4EC);
const kGreenBorder  = Color(0xFFB5D9C2);
const kGreenDark    = Color(0xFF1A7038);
const kBg           = Color(0xFFF2F2F7);
const kCard         = Color(0xFFFFFFFF);
const kBorder       = Color(0xFFE5E5EA);
const kTextPrimary   = Color(0xFF1C1C1E);
const kTextSecondary = Color(0xFF6C6C70);
const kTextTertiary  = Color(0xFFAEAEB2);

// ─── Página ───────────────────────────────────────────────────────────────────
class NovoRegistroPage extends StatefulWidget {
  const NovoRegistroPage({super.key});

  @override
  State<NovoRegistroPage> createState() => _NovoRegistroPageState();
}

class _NovoRegistroPageState extends State<NovoRegistroPage> {
  // Controllers
  final _tituloCtrl    = TextEditingController();
  final _descricaoCtrl = TextEditingController();
  final _localCtrl     = TextEditingController();

  // Estado do formulário
  int?        _selectedMood = 1;
  final Set<int> _selectedTags  = {0};
  int         _selectedAlbumIdx = 0;
  DateTime    _selectedDateTime = DateTime.now();
  bool        _saving = false;

  // Fotos
  final List<XFile> _fotos = [];
  final _picker = ImagePicker();

  // Dados estáticos
  final _moods  = ['😊', '😄', '😐', '😢', '😍'];
  final _tags   = ['Viagem', 'Família', 'Comida', 'Natureza'];
  final _albums = ['Inverno 2026', 'Verão 2026', 'Outono 2026', 'Primavera 2026'];

  @override
  void dispose() {
    _tituloCtrl.dispose();
    _descricaoCtrl.dispose();
    _localCtrl.dispose();
    super.dispose();
  }

  // ─── Build ─────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBg,
      appBar: AppBar(
        backgroundColor: kGreen,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white, size: 22),
          onPressed: () => Navigator.maybePop(context),
        ),
        title: const Text(
          'Novo Registro',
          style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600),
        ),
        actions: [
          _saving
              ? const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: SizedBox(
                    width: 18, height: 18,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                  ),
                )
              : TextButton(
                  onPressed: _handleSave,
                  child: const Text(
                    'Salvar',
                    style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500),
                  ),
                ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(12, 14, 12, 100),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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
            _textField(
              controller: _descricaoCtrl,
              hint: 'O que aconteceu hoje?',
              maxLines: 4,
              minLines: 3,
            ),
            const SizedBox(height: 16),

            _label('Local'),
            const SizedBox(height: 6),
            _textFieldIcon(
              controller: _localCtrl,
              icon: Icons.location_on_outlined,
              hint: 'Cidade, ponto de referência...',
            ),
            const SizedBox(height: 16),

            _label('Data & Hora'),
            const SizedBox(height: 6),
            _dateTimePicker(),
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
            _albumDropdown(),
            const SizedBox(height: 24),

            _saveButton(),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  // ─── Seção de fotos ────────────────────────────────────────────────────────

  Widget _photoGrid() {
    // Mostra fotos selecionadas + botão "adicionar" se couber mais
    final slots = <Widget>[];

    for (int i = 0; i < _fotos.length; i++) {
      slots.add(_fotoPreview(i));
    }

    // Botão adicionar (até 6 fotos)
    if (_fotos.length < 6) {
      slots.add(_addFotoButton());
    }

    // Preenche até 3 colunas visíveis na primeira linha
    while (slots.length < 3) {
      slots.add(_emptySlot());
    }

    // Agrupa em linhas de 3
    final rows = <Widget>[];
    for (int i = 0; i < slots.length; i += 3) {
      final rowItems = slots.sublist(i, i + 3 > slots.length ? slots.length : i + 3);
      while (rowItems.length < 3) rowItems.add(_emptySlot());

      rows.add(Row(
        children: rowItems
            .expand((w) => [Expanded(child: AspectRatio(aspectRatio: 1, child: w))])
            .toList()
          ..insertAll(1, [Expanded(child: const SizedBox(width: 5))])
          ..insertAll(3, [Expanded(child: const SizedBox(width: 5))]),
      ));
      if (i + 3 < slots.length) rows.add(const SizedBox(height: 5));
    }

    return Column(children: rows);
  }

  Widget _fotoPreview(int index) {
    return Stack(
      fit: StackFit.expand,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.file(
            File(_fotos[index].path),
            fit: BoxFit.cover,
          ),
        ),
        Positioned(
          top: 4, right: 4,
          child: GestureDetector(
            onTap: () => setState(() => _fotos.removeAt(index)),
            child: Container(
              width: 22, height: 22,
              decoration: const BoxDecoration(
                color: Colors.black54,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.close, size: 14, color: Colors.white),
            ),
          ),
        ),
      ],
    );
  }

  Widget _addFotoButton() {
    return GestureDetector(
      onTap: _showPhotoSourceSheet,
      child: Container(
        decoration: BoxDecoration(
          color: kCard,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: kGreen, width: 1.5),
        ),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add_a_photo_outlined, size: 24, color: kGreen),
            SizedBox(height: 4),
            Text(
              'Adicionar',
              style: TextStyle(fontSize: 10, color: kGreen, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
    );
  }

  Widget _emptySlot() {
    return Container(
      decoration: BoxDecoration(
        color: kCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: kBorder),
      ),
      child: const Icon(Icons.image_outlined, size: 22, color: kTextTertiary),
    );
  }

  void _showPhotoSourceSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: kCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 36, height: 4,
              decoration: BoxDecoration(color: kBorder, borderRadius: BorderRadius.circular(2)),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined, color: kGreen),
              title: const Text('Tirar foto', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined, color: kGreen),
              title: const Text('Escolher da galeria', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.gallery);
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      if (source == ImageSource.gallery) {
        // Permite selecionar múltiplas fotos de uma vez
        final picked = await _picker.pickMultiImage(imageQuality: 80);
        if (picked.isNotEmpty) {
          setState(() {
            final restante = 6 - _fotos.length;
            _fotos.addAll(picked.take(restante));
          });
        }
      } else {
        final picked = await _picker.pickImage(source: source, imageQuality: 80);
        if (picked != null) {
          setState(() => _fotos.add(picked));
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Não foi possível acessar as fotos. Verifique as permissões.')),
        );
      }
    }
  }

  // ─── Campos de texto ───────────────────────────────────────────────────────

  Widget _label(String text) => Text(
    text.toUpperCase(),
    style: const TextStyle(
      fontSize: 11, fontWeight: FontWeight.w600,
      color: kTextTertiary, letterSpacing: 0.5,
    ),
  );

  Widget _textField({
    required TextEditingController controller,
    required String hint,
    int maxLines = 1,
    int minLines = 1,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: kCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: kBorder),
      ),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        minLines: minLines,
        style: const TextStyle(fontSize: 13, color: kTextPrimary),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(fontSize: 13, color: kTextTertiary),
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
        ),
      ),
    );
  }

  Widget _textFieldIcon({
    required TextEditingController controller,
    required IconData icon,
    required String hint,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: kCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: kBorder),
      ),
      child: Row(
        children: [
          const SizedBox(width: 12),
          Icon(icon, size: 16, color: kTextTertiary),
          Expanded(
            child: TextField(
              controller: controller,
              style: const TextStyle(fontSize: 13, color: kTextPrimary),
              decoration: InputDecoration(
                hintText: hint,
                hintStyle: const TextStyle(fontSize: 13, color: kTextTertiary),
                contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Date picker ───────────────────────────────────────────────────────────

  Widget _dateTimePicker() {
    final formatted = _formatDateTime(_selectedDateTime);
    return GestureDetector(
      onTap: _pickDateTime,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: kCard,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: kBorder),
        ),
        child: Row(
          children: [
            const Icon(Icons.calendar_today_outlined, size: 16, color: kTextTertiary),
            const SizedBox(width: 8),
            Text(formatted, style: const TextStyle(fontSize: 13, color: kTextSecondary)),
            const Spacer(),
            const Icon(Icons.edit_outlined, size: 14, color: kTextTertiary),
          ],
        ),
      ),
    );
  }

  Future<void> _pickDateTime() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDateTime,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(primary: kGreen),
        ),
        child: child!,
      ),
    );
    if (date == null || !mounted) return;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_selectedDateTime),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(primary: kGreen),
        ),
        child: child!,
      ),
    );
    if (time == null) return;

    setState(() {
      _selectedDateTime = DateTime(date.year, date.month, date.day, time.hour, time.minute);
    });
  }

  String _formatDateTime(DateTime dt) {
    const meses = ['Jan','Fev','Mar','Abr','Mai','Jun','Jul','Ago','Set','Out','Nov','Dez'];
    final hora = dt.hour.toString().padLeft(2, '0');
    final min  = dt.minute.toString().padLeft(2, '0');
    return '${dt.day} ${meses[dt.month - 1]} ${dt.year} · $hora:$min';
  }

  // ─── Mood picker ───────────────────────────────────────────────────────────

  Widget _moodPicker() {
    return Row(
      children: List.generate(_moods.length, (i) {
        final sel = _selectedMood == i;
        return Expanded(
          child: GestureDetector(
            onTap: () => setState(() => _selectedMood = i),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              margin: EdgeInsets.only(right: i < _moods.length - 1 ? 6 : 0),
              padding: const EdgeInsets.symmetric(vertical: 9),
              decoration: BoxDecoration(
                color: sel ? kGreenLight : kCard,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: sel ? kGreen : kBorder, width: sel ? 1.5 : 1),
              ),
              child: Center(
                child: Text(_moods[i], style: const TextStyle(fontSize: 20)),
              ),
            ),
          ),
        );
      }),
    );
  }

  // ─── Tag picker ────────────────────────────────────────────────────────────

  Widget _tagPicker() {
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: [
        ..._tags.asMap().entries.map((e) {
          final sel = _selectedTags.contains(e.key);
          return GestureDetector(
            onTap: () => setState(() {
              sel ? _selectedTags.remove(e.key) : _selectedTags.add(e.key);
            }),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 130),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: sel ? kGreenLight : kCard,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: sel ? kGreenBorder : kBorder),
              ),
              child: Text(
                e.value,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: sel ? kGreenDark : kTextSecondary,
                ),
              ),
            ),
          );
        }),
        GestureDetector(
          onTap: () {},
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: kCard,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: kBorder),
            ),
            child: const Text(
              '+ Nova',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: kTextTertiary),
            ),
          ),
        ),
      ],
    );
  }

  // ─── Album dropdown ────────────────────────────────────────────────────────

  Widget _albumDropdown() {
    return GestureDetector(
      onTap: _showAlbumSheet,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: kCard,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: kBorder),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(_albums[_selectedAlbumIdx],
                style: const TextStyle(fontSize: 13, color: kTextSecondary)),
            const Icon(Icons.keyboard_arrow_down, size: 18, color: kTextTertiary),
          ],
        ),
      ),
    );
  }

  void _showAlbumSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: kCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) {
        final icons = [
          Icons.ac_unit,
          Icons.wb_sunny_outlined,
          Icons.eco_outlined,
          Icons.local_florist_outlined,
        ];
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 8),
              Container(
                width: 36, height: 4,
                decoration: BoxDecoration(color: kBorder, borderRadius: BorderRadius.circular(2)),
              ),
              const SizedBox(height: 14),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Escolher Álbum',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: kTextPrimary),
                  ),
                ),
              ),
              const SizedBox(height: 6),
              ..._albums.asMap().entries.map((e) {
                final active = e.key == _selectedAlbumIdx;
                return ListTile(
                  dense: true,
                  leading: Icon(icons[e.key], color: active ? kGreen : kTextTertiary),
                  title: Text(
                    e.value,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: active ? FontWeight.w600 : FontWeight.normal,
                      color: active ? kGreen : kTextPrimary,
                    ),
                  ),
                  trailing: active ? const Icon(Icons.check, color: kGreen, size: 18) : null,
                  onTap: () {
                    setState(() => _selectedAlbumIdx = e.key);
                    Navigator.pop(context);
                  },
                );
              }),
              const SizedBox(height: 12),
            ],
          ),
        );
      },
    );
  }

  // ─── Salvar ────────────────────────────────────────────────────────────────

  Widget _saveButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _saving ? null : _handleSave,
        style: ElevatedButton.styleFrom(
          backgroundColor: kGreen,
          disabledBackgroundColor: kGreen.withOpacity(0.5),
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        child: _saving
            ? const SizedBox(
                height: 18, width: 18,
                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
              )
            : const Text(
                'Salvar registro',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
              ),
      ),
    );
  }

  Future<void> _handleSave() async {
    // Validação
    final titulo = _tituloCtrl.text.trim();
    if (titulo.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Por favor, adicione um título ao registro.'),
          backgroundColor: Colors.red[700],
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          margin: const EdgeInsets.all(12),
        ),
      );
      return;
    }

    setState(() => _saving = true);

    try {
      final tagsStr = _selectedTags.map((i) => _tags[i]).join(',');

      final registro = Registro(
        titulo:    titulo,
        descricao: _descricaoCtrl.text.trim(),
        local:     _localCtrl.text.trim(),
        dataHora:  _selectedDateTime.toIso8601String(),
        humor:     _selectedMood ?? 0,
        tags:      tagsStr,
        album:     _albums[_selectedAlbumIdx],
        fotos:     _fotos.map((f) => f.path).toList(),
      );

      await DatabaseHelper.instance.inserirRegistro(registro);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('✓ Registro salvo com sucesso!'),
          backgroundColor: kGreen,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          margin: const EdgeInsets.all(12),
        ),
      );

      // Retorna true para a tela anterior poder atualizar a lista
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao salvar: $e'),
          backgroundColor: Colors.red[700],
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          margin: const EdgeInsets.all(12),
        ),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  // ─── Bottom nav ────────────────────────────────────────────────────────────

  Widget _buildBottomNav() {
    return Container(
      height: 64,
      decoration: const BoxDecoration(
        color: kCard,
        border: Border(top: BorderSide(color: kBorder)),
      ),
      child: Row(
        children: [
          _navItem(Icons.home_outlined, 'Home', false),
          _navItem(Icons.timeline_outlined, 'Timeline', false),
          Expanded(
            flex: 1,
            child: Center(
              child: Container(
                width: 44, height: 44,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: kCard,
                  border: Border.all(color: kGreen, width: 1.5),
                  boxShadow: [BoxShadow(color: kGreen.withOpacity(0.15), blurRadius: 8)],
                ),
                child: const Icon(Icons.add, color: kGreen, size: 22),
              ),
            ),
          ),
          _navItem(Icons.map_outlined, 'Mapa', false),
          _navItem(Icons.show_chart_outlined, 'Insights', false),
        ],
      ),
    );
  }

  Widget _navItem(IconData icon, String label, bool active) {
    return Expanded(
      child: GestureDetector(
        onTap: () {},
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 22, color: active ? kGreen : kTextTertiary),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                color: active ? kGreen : kTextTertiary,
                fontWeight: active ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
