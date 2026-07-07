// lib/screens/home_screen.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:travel/database/database_helper.dart';
import 'package:travel/screens/novo_registro_screen.dart';

// ─── Constantes de cor ───────────────────────────────────────────────────────
const _kGreen         = Color(0xFF2E9E50);
const _kGreenLight    = Color(0xFFE6F4EC);
const _kGreenBorder   = Color(0xFFB5D9C2);
const _kBg            = Color(0xFFF2F2F7);
const _kCard          = Color(0xFFFFFFFF);
const _kBorder        = Color(0xFFE5E5EA);
const _kTextPrimary   = Color(0xFF1C1C1E);
const _kTextSecondary = Color(0xFF6C6C70);
const _kTextTertiary  = Color(0xFFAEAEB2);

// ─── Entry point ─────────────────────────────────────────────────────────────
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Inicializa SQLite via FFI em Desktop/Web (Windows, Linux, macOS)
  // No Android/iOS o sqflite nativo já funciona sem isso
  DatabaseHelper.initFfiIfNeeded();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Chronicle',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: _kGreen),
        scaffoldBackgroundColor: _kBg,
      ),
      home: const HomeScreen(),
    );
  }
}

// ─── Home Screen ─────────────────────────────────────────────────────────────
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _navIndex = 0;

  List<Registro> _registros = [];
  int _totalRegistros = 0;

  // Três estados possíveis: loading | loaded | error
  bool _loading = true;
  String? _erro;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    // Garante que _loading seja true antes de qualquer await
    if (mounted) setState(() { _loading = true; _erro = null; });

    try {
      final registros = await DatabaseHelper.instance.listarRegistros();
      final total     = await DatabaseHelper.instance.totalRegistros();

      if (mounted) {
        setState(() {
          _registros      = registros;
          _totalRegistros = total;
          _loading        = false;
        });
      }
    } catch (e) {
      // Sem try/catch aqui o spinner ficava eterno quando o banco falhava
      if (mounted) {
        setState(() {
          _loading = false;
          _erro    = e.toString();
        });
      }
    }
  }

  Future<void> _goToNovoRegistro() async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const NovoRegistroPage()),
    );
    if (result == true) _loadData();
  }

  // ─── Build ─────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      appBar: AppBar(
        backgroundColor: _kGreen,
        elevation: 0,
        title: const Row(
          children: [
            Icon(Icons.public, color: Colors.white, size: 20),
            SizedBox(width: 6),
            Text(
              'Chronicle',
              style: TextStyle(
                color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined, color: Colors.white),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined, color: Colors.white),
            onPressed: () {},
          ),
        ],
      ),
      body: _buildBody(),
      bottomNavigationBar: _buildBottomNav(),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: FloatingActionButton(
        onPressed: _goToNovoRegistro,
        backgroundColor: _kGreen,
        elevation: 4,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator(color: _kGreen));
    }

    if (_erro != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 12),
              const Text(
                'Não foi possível carregar os dados.',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: _kTextPrimary),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 6),
              Text(
                _erro!,
                style: const TextStyle(fontSize: 12, color: _kTextSecondary),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: _loadData,
                icon: const Icon(Icons.refresh),
                label: const Text('Tentar novamente'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _kGreen,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      color: _kGreen,
      onRefresh: _loadData,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.only(bottom: 80),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sectionHeader('ÁLBUNS', showViewAll: true),
            _albumsSection(),
            _sectionHeader('ÚLTIMOS ACESSOS'),
            _recentSection(),
            _sectionHeader('CONTINUAR HOJE'),
            _continueTodaySection(),
            _sectionHeader('ESTATÍSTICAS'),
            _statisticsSection(),
          ],
        ),
      ),
    );
  }

  // ─── Seções ────────────────────────────────────────────────────────────────

  Widget _sectionHeader(String title, {bool showViewAll = false}) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 11, fontWeight: FontWeight.w700,
              color: _kTextTertiary, letterSpacing: 0.5,
            ),
          ),
          if (showViewAll)
            GestureDetector(
              onTap: () {},
              child: const Text(
                'Ver todos',
                style: TextStyle(color: _kGreen, fontSize: 12, fontWeight: FontWeight.w600),
              ),
            ),
        ],
      ),
    );
  }

  // Álbuns
  Widget _albumsSection() {
    final albums = [
      _AlbumData('Inverno',   Icons.ac_unit,                  true),
      _AlbumData('Verão',     Icons.wb_sunny_outlined,        false),
      _AlbumData('Outono',    Icons.eco_outlined,             false),
      _AlbumData('Primavera', Icons.local_florist_outlined,   false),
    ];

    return SizedBox(
      height: 128,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
        itemCount: albums.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (_, i) => _albumCard(albums[i]),
      ),
    );
  }

  Widget _albumCard(_AlbumData data) {
    return SizedBox(
      width: 90,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 78, width: 90,
            decoration: BoxDecoration(
              color:  data.active ? _kGreenLight : _kCard,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: data.active ? _kGreenBorder : _kBorder),
            ),
            child: Center(
              child: Icon(data.icon, size: 28, color: data.active ? _kGreen : _kTextTertiary),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            data.name,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: _kTextPrimary),
          ),
          const Text('2026 · Você', style: TextStyle(fontSize: 10, color: _kTextTertiary)),
        ],
      ),
    );
  }

  // Últimos Acessos
  Widget _recentSection() {
    if (_registros.isEmpty) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: _kCard,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: _kBorder),
          ),
          child: const Row(
            children: [
              Icon(Icons.history, color: _kTextTertiary, size: 20),
              SizedBox(width: 10),
              Text(
                'Nenhum registro ainda.',
                style: TextStyle(fontSize: 13, color: _kTextSecondary),
              ),
            ],
          ),
        ),
      );
    }

    final recentes = _registros.take(3).toList();
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Container(
        decoration: BoxDecoration(
          color: _kCard,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _kBorder),
        ),
        child: Column(
          children: recentes.asMap().entries.map((e) {
            final isLast = e.key == recentes.length - 1;
            return Column(
              children: [
                _recentItem(e.value),
                if (!isLast)
                  const Divider(height: 1, indent: 16, endIndent: 16, color: _kBorder),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _recentItem(Registro r) {
    const moodEmoji = ['😊', '😄', '😐', '😢', '😍'];
    final dataFmt   = _formatDate(r.dataHora);
    final temFoto   = r.fotos.isNotEmpty && File(r.fotos.first).existsSync();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        children: [
          Container(
            width: 42, height: 42,
            decoration: BoxDecoration(
              color: temFoto ? Colors.transparent : _kGreenLight,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: _kBorder),
            ),
            child: temFoto
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.file(
                      File(r.fotos.first),
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) =>
                          const Icon(Icons.broken_image_outlined, size: 20, color: _kTextTertiary),
                    ),
                  )
                : const Icon(Icons.camera_alt_outlined, size: 20, color: _kGreen),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  r.titulo,
                  style: const TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w600, color: _kTextPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  r.local.isNotEmpty ? '${r.local} · $dataFmt' : dataFmt,
                  style: const TextStyle(fontSize: 11, color: _kTextSecondary),
                ),
              ],
            ),
          ),
          const SizedBox(width: 6),
          Text(moodEmoji[r.humor.clamp(0, 4)], style: const TextStyle(fontSize: 16)),
        ],
      ),
    );
  }

  // Continuar Hoje
  Widget _continueTodaySection() {
    final hoje    = DateTime.now();
    final temHoje = _registros.any((r) {
      final dt = DateTime.tryParse(r.dataHora);
      return dt != null &&
          dt.year == hoje.year && dt.month == hoje.month && dt.day == hoje.day;
    });

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: GestureDetector(
        onTap: _goToNovoRegistro,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: _kGreen,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            children: [
              Container(
                width: 46, height: 46,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.camera_alt_outlined, color: Colors.white, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      temHoje ? 'Continuar o registro de hoje' : 'Adicionar registro diário',
                      style: const TextStyle(
                        color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      temHoje
                          ? 'Você já tem um registro hoje 🎉'
                          : 'Ainda não há entrada para hoje',
                      style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 11),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: Colors.white70, size: 20),
            ],
          ),
        ),
      ),
    );
  }

  // Estatísticas
  Widget _statisticsSection() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Container(
        decoration: BoxDecoration(
          color: _kCard,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _kBorder),
        ),
        child: Column(
          children: [
            _statRow('Registros', '$_totalRegistros', isFirst: true),
            _statRow('Sequência', '${_calcularSequencia()} dias'),
            _statRow('Estações completas', '4', valueColor: _kGreen),
            _statRow('Locais visitados', '${_locaisUnicos()}', isLast: true),
          ],
        ),
      ),
    );
  }

  Widget _statRow(
    String label,
    String value, {
    bool isFirst = false,
    bool isLast  = false,
    Color? valueColor,
  }) {
    return Column(
      children: [
        if (!isFirst)
          const Divider(height: 1, indent: 16, endIndent: 16, color: _kBorder),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label, style: const TextStyle(fontSize: 13, color: _kTextSecondary)),
              Text(
                value,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: valueColor ?? _kTextPrimary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ─── Bottom nav ────────────────────────────────────────────────────────────
  Widget _buildBottomNav() {
    return BottomAppBar(
      color: _kCard,
      elevation: 8,
      notchMargin: 6,
      shape: const CircularNotchedRectangle(),
      child: SizedBox(
        height: 56,
        child: Row(
          children: [
            _navItem(0, Icons.home_outlined,      'Home'),
            _navItem(1, Icons.timeline_outlined,  'Timeline'),
            const Expanded(child: SizedBox()),   // espaço central para o FAB
            _navItem(2, Icons.map_outlined,       'Mapa'),
            _navItem(3, Icons.show_chart_outlined,'Insights'),
          ],
        ),
      ),
    );
  }

  Widget _navItem(int index, IconData icon, String label) {
    final active = _navIndex == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _navIndex = index),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 22, color: active ? _kGreen : _kTextTertiary),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                color: active ? _kGreen : _kTextTertiary,
                fontWeight: active ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Helpers ───────────────────────────────────────────────────────────────
  String _formatDate(String iso) {
    final dt = DateTime.tryParse(iso);
    if (dt == null) return '';
    const m = ['Jan','Fev','Mar','Abr','Mai','Jun','Jul','Ago','Set','Out','Nov','Dez'];
    return '${dt.day} ${m[dt.month - 1]}';
  }

  int _calcularSequencia() {
    if (_registros.isEmpty) return 0;
    final dias = _registros
        .map((r) => DateTime.tryParse(r.dataHora))
        .whereType<DateTime>()
        .map((dt) => DateTime(dt.year, dt.month, dt.day))
        .toSet()
        .toList()
      ..sort((a, b) => b.compareTo(a));

    int seq = 1;
    for (int i = 1; i < dias.length; i++) {
      if (dias[i - 1].difference(dias[i]).inDays == 1) {
        seq++;
      } else {
        break;
      }
    }
    return seq;
  }

  int _locaisUnicos() => _registros
      .map((r) => r.local.trim().toLowerCase())
      .where((l) => l.isNotEmpty)
      .toSet()
      .length;
}

// ─── Modelo auxiliar ─────────────────────────────────────────────────────────
class _AlbumData {
  final String   name;
  final IconData icon;
  final bool     active;
  const _AlbumData(this.name, this.icon, this.active);
}
