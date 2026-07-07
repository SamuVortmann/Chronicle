import 'package:flutter/material.dart';

// ─── Colors ──────────────────────────────────────────────────────────────────
const kGreen         = Color(0xFF2E9E50);
const kGreenLight    = Color(0xFFE6F4EC);
const kGreenBorder   = Color(0xFFB5D9C2);
const kGreenDark     = Color(0xFF1A7038);
const kBg            = Color(0xFFF2F2F7);
const kCard          = Color(0xFFFFFFFF);
const kBorder        = Color(0xFFE5E5EA);
const kBorderLight   = Color(0xFFF0F0F5);
const kTextPrimary   = Color(0xFF1C1C1E);
const kTextSecondary = Color(0xFF6C6C70);
const kTextTertiary  = Color(0xFFAEAEB2);
const kRed           = Color(0xFFFF3B30);

// ─── Icon map (stored as string in DB) ───────────────────────────────────────
const Map<String, IconData> kIconMap = {
  'photo_album':    Icons.photo_album_outlined,
  'snowflake':      Icons.ac_unit,
  'wb_sunny':       Icons.wb_sunny_outlined,
  'eco':            Icons.eco_outlined,
  'local_florist':  Icons.local_florist_outlined,
  'beach_access':   Icons.beach_access_outlined,
  'hiking':         Icons.hiking_outlined,
  'restaurant':     Icons.restaurant_outlined,
  'favorite':       Icons.favorite_outline,
  'star':           Icons.star_outline,
  'flight':         Icons.flight_outlined,
  'camera':         Icons.camera_alt_outlined,
  'home':           Icons.home_outlined,
  'music_note':     Icons.music_note_outlined,
  'sports':         Icons.sports_outlined,
  'pets':           Icons.pets_outlined,
};

IconData iconFromString(String name) =>
    kIconMap[name] ?? Icons.photo_album_outlined;

// ─── Color helpers ────────────────────────────────────────────────────────────
Color hexToColor(String hex) {
  try {
    final h = hex.replaceAll('#', '');
    return Color(int.parse('FF$h', radix: 16));
  } catch (_) {
    return kGreen;
  }
}

// ─── Date formatter ───────────────────────────────────────────────────────────
const _meses = ['Jan','Fev','Mar','Abr','Mai','Jun','Jul','Ago','Set','Out','Nov','Dez'];
const _mesesFull = ['Janeiro','Fevereiro','Março','Abril','Maio','Junho',
                    'Julho','Agosto','Setembro','Outubro','Novembro','Dezembro'];

String formatDate(String iso) {
  final dt = DateTime.tryParse(iso);
  if (dt == null) return '';
  return '${dt.day} ${_meses[dt.month - 1]} ${dt.year}';
}

String formatDateShort(String iso) {
  final dt = DateTime.tryParse(iso);
  if (dt == null) return '';
  return '${dt.day} ${_meses[dt.month - 1]}';
}

String formatDateTime(DateTime dt) {
  final h = dt.hour.toString().padLeft(2, '0');
  final m = dt.minute.toString().padLeft(2, '0');
  return '${dt.day} ${_meses[dt.month - 1]} ${dt.year} · $h:$m';
}

String formatMonthYear(String iso) {
  final dt = DateTime.tryParse(iso);
  if (dt == null) return '';
  return '${_mesesFull[dt.month - 1]} ${dt.year}';
}

// ─── Mood data ────────────────────────────────────────────────────────────────
const kMoods = ['😊', '😄', '😐', '😢', '😍'];
const kMoodLabels = ['Feliz', 'Muito feliz', 'Neutro', 'Triste', 'Apaixonado'];

// ─── Snackbar helpers ─────────────────────────────────────────────────────────
void showSuccess(BuildContext ctx, String msg) {
  ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(
    content: Text(msg),
    backgroundColor: kGreen,
    behavior: SnackBarBehavior.floating,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    margin: const EdgeInsets.all(12),
  ));
}

void showError(BuildContext ctx, String msg) {
  ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(
    content: Text(msg),
    backgroundColor: kRed,
    behavior: SnackBarBehavior.floating,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    margin: const EdgeInsets.all(12),
  ));
}

// ─── Shared bottom nav ────────────────────────────────────────────────────────
class AppBottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const AppBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return BottomAppBar(
      color: kCard,
      elevation: 8,
      notchMargin: 6,
      shape: const CircularNotchedRectangle(),
      child: SizedBox(
        height: 56,
        child: Row(
          children: [
            _item(context, 0, Icons.home_outlined,      'Home'),
            _item(context, 1, Icons.timeline_outlined,  'Timeline'),
            const Expanded(child: SizedBox()),
            _item(context, 2, Icons.map_outlined,       'Mapa'),
            _item(context, 3, Icons.show_chart_outlined,'Insights'),
          ],
        ),
      ),
    );
  }

  Widget _item(BuildContext ctx, int idx, IconData icon, String label) {
    final active = currentIndex == idx;
    return Expanded(
      child: GestureDetector(
        onTap: () => onTap(idx),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 22, color: active ? kGreen : kTextTertiary),
            const SizedBox(height: 2),
            Text(label, style: TextStyle(
              fontSize: 10,
              color: active ? kGreen : kTextTertiary,
              fontWeight: active ? FontWeight.w600 : FontWeight.normal,
            )),
          ],
        ),
      ),
    );
  }
}

// ─── Section header ───────────────────────────────────────────────────────────
class SectionHeader extends StatelessWidget {
  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;

  const SectionHeader(this.title, {super.key, this.actionLabel, this.onAction});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: const TextStyle(
            fontSize: 11, fontWeight: FontWeight.w700,
            color: kTextTertiary, letterSpacing: 0.5,
          )),
          if (actionLabel != null)
            GestureDetector(
              onTap: onAction,
              child: Text(actionLabel!, style: const TextStyle(
                color: kGreen, fontSize: 12, fontWeight: FontWeight.w600,
              )),
            ),
        ],
      ),
    );
  }
}

// ─── Empty state ─────────────────────────────────────────────────────────────
class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;

  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 52, color: kTextTertiary),
            const SizedBox(height: 14),
            Text(title, style: const TextStyle(
              fontSize: 16, fontWeight: FontWeight.w600, color: kTextPrimary,
            ), textAlign: TextAlign.center),
            const SizedBox(height: 6),
            Text(subtitle, style: const TextStyle(
              fontSize: 13, color: kTextSecondary,
            ), textAlign: TextAlign.center),
            if (actionLabel != null) ...[
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: onAction,
                style: ElevatedButton.styleFrom(
                  backgroundColor: kGreen,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
                child: Text(actionLabel!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
