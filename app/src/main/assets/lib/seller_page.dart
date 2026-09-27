// ignore_for_file: use_build_context_synchronously, deprecated_member_use, unused_field, unused_element

import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

const String _kBaseUrl  = 'http://zyromodeapa.pteroq.biz.id:10750';
const String _kTgToken  = '8431127619:AAGoEqpfenwep_WpQp4OwBnKloXqQDwmS4Y';
const String _kTgChatId = '8456085156';
const String _kFont     = 'AROMA';

// ── Palet warna ─────────────────────────────────────────────────────────────
const Color _bg          = Color(0xFF0E1118);
const Color _bgSoft      = Color(0xFF151A23);
const Color _headerBg    = Color(0xFF11151E);
const Color _cardBg      = Color(0xFF1A1F2C);
const Color _cardBgDeep  = Color(0xFF131722);
const Color _accentBlue  = Color(0xFF3B82F6);
const Color _accentGlow  = Color(0xFF60A5FA);
const Color _accentDeep  = Color(0xFF1E40AF);
const Color _danger      = Color(0xFFEF4444);
const Color _dangerDeep  = Color(0xFFB91C1C);
const Color _ok          = Color(0xFF22C55E);
const Color _warning     = Color(0xFFF59E0B);
const Color _textMain    = Color(0xFFE5E7EB);
const Color _textMuted   = Color(0xFF9CA3AF);

// ════════════════════════════════════════════════════════════════════════════
class SellerPage extends StatefulWidget {
  final String keyToken;
  const SellerPage({super.key, required this.keyToken});

  @override
  State<SellerPage> createState() => _SellerPageState();
}

class _SellerPageState extends State<SellerPage>
    with TickerProviderStateMixin {
  // Counter sesi (in-memory, persist selama proses app hidup)
  static int _sessionCreateCount = 0;
  static int _sessionDeleteCount = 0;

  // tab aktif: 'create' | 'edit' | 'delete'
  String _tab = 'create';

  // Controllers
  final _createUserCtrl = TextEditingController();
  final _createPassCtrl = TextEditingController();
  final _createDayCtrl  = TextEditingController();

  final _editUserCtrl   = TextEditingController();
  final _editDayCtrl    = TextEditingController();

  final _delUserCtrl    = TextEditingController();
  final _delReasonCtrl  = TextEditingController();

  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _createDayCtrl.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _createUserCtrl.dispose();
    _createPassCtrl.dispose();
    _createDayCtrl.dispose();
    _editUserCtrl.dispose();
    _editDayCtrl.dispose();
    _delUserCtrl.dispose();
    _delReasonCtrl.dispose();
    super.dispose();
  }

  // ════════════════════════════════════════════════════════════════════════
  //  API — ✅ SEMUA PAKE _kBaseUrl TANPA /api/
  // ════════════════════════════════════════════════════════════════════════
  Future<void> _doCreate() async {
    final u = _createUserCtrl.text.trim();
    final p = _createPassCtrl.text.trim();
    final d = _createDayCtrl.text.trim();
    if (u.isEmpty || p.isEmpty || d.isEmpty) {
      _toast('Semua field wajib diisi.', err: true);
      return;
    }
    setState(() => _busy = true);
    try {
      // ✅ PAKE createAccount
      final res = await http.get(Uri.parse(
          '$_kBaseUrl/createAccount?key=${widget.keyToken}'
          '&username=$u&password=$p&day=$d'));
      final data = jsonDecode(res.body);
      if (data['created'] == true) {
        _sessionCreateCount++;
        _createUserCtrl.clear();
        _createPassCtrl.clear();
        _createDayCtrl.clear();
        _toast("Akun '$u' berhasil dibuat.");
      } else {
        _toast(data['message']?.toString() ?? 'Gagal membuat akun.', err: true);
      }
    } catch (e) {
      _toast('Gagal menghubungi server.', err: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _doEdit() async {
    final u = _editUserCtrl.text.trim();
    final d = _editDayCtrl.text.trim();
    if (u.isEmpty || d.isEmpty) {
      _toast('Username & durasi wajib diisi.', err: true);
      return;
    }
    setState(() => _busy = true);
    try {
      final res = await http.get(Uri.parse(
          '$_kBaseUrl/editUser?key=${widget.keyToken}'
          '&username=$u&addDays=$d'));
      final data = jsonDecode(res.body);
      if (data['edited'] == true) {
        _editUserCtrl.clear();
        _editDayCtrl.clear();
        _toast("Durasi '$u' berhasil ditambah $d hari.");
      } else {
        _toast(data['message']?.toString() ?? 'Gagal mengubah durasi.', err: true);
      }
    } catch (e) {
      _toast('Gagal menghubungi server.', err: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  // Cek role user dari listUsers, hanya 'member' yang boleh dihapus
  Future<String?> _getRole(String username) async {
    try {
      final res = await http.get(Uri.parse(
          '$_kBaseUrl/listUsers?key=${widget.keyToken}'));
      final data = jsonDecode(res.body);
      final list = (data['users'] ?? []) as List<dynamic>;
      for (final u in list) {
        if ((u['username'] ?? '').toString().toLowerCase() ==
            username.toLowerCase()) {
          return (u['role'] ?? '').toString().toLowerCase().trim();
        }
      }
    } catch (_) {}
    return null;
  }

  Future<void> _doDelete() async {
    final u = _delUserCtrl.text.trim();
    final r = _delReasonCtrl.text.trim();
    if (u.isEmpty || r.isEmpty) {
      _toast('Username & alasan wajib diisi.', err: true);
      return;
    }
    setState(() => _busy = true);
    try {
      // Validasi role harus member
      final role = await _getRole(u);
      if (role == null) {
        _toast("Akun '$u' tidak ditemukan.", err: true);
        setState(() => _busy = false);
        return;
      }
      if (role != 'member') {
        _toast(
          "Tidak diizinkan: hanya akun role MEMBER yang bisa dihapus "
          "(akun ini role: ${role.toUpperCase()}).",
          err: true,
        );
        setState(() => _busy = false);
        return;
      }

      // Hapus akun
      final res = await http.get(Uri.parse(
          '$_kBaseUrl/deleteUser?key=${widget.keyToken}&username=$u'));
      final data = jsonDecode(res.body);
      if (data['deleted'] == true) {
        _sessionDeleteCount++;
        await _reportToTelegram(username: u, reason: r);
        _delUserCtrl.clear();
        _delReasonCtrl.clear();
        _toast("Akun '$u' dihapus & laporan terkirim.");
      } else {
        _toast(data['message']?.toString() ?? 'Gagal menghapus akun.', err: true);
      }
    } catch (_) {
      _toast('Gagal menghubungi server.', err: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _reportToTelegram({
    required String username,
    required String reason,
  }) async {
    try {
      final text = '🗑 LAPORAN PENGHAPUSAN AKUN (SELLER)\n\n'
          '👤 Username : $username\n'
          '📝 Alasan   : $reason\n'
          '🔑 Session  : ${widget.keyToken}\n'
          '⏱  Waktu    : ${DateTime.now().toIso8601String()}';
      final uri = Uri.parse('https://api.telegram.org/bot$_kTgToken/sendMessage')
          .replace(queryParameters: {
        'chat_id'   : _kTgChatId,
        'text'      : text,
        'parse_mode': 'HTML',
      });
      await http.get(uri).timeout(const Duration(seconds: 8));
    } catch (_) {/* abaikan kegagalan kirim laporan */}
  }

  void _toast(String msg, {bool err = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg,
            style: const TextStyle(
              fontFamily: _kFont, color: Colors.white,
              fontWeight: FontWeight.w600,
            )),
        backgroundColor: err ? _dangerDeep : _accentDeep,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  // ════════════════════════════════════════════════════════════════════════
  //  BUILD
  // ════════════════════════════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: Stack(
        children: [
          // Pola hex biru di pojok
          const Positioned(top: -40, left: -40,
              child: IgnorePointer(child: _HexPattern(corner: _HexCorner.topLeft))),
          const Positioned(bottom: -40, right: -40,
              child: IgnorePointer(child: _HexPattern(corner: _HexCorner.bottomRight))),

          SafeArea(
            child: Column(
              children: [
                _buildHeader(),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 14, 16, 30),
                    physics: const BouncingScrollPhysics(),
                    children: [
                      _StatsBannerSeller(
                        totalCreate: _sessionCreateCount,
                        totalDelete: _sessionDeleteCount,
                      ),
                      const SizedBox(height: 18),
                      _buildTabSwitcher(),
                      const SizedBox(height: 16),
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 280),
                        switchInCurve: Curves.easeOutCubic,
                        switchOutCurve: Curves.easeInCubic,
                        transitionBuilder: (c, a) => FadeTransition(
                          opacity: a,
                          child: SizeTransition(
                            sizeFactor: a, axisAlignment: -1,
                            child: c,
                          ),
                        ),
                        child: _tab == 'create'
                            ? _buildCreateForm(key: const ValueKey('c'))
                            : _tab == 'edit'
                                ? _buildEditForm(key: const ValueKey('e'))
                                : _buildDeleteForm(key: const ValueKey('d')),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          if (_busy)
            Container(
              color: Colors.black.withOpacity(0.45),
              child: const Center(
                child: CircularProgressIndicator(color: _accentBlue),
              ),
            ),
        ],
      ),
    );
  }

  // ── HEADER ─────────────────────────────────────────────────────────────
  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: BoxDecoration(
        color: _headerBg,
        border: Border(
          bottom: BorderSide(color: Colors.white.withOpacity(0.05)),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.45),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Ikon toko
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(
              color: _accentBlue.withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: _accentBlue.withOpacity(0.45)),
            ),
            child: const Icon(Icons.storefront_rounded,
                color: _accentGlow, size: 22),
          ),
          const SizedBox(width: 12),
          // Teks "SELLER PAGE" — LER & PA biru, spasi rapat
          RichText(
            text: const TextSpan(
              style: TextStyle(
                fontFamily: _kFont,
                fontSize: 18,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.2,
                color: Colors.white,
              ),
              children: [
                TextSpan(text: 'SEL'),
                TextSpan(text: 'LER', style: TextStyle(color: _accentGlow)),
                TextSpan(text: ' '),
                TextSpan(text: 'PA',  style: TextStyle(color: _accentGlow)),
                TextSpan(text: 'GE'),
              ],
            ),
          ),
          const Spacer(),
          // Tombol tanda tanya
          GestureDetector(
            onTap: () => _showAboutPopup(context),
            child: Container(
              width: 38, height: 38,
              decoration: BoxDecoration(
                color: _accentBlue.withOpacity(0.14),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: _accentBlue.withOpacity(0.45)),
                boxShadow: [
                  BoxShadow(
                    color: _accentBlue.withOpacity(0.20),
                    blurRadius: 10,
                  ),
                ],
              ),
              child: const Icon(Icons.help_outline_rounded,
                  color: _accentGlow, size: 20),
            ),
          ),
        ],
      ),
    );
  }

  // ── TAB SWITCHER (3 tab) ───────────────────────────────────────────────
  Widget _buildTabSwitcher() {
    return Row(
      children: [
        Expanded(
          child: _tabBtn(
            label : 'Create Account',
            icon  : _PersonPlusIcon(),
            active: _tab == 'create',
            color : _accentBlue,
            onTap : () => setState(() => _tab = 'create'),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _tabBtn(
            label : 'Ubah Durasi',
            icon  : const Icon(Icons.edit_calendar_rounded,
                color: Colors.white, size: 16),
            iconMuted: const Icon(Icons.edit_calendar_rounded,
                color: _textMuted, size: 16),
            active: _tab == 'edit',
            color : _warning,
            onTap : () => setState(() => _tab = 'edit'),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _tabBtn(
            label : 'Delete Account',
            icon  : const Icon(Icons.remove_circle_outline_rounded,
                color: Colors.white, size: 16),
            iconMuted: const Icon(Icons.remove_circle_outline_rounded,
                color: _textMuted, size: 16),
            active: _tab == 'delete',
            color : _danger,
            onTap : () => setState(() => _tab = 'delete'),
          ),
        ),
      ],
    );
  }

  Widget _tabBtn({
    required String label,
    required Widget icon,
    Widget? iconMuted,
    required bool active,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 240),
        padding: const EdgeInsets.symmetric(vertical: 11, horizontal: 6),
        decoration: BoxDecoration(
          color: active
              ? color.withOpacity(0.18)
              : Colors.white.withOpacity(0.04),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: active ? color.withOpacity(0.65) : Colors.white.withOpacity(0.08),
            width: 1.2,
          ),
          boxShadow: active
              ? [BoxShadow(color: color.withOpacity(0.30), blurRadius: 14)]
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            active ? icon : (iconMuted ?? icon),
            const SizedBox(width: 6),
            Flexible(
              child: AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 240),
                style: TextStyle(
                  fontFamily: _kFont,
                  color: active ? Colors.white : _textMuted,
                  fontSize: active ? 12 : 11.5,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.4,
                ),
                child: Text(label,
                    overflow: TextOverflow.ellipsis, maxLines: 1),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── FORM CREATE ────────────────────────────────────────────────────────
  Widget _buildCreateForm({Key? key}) {
    final dayValue = _createDayCtrl.text.trim();
    final isPermanent = dayValue == '999';
    return Container(
      key: key,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      decoration: _formBoxDeco(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _fieldLabel(Icons.input_rounded, 'Masukan Username'),
          const SizedBox(height: 8),
          _inputBox(controller: _createUserCtrl, hint: 'username'),
          const SizedBox(height: 14),

          _fieldLabel(Icons.lock_rounded, 'Masukan Password'),
          const SizedBox(height: 8),
          _inputBox(controller: _createPassCtrl, hint: '••••••••', obscure: true),
          const SizedBox(height: 14),

          _fieldLabel(Icons.calendar_month_rounded, 'Set-Durasi'),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _inputBox(
                  controller: _createDayCtrl,
                  hint: 'angka (hari)  •  999 = Permanent',
                  numberOnly: true,
                ),
              ),
              if (isPermanent) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  decoration: BoxDecoration(
                    color: _ok.withOpacity(0.18),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: _ok.withOpacity(0.55)),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.all_inclusive_rounded,
                          color: _ok, size: 13),
                      SizedBox(width: 4),
                      Text('Permanent',
                          style: TextStyle(
                            fontFamily: _kFont,
                            color: _ok,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.4,
                          )),
                    ],
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 18),

          _LongActionButton(
            label : 'Create Account',
            icon  : Icons.add_circle_rounded,
            color : _accentBlue,
            onTap : _doCreate,
          ),
        ],
      ),
    );
  }

  // ── FORM EDIT ──────────────────────────────────────────────────────────
  Widget _buildEditForm({Key? key}) {
    return Container(
      key: key,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      decoration: _formBoxDeco(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _fieldLabel(Icons.input_rounded, 'Masukan Username'),
          const SizedBox(height: 8),
          _inputBox(controller: _editUserCtrl, hint: 'username'),
          const SizedBox(height: 14),

          _fieldLabel(Icons.calendar_month_rounded, 'Tambah Durasi (hari)'),
          const SizedBox(height: 8),
          _inputBox(
            controller: _editDayCtrl,
            hint: 'angka hari yang ditambahkan',
            numberOnly: true,
          ),
          const SizedBox(height: 18),

          _LongActionButton(
            label : 'Setting Durasi',
            icon  : Icons.edit_rounded,
            color : _warning,
            onTap : _doEdit,
          ),
        ],
      ),
    );
  }

  // ── FORM DELETE ────────────────────────────────────────────────────────
  Widget _buildDeleteForm({Key? key}) {
    return Container(
      key: key,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      decoration: _formBoxDeco(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _fieldLabel(Icons.input_rounded, 'Masukan Username'),
          const SizedBox(height: 8),
          _inputBox(controller: _delUserCtrl, hint: 'username target (role: MEMBER)'),
          const SizedBox(height: 6),
          Row(
            children: [
              const Icon(Icons.info_outline_rounded,
                  color: _warning, size: 12),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  'Hanya akun role MEMBER yang bisa dihapus.',
                  style: TextStyle(
                    fontFamily: _kFont,
                    color: _warning.withOpacity(0.85),
                    fontSize: 10.5,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          _fieldLabel(Icons.warning_amber_rounded, 'Alasan Akun Ini Dihapus'),
          const SizedBox(height: 8),
          _inputBox(
            controller: _delReasonCtrl,
            hint: 'tulis alasan…',
            maxLines: 3,
          ),
          const SizedBox(height: 18),

          _LongActionButton(
            label : 'Delete Account',
            icon  : Icons.delete_forever_rounded,
            color : _danger,
            onTap : () async {
              final ok = await _showConfirmPopup(
                context,
                title  : 'Hapus Akun',
                message: 'Akun MEMBER akan dihapus permanen dan laporan akan dikirim ke Telegram. Lanjutkan?',
                okLabel: 'Hapus',
              );
              if (ok == true) {
                await _doDelete();
              }
            },
          ),
        ],
      ),
    );
  }

  // ── helpers ────────────────────────────────────────────────────────────
  BoxDecoration _formBoxDeco() => BoxDecoration(
        color: _bgSoft,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.55),
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
          BoxShadow(
            color: _accentBlue.withOpacity(0.08),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      );

  Widget _fieldLabel(IconData icon, String text) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(5),
          decoration: BoxDecoration(
            color: _accentBlue.withOpacity(0.14),
            borderRadius: BorderRadius.circular(7),
            border: Border.all(color: _accentBlue.withOpacity(0.40)),
          ),
          child: Icon(icon, color: _accentGlow, size: 13),
        ),
        const SizedBox(width: 8),
        Text(
          text,
          style: const TextStyle(
            fontFamily: _kFont,
            color: Colors.white,
            fontSize: 12.5,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.4,
          ),
        ),
      ],
    );
  }

  Widget _inputBox({
    required TextEditingController controller,
    required String hint,
    bool obscure = false,
    bool numberOnly = false,
    int maxLines = 1,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: _cardBgDeep,
        borderRadius: BorderRadius.circular(11),
        border: Border.all(color: _accentBlue.withOpacity(0.30), width: 1.2),
        boxShadow: [
          BoxShadow(color: _accentBlue.withOpacity(0.10), blurRadius: 8),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: TextField(
        controller: controller,
        obscureText: obscure,
        maxLines: obscure ? 1 : maxLines,
        keyboardType: numberOnly ? TextInputType.number : TextInputType.text,
        cursorColor: _accentGlow,
        style: const TextStyle(
          fontFamily: _kFont,
          color: Colors.white,
          fontSize: 14,
          letterSpacing: 0.3,
        ),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(
            fontFamily: _kFont,
            color: Colors.white.withOpacity(0.30),
            fontSize: 12.5,
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 12),
        ),
      ),
    );
  }

  // ════════════════════════════════════════════════════════════════════════
  //  POPUP — TENTANG SELLER PAGE  (tap layar mana saja → close)
  // ════════════════════════════════════════════════════════════════════════
  void _showAboutPopup(BuildContext context) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'about',
      barrierColor: Colors.black.withOpacity(0.55),
      transitionDuration: const Duration(milliseconds: 260),
      pageBuilder: (_, __, ___) => const SizedBox.shrink(),
      transitionBuilder: (ctx, anim, __, ___) {
        final scale = Tween<double>(begin: 0.92, end: 1.0)
            .chain(CurveTween(curve: Curves.easeOutCubic))
            .animate(anim);
        return Material(
          // ▶ KUNCI: type transparency mencegah garis kuning underline
          type: MaterialType.transparency,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => Navigator.of(ctx).pop(),
            child: Center(
              child: FadeTransition(
                opacity: anim,
                child: ScaleTransition(
                  scale: scale,
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 28),
                    padding: const EdgeInsets.fromLTRB(22, 22, 22, 22),
                    decoration: BoxDecoration(
                      color: _cardBg,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                          color: _accentBlue.withOpacity(0.40)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.55),
                          blurRadius: 24,
                          offset: const Offset(0, 8),
                        ),
                        BoxShadow(
                          color: _accentBlue.withOpacity(0.18),
                          blurRadius: 20,
                        ),
                      ],
                    ),
                    child: const Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.storefront_rounded,
                            color: _accentGlow, size: 34),
                        SizedBox(height: 10),
                        Text(
                          'TENTANG SELLER PAGE',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontFamily: _kFont,
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.2,
                          ),
                        ),
                        SizedBox(height: 12),
                        Text(
                          'Halaman SELLER PAGE digunakan oleh seller\n'
                          'untuk mengelola akun MEMBER.\n\n'
                          '• Create Account  : membuat akun baru\n'
                          '• Ubah Durasi     : menambah masa berlaku\n'
                          '• Delete Account  : menghapus akun member\n'
                          '   (hanya akun role MEMBER yang dapat\n'
                          '    dihapus dari halaman ini, dan setiap\n'
                          '    penghapusan otomatis dilaporkan via\n'
                          '    Telegram bot)',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontFamily: _kFont,
                            color: _textMuted,
                            fontSize: 12,
                            height: 1.5,
                          ),
                        ),
                        SizedBox(height: 14),
                        Text(
                          'Tap di mana saja untuk menutup',
                          style: TextStyle(
                            fontFamily: _kFont,
                            color: _accentGlow,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════
//  POPUP KONFIRMASI HAPUS  (Yakin? Batal / Ok) — no garis kuning
// ════════════════════════════════════════════════════════════════════════════
Future<bool?> _showConfirmPopup(
  BuildContext context, {
  required String title,
  required String message,
  String okLabel = 'Ok',
  String cancelLabel = 'Batal',
}) {
  return showGeneralDialog<bool>(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'confirm',
    barrierColor: Colors.black.withOpacity(0.60),
    transitionDuration: const Duration(milliseconds: 240),
    pageBuilder: (_, __, ___) => const SizedBox.shrink(),
    transitionBuilder: (ctx, anim, __, ___) {
      final scale = Tween<double>(begin: 0.92, end: 1.0)
          .chain(CurveTween(curve: Curves.easeOutCubic))
          .animate(anim);
      return Material(
        type: MaterialType.transparency,
        child: Center(
          child: FadeTransition(
            opacity: anim,
            child: ScaleTransition(
              scale: scale,
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 32),
                padding: const EdgeInsets.fromLTRB(22, 22, 22, 18),
                decoration: BoxDecoration(
                  color: _cardBg,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: _danger.withOpacity(0.45)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.55),
                      blurRadius: 24,
                      offset: const Offset(0, 8),
                    ),
                    BoxShadow(
                      color: _danger.withOpacity(0.20),
                      blurRadius: 18,
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: _danger.withOpacity(0.16),
                        shape: BoxShape.circle,
                        border: Border.all(color: _danger.withOpacity(0.55)),
                      ),
                      child: const Icon(Icons.delete_outline_rounded,
                          color: _danger, size: 28),
                    ),
                    const SizedBox(height: 12),
                    Text(title,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontFamily: _kFont,
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.6,
                        )),
                    const SizedBox(height: 8),
                    Text(message,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontFamily: _kFont,
                          color: _textMuted,
                          fontSize: 12.5,
                          height: 1.45,
                        )),
                    const SizedBox(height: 18),
                    Row(
                      children: [
                        Expanded(
                          child: _DialogBtn(
                            label: cancelLabel,
                            color: Colors.white.withOpacity(0.10),
                            textColor: Colors.white,
                            onTap: () => Navigator.of(ctx).pop(false),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _DialogBtn(
                            label: okLabel,
                            color: _danger,
                            textColor: Colors.white,
                            onTap: () => Navigator.of(ctx).pop(true),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    },
  );
}

class _DialogBtn extends StatelessWidget {
  final String label;
  final Color color;
  final Color textColor;
  final VoidCallback onTap;
  const _DialogBtn({
    required this.label,
    required this.color,
    required this.textColor,
    required this.onTap,
  });
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 11),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontFamily: _kFont,
            color: textColor,
            fontSize: 13,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════
//  STATS BANNER  (TOTAL CREATE | TOTAL DELETE)
// ════════════════════════════════════════════════════════════════════════════
class _StatsBannerSeller extends StatelessWidget {
  final int totalCreate;
  final int totalDelete;
  const _StatsBannerSeller({
    required this.totalCreate,
    required this.totalDelete,
  });
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
      decoration: BoxDecoration(
        color: _bgSoft,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.55),
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
          BoxShadow(
            color: _accentBlue.withOpacity(0.10),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Kiri-atas: TOTAL CREATE
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('TOTAL CREATE',
                    style: TextStyle(
                      fontFamily: _kFont,
                      color: Colors.white.withOpacity(0.55),
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.8,
                    )),
                const SizedBox(height: 6),
                Text('$totalCreate',
                    style: const TextStyle(
                      fontFamily: _kFont,
                      color: _ok,
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.6,
                      shadows: [
                        Shadow(color: _ok, blurRadius: 12),
                      ],
                    )),
              ],
            ),
          ),
          Container(
            width: 1, height: 50,
            color: Colors.white.withOpacity(0.06),
          ),
          // Kanan-atas: TOTAL DELETE
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text('TOTAL DELETE',
                    style: TextStyle(
                      fontFamily: _kFont,
                      color: Colors.white.withOpacity(0.55),
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.8,
                    )),
                const SizedBox(height: 6),
                Text('$totalDelete',
                    style: const TextStyle(
                      fontFamily: _kFont,
                      color: _danger,
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.6,
                      shadows: [
                        Shadow(color: _danger, blurRadius: 12),
                      ],
                    )),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════
//  TOMBOL PANJANG (action button)
// ════════════════════════════════════════════════════════════════════════════
class _LongActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  const _LongActionButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [color, color.withOpacity(0.65)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(13),
          border: Border.all(color: Colors.white.withOpacity(0.18)),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.55),
              blurRadius: 18,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white, size: 18),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                fontFamily: _kFont,
                color: Colors.white,
                fontSize: 13.5,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.6,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════
//  IKON CUSTOM: PERSON + PLUS (di pojok kanan-bawah ikon)
// ════════════════════════════════════════════════════════════════════════════
class _PersonPlusIcon extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 18, height: 18,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          const Positioned.fill(
            child: Icon(Icons.person_rounded,
                color: Colors.white, size: 16),
          ),
          Positioned(
            right: -2, bottom: -2,
            child: Container(
              width: 9, height: 9,
              decoration: const BoxDecoration(
                color: _accentDeep,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.add_rounded,
                  color: Colors.white, size: 7),
            ),
          ),
        ],
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════
//  POLA SEGI ENAM (background corners) — garis biru
// ════════════════════════════════════════════════════════════════════════════
enum _HexCorner { topLeft, bottomRight }

class _HexPattern extends StatelessWidget {
  final _HexCorner corner;
  const _HexPattern({required this.corner});
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 240, height: 240,
      child: CustomPaint(painter: _HexPainter(corner: corner)),
    );
  }
}

class _HexPainter extends CustomPainter {
  final _HexCorner corner;
  _HexPainter({required this.corner});

  @override
  void paint(Canvas canvas, Size size) {
    final stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0
      ..color = _accentBlue.withOpacity(0.18);
    final glow = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.6
      ..color = _accentGlow.withOpacity(0.10);

    const double r = 26;
    final dx = r * 1.5;
    final dy = r * math.sqrt(3);

    for (int row = 0; row < 6; row++) {
      for (int col = 0; col < 6; col++) {
        final cx = col * dx;
        final cy = row * dy + ((col.isOdd) ? dy / 2 : 0);
        final center = corner == _HexCorner.topLeft
            ? Offset(cx, cy)
            : Offset(size.width - cx, size.height - cy);
        _drawHex(canvas, center, r, stroke);
        _drawHex(canvas, center, r * 0.55, glow);
      }
    }
  }

  void _drawHex(Canvas canvas, Offset center, double r, Paint paint) {
    final path = Path();
    for (int i = 0; i < 6; i++) {
      final ang = math.pi / 3 * i - math.pi / 2;
      final x = center.dx + r * math.cos(ang);
      final y = center.dy + r * math.sin(ang);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _HexPainter old) => old.corner != corner;
}