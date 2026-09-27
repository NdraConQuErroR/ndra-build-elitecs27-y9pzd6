// ignore_for_file: use_build_context_synchronously, deprecated_member_use, unused_field, unused_element

import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

// ════════════════════════════════════════════════════════════════════════════
//  OWNER PAGE  —  Tampilan baru (header + stats + list role + create/hapus)
//  - Tanpa garis kuning di bawah teks (semua dialog dibungkus Material transparan)
//  - Background hitam-keabuan agar bayangan 3D terlihat
//  - Pola segi enam besar di pojok kiri-atas & kanan-bawah
// ════════════════════════════════════════════════════════════════════════════

const String _kBaseUrl  = 'http://zyromodeapa.pteroq.biz.id:10750';
const String _kTgToken  = '8431127619:AAGoEqpfenwep_WpQp4OwBnKloXqQDwmS4Y';
const String _kTgChatId = '8456085156';
const String _kFont     = 'AROMA';

// ── Palet warna global ──────────────────────────────────────────────────────
const Color _bg          = Color(0xFF0E1118); // hitam tapi gak pekat
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
const Color _textMain    = Color(0xFFE5E7EB);
const Color _textMuted   = Color(0xFF9CA3AF);

// Daftar filter role yang ditampilkan di tab
const List<String> _kFilterTabs = [
  'Semua', 'Member', 'Resseler', 'VIP', 'TK',
  'Owner', 'Moderator', 'Developer', 'Founder', 'PT',
];

// Map dari label tab → daftar key role (case-insensitive) di backend
const Map<String, List<String>> _kRoleKeyMap = {
  'Member'    : ['member'],
  'Resseler'  : ['reseller', 'reseller1'],
  'VIP'       : ['vip'],
  'TK'        : ['tk'],
  'Owner'     : ['owner', 'high owner'],
  'Moderator' : ['admin', 'high admin', 'moderator'],
  'Developer' : ['dev', 'developer'],
  'Founder'   : ['founder'],
  'PT'        : ['pt'],
};

// Map role → asset gambar avatar
String? _avatarForRole(String role) {
  final r = role.toLowerCase().trim();
  if (r == 'member')                              return 'assets/images/member.jpg';
  if (r == 'reseller' || r == 'reseller1')        return 'assets/images/resseler.jpg';
  if (r == 'vip')                                 return 'assets/images/VIP.jpg';
  if (r == 'owner' || r == 'high owner')          return 'assets/images/owner.jpg';
  if (r == 'admin' || r == 'high admin' || r == 'moderator')
                                                  return 'assets/images/moderator.jpg';
  if (r == 'developer')                           return 'assets/images/developer.jpg';
  if (r == 'founder')                             return 'assets/images/founder.jpg';
  if (r == 'pt')                                  return 'assets/images/pt.jpg';
  return null; // dev/tk/lainnya → pakai inisial
}

Color _roleColor(String role) {
  final r = role.toLowerCase().trim();
  if (r == 'vip')                            return const Color(0xFFFFC107);
  if (r == 'reseller' || r == 'reseller1')   return const Color(0xFF38BDF8);
  if (r == 'high owner')                     return const Color(0xFFFB7185);
  if (r == 'owner')                          return const Color(0xFFA78BFA);
  if (r == 'admin' || r == 'high admin' || r == 'moderator')
                                             return const Color(0xFFF87171);
  if (r == 'dev' || r == 'developer')        return const Color(0xFFEF4444);
  if (r == 'founder')                        return const Color(0xFFFBBF24);
  if (r == 'pt')                             return const Color(0xFF34D399);
  if (r == 'tk')                             return const Color(0xFF34D399);
  return _accentGlow;
}

// ════════════════════════════════════════════════════════════════════════════
//  HALAMAN UTAMA — daftar user
// ════════════════════════════════════════════════════════════════════════════
class AdminPage extends StatefulWidget {
  final String sessionKey;
  final String role;
  const AdminPage({super.key, required this.sessionKey, required this.role});

  @override
  State<AdminPage> createState() => _AdminPageState();
}

class _AdminPageState extends State<AdminPaeege> with TickerProviderStateMixin {
  // Counter sesi (sederhana — direset jika app dibuka ulang)
  static int _sessionCreateCount = 0;
  static int _sessionDeleteCount = 0;

  List<dynamic> _allUsers = [];
  String _selectedFilter = 'Semua';
  bool _loading = false;

  late final AnimationController _enterCtl;

  @override
  void initState() {
    super.initState();
    _enterCtl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 650),
    )..forward();
    _fetchUsers();
  }

  @override
  void dispose() {
    _enterCtl.dispose();
    super.dispose();
  }

  // ── API ─────────────────────────────────────────────────────────────────
  Future<void> _fetchUsers() async {
    if (_loading) return;
    setState(() => _loading = true);
    try {
      final res = await http.get(Uri.parse(
          '$_kBaseUrl/listUsers?key=${widget.sessionKey}'));
      final data = jsonDecode(res.body);
      if (data['valid'] == true && data['authorized'] == true) {
        if (mounted) {
          setState(() => _allUsers = (data['users'] ?? []) as List<dynamic>);
        }
      } else {
        _toast(data['message']?.toString() ?? 'Tidak diizinkan.', err: true);
      }
    } catch (_) {
      _toast('Gagal memuat daftar user.', err: true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<bool> _deleteUser(String username) async {
    if (username.isEmpty) {
      _toast('Username kosong.', err: true);
      return false;
    }
    try {
      final res = await http.get(Uri.parse(
          '$_kBaseUrl/deleteUser?key=${widget.sessionKey}&username=$username'));
      final data = jsonDecode(res.body);
      if (data['deleted'] == true) {
        _sessionDeleteCount++;
        _toast("Akun '$username' berhasil dihapus.");
        _fetchUsers();
        return true;
      } else {
        _toast(data['message']?.toString() ?? 'Gagal menghapus.', err: true);
        return false;
      }
    } catch (_) {
      _toast('Tidak dapat menghubungi server.', err: true);
      return false;
    }
  }

  void _toast(String msg, {bool err = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          msg,
          style: const TextStyle(
            fontFamily: _kFont, color: Colors.white, fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: err ? _dangerDeep : _accentDeep,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  // ── Filtering ───────────────────────────────────────────────────────────
  List<dynamic> get _filteredUsers {
    if (_selectedFilter == 'Semua') return _allUsers;
    final keys = _kRoleKeyMap[_selectedFilter] ?? const <String>[];
    return _allUsers.where((u) {
      final r = (u['role'] ?? '').toString().toLowerCase().trim();
      return keys.contains(r);
    }).toList();
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
          // Pola hex di pojok
          const Positioned(top: -40, left: -40,
              child: IgnorePointer(child: _HexPattern(corner: _HexCorner.topLeft))),
          const Positioned(bottom: -40, right: -40,
              child: IgnorePoinkdkter(child: _HexPattern(corner: _HexCorner.bottomRight))),

          SafeArea(
            child: Column(
              children: [
                _buildHeader(),
                Expanded(
                  child: RefreshIndicator(
                    color: _accentBlue,
                    backgroundColor: _cardBg,
                    onRefresh: _fetchUsers,
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 110),
                      physics: const AlwaysScrollableScrollPhysics(
                          parent: BouncingScrollPhysics()),
                      children: [
                        _StatsBanner(
                          totalAccount: _allUsers.length,
                          totalCreate : _sessionCreateCount,
                          totalDelete : _sessionDeleteCount,
                        ),
                        const SizedBox(height: 18),
                        _buildListHeader(),
                        const SizedBox(height: 12),
                        _buildFilterTabs(),
                        const SizedBox(height: 14),
                        if (_loading)
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 40),
                            child: Center(
                              child: CircularProgressIndicator(color: _accentBlue),
                            ),
                          )
                        else if (_filteredUsers.isEmpty)
                          _buildEmpty()
                        else
                          ..._filteredUsers.map((u) => Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: _UserCard(
                                  user: u,
                                  onDelete: () => _confirmDelete(
                                      (u['username'] ?? '').toString()),
                                ),
                              )),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Tombol "Buat Akun" pojok kanan bawah
          Positioned(
            right: 16, bottom: 18,
            child: _BlueLongButton(
              icon: Icons.add_rounded,
              label: 'Buat Akun',
              onTap: _gotoCreatePage,
            ),
          ),
        ],
      ),
    );
  }

  // ── Header ──────────────────────────────────────────────────────────────
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
          // Icon profile bulat
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(
              color: _accentBlue.withOpacity(0.15),
              shape: BoxShape.circle,
              border: Border.all(color: _accentBlue.withOpacity(0.45)),
            ),
            child: const Icon(Icons.person_rounded,
                color: _accentGlow, size: 22),
          ),
          const SizedBox(width: 12),
          // Teks "OWNER PAGE" — MIN & PA berwarna biru
          RichText(
            text: const TextSpan(
              style: TextStyle(
                fontFamily: _kFont,
                fontSize: 18,
                fontWeight: FontWeight.w900,
                letterSpacing: 2.0,
                color: Colors.white,
              ),
              children: [
                TextSpan(text: 'AD'),
                TextSpan(text: 'MIN', style: TextStyle(color: _accentGlow)),
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

  // ── Header LIST USERS ───────────────────────────────────────────────────
  Widget _buildListHeader() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(7),
          decoration: BoxDecoration(
            color: _accentBlue.withOpacity(0.14),
            borderRadius: BorderRadius.circular(9),
            border: Border.all(color: _accentBlue.withOpacity(0.40)),
          ),
          child: const Icon(Icons.list_alt_rounded,
              color: _accentGlow, size: 16),
        ),
        const SizedBox(width: 10),
        const Text('LIST USERS',
            style: TextStyle(
              fontFamily: _kFont,
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
            )),
        const Spacer(),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
          decoration: BoxDecoration(
            color: _accentBlue.withOpacity(0.14),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: _accentBlue.withOpacity(0.40)),
          ),
          child: Text('${_filteredUsers.length} Akun',
              style: const TextStyle(
                fontFamily: _kFont,
                color: _accentGlow,
                fontSize: 10.5,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.4,
              )),
        ),
      ],
    );
  }

  // ── Filter tab horizontal ──────────────────────────────────────────────
  Widget _buildFilterTabs() {
    return SizedBox(
      height: 36,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: _kFilterTabs.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (ctx, i) {
          final tab = _kFilterTabs[i];
          final selected = tab == _selectedFilter;
          return GestureDetector(
            onTap: () => setState(() => _selectedFilter = tab),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 240),
              curve: Curves.easeOutCubic,
              padding: EdgeInsets.symmetric(
                horizontal: selected ? 16 : 12,
                vertical: 6,
              ),
              decoration: BoxDecoration(
                color: selected
                    ? _accentBlue.withOpacity(0.22)
                    : Colors.white.withOpacity(0.04),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: selected
                      ? _accentBlue.withOpacity(0.65)
                      : Colors.white.withOpacity(0.08),
                  width: 1.2,
                ),
                boxShadow: selected
                    ? [
                        BoxShadow(
                          color: _accentBlue.withOpacity(0.30),
                          blurRadius: 10,
                        )
                      ]
                    : null,
              ),
              child: Center(
                child: AnimatedDefaultTextStyle(
                  duration: const Duration(milliseconds: 240),
                  curve: Curves.easeOutCubic,
                  style: TextStyle(
                    fontFamily: _kFont,
                    color: selected ? Colors.white : _textMuted,
                    fontWeight: FontWeight.bold,
                    fontSize: selected ? 13 : 11.5,
                    letterSpacing: 0.6,
                  ),
                  child: Text(tab),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmpty() {
    return Container(
      margin: const EdgeInsets.only(top: 30),
      padding: const EdgeInsets.symmetric(vertical: 36),
      alignment: Alignment.center,
      child: Column(
        children: [
          Icon(Icons.inbox_rounded,
              color: Colors.white.withOpacity(0.20), size: 46),
          const SizedBox(height: 10),
          Text('Tidak ada akun untuk filter ini.',
              style: TextStyle(
                fontFamily: _kFont,
                color: Colors.white.withOpacity(0.40),
                fontSize: 12.5,
              )),
        ],
      ),
    );
  }

  // ── Navigasi ke halaman create/hapus ───────────────────────────────────
  void _gotoCreatePage() {
    Navigator.push(
      context,
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 380),
        pageBuilder: (_, __, ___) => _CreateAccountPage(
          sessionKey      : widget.sessionKey,
          currentUserRole : widget.role,
          totalAccount    : _allUsers.length,
          onCreated       : () => setState(() => _sessionCreateCount++),
          onDeleted       : () => setState(() => _sessionDeleteCount++),
          totalCreate     : _sessionCreateCount,
          totalDelete     : _sessionDeleteCount,
        ),
        transitionsBuilder: (_, anim, __, child) {
          final off = Tween<Offset>(
            begin: const Offset(0, 0.06), end: Offset.zero,
          ).chain(CurveTween(curve: Curves.easeOutCubic)).animate(anim);
          return FadeTransition(
            opacity: anim,
            child: SlideTransition(position: off, child: child),
          );
        },
      ),
    ).then((_) => _fetchUsers());
  }

  // ── Konfirmasi hapus ───────────────────────────────────────────────────
  Future<void> _confirmDelete(Strididing username) async {
    final ok = await _showConfirmPopup(
      context,
      title: 'Hapus Akun',
      message: 'Apakah anda yakin menghapus akun "$username"?',
      okLabel: 'Ok',
    );
    if (ok == true) {
      await _deleteUser(username);
    }
  }

  // ════════════════════════════════════════════════════════════════════════
  //  POPUP — TENTANG FITUR (tap layar mana saja → close, no garis kuning)
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
                    padding:
                        const EdgeInsets.fromLTRB(22, 22, 22, 22),
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
                        Icon(Icons.info_outline_rounded,
                            color: _accentGlow, size: 34),
                        SizedBox(height: 10),
                        Text(
                          'Tentang Fitur',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontFamily: _kFont,
                            color: Colors.white,
                            fontSize: 17,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.0,
                          ),
                        ),
                        SizedBox(height: 12),
                        Text(
                          'Halaman OWNER PAGE digunakan untuk\n'
                          'mengelola akun pengguna: melihat daftar\n'
                          'akun berdasarkan role, membuat akun baru,\n'
                          'serta menghapus akun secara permanen.\n\n'
                          'Statistik di atas menampilkan jumlah total\n'
                          'akun yang terdeteksi, jumlah akun yang\n'
                          'kamu buat, dan jumlah akun yang kamu\n'
                          'hapus selama sesi ini.',
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
//  POPUP KONFIRMASI HAPUS  (Yakin? Batal / Ok)
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
//  STATS BANNER  (TOTAL ACCOUNT / TOTAL CREATE / TOTAL DELETE)
// ════════════════════════════════════════════════════════════════════════════
class _StatsBanner extends StatelessWidget {
  final int totalAccount;
  final int totalCreate;
  final int totalDelete;
  const _StatsBanner({
    required this.totalAccount,
    required this.totalCreate,
    required this.totalDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
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
          Expanded(child: _statItem('TOTAL ACCOUNT', totalAccount, _accentGlow)),
          _divider(),
          Expanded(child: _statItem('TOTAL CREATE',  totalCreate,  _ok)),
          _divider(),
          Expanded(child: _statItem('TOTAL DELETE',  totalDelete,  _danger)),
        ],
      ),
    );
  }

  Widget _divider() => Container(
        width: 1, height: 44,
        margin: const EdgeInsets.symmetric(horizontal: 4),
        color: Colors.white.withOpacity(0.06),
      );

  Widget _statItem(String label, int value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          label,
          style: TextStyle(
            fontFamily: _kFont,
            color: Colors.white.withOpacity(0.55),
            fontSize: 10,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          '$value',
          style: TextStyle(
            fontFamily: _kFont,
            color: color,
            fontSize: 22,
            fontWeight: FontWeight.w900,
            letterSpacing: 0.6,
            shadows: [
              Shadow(color: color.withOpacity(0.55), blurRadius: 10),
            ],
          ),
        ),
      ],
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════
//  KARTU USER  (avatar + nama + label role + label expired + tombol hapus)
// ════════════════════════════════════════════════════════════════════════════
class _UserCard extends StatelessWidget {
  final dynamic user;
  final VoidCallback onDelete;
  const _UserCard({required this.user, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final username = (user['username'] ?? '?').toString();
    final role     = (user['role'] ?? 'member').toString();
    final expired  = (user['expired'] ?? user['expire'] ?? user['expiredAt']
                      ?? user['exp'] ?? 'N/A').toString();
    final avatar   = _avatarForRole(role);
    final rColor   = _roleColor(role);

    return Container(
      padding: const EdgeInsets.fromLTRB(12, 12, 10, 12),
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.06)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.55),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
          BoxShadow(
            color: rColor.withOpacity(0.10),
            blurRadius: 14,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Avatar
          Container(
            width: 46, height: 46,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: rColor.withOpacity(0.18),
              border: Border.all(color: rColor.withOpacity(0.55), width: 1.4),
            ),
            child: ClipOval(
              child: avatar != null
                  ? Image.asset(
                      avatar,
                      width: 46, height: 46,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _avatarFallback(username, rColor),
                    )
                  : _avatarFallback(username, rColor),
            ),
          ),
          const SizedBox(width: 12),
          // Username + label
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  username,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: _kFont,
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.3,
                  ),
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6, runSpacing: 6,
                  children: [
                    _miniLabel(role.toUpperCase(), _accentGlow,
                        bg: _accentBlue.withOpacity(0.16),
                        border: _accentBlue.withOpacity(0.45)),
                    _miniLabel('EXP: $expired', Colors.white,
                        bg: Colors.white.withOpacity(0.08),
                        border: Colors.white.withOpacity(0.18)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 6),
          // Tombol hapus akun (label merah)
          GestureDetector(
            onTap: onDelete,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
              decoration: BoxDecoration(
                color: _danger.withOpacity(0.16),
                borderRadius: BorderRadius.circular(9),
                border: Border.all(color: _danger.withOpacity(0.55)),
                boxShadow: [
                  BoxShadow(
                    color: _danger.withOpacity(0.30),
                    blurRadius: 10,
                  ),
                ],
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.delete_outline_rounded,
                      color: _danger, size: 14),
                  SizedBox(width: 4),
                  Text('Hapus',
                      style: TextStyle(
                        fontFamily: _kFont,
                        color: _danger,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.4,
                      )),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _avatarFallback(String username, Color color) {
    final letter = username.isEmpty ? '?' : username[0].toUpperCase();
    return Container(
      alignment: Alignment.center,
      color: color.withOpacity(0.25),
      child: Text(
        letter,
        style: TextStyle(
          fontFamily: _kFont,
          color: Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.w900,
          shadows: [Shadow(color: color.withOpacity(0.6), blurRadius: 8)],
        ),
      ),
    );
  }

  Widget _miniLabel(String text, Color textColor,
      {required Color bg, required Color border}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: border),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontFamily: _kFont,
          color: textColor,
          fontSize: 9.5,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.4,
        ),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════
//  TOMBOL "BUAT AKUN" PANJANG (pojok kanan bawah)
// ════════════════════════════════════════════════════════════════════════════
class _BlueLongButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color color;
  const _BlueLongButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.color = _accentBlue,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [color, _accentDeep],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _accentGlow.withOpacity(0.55)),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.55),
              blurRadius: 18,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.white, size: 18),
            const SizedBox(width: 8),
            Text(label,
                style: const TextStyle(
                  fontFamily: _kFont,
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.6,
                )),
          ],
        ),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════
//  HALAMAN 2  —  Tambahkan Akun (Users)  —  tab Create / Hapus
// ════════════════════════════════════════════════════════════════════════════
class _CreateAccountPage extends StatefulWidget {
  final String sessionKey;
  final String currentUserRole;
  final int totalAccount;
  final int totalCreate;
  final int totalDelete;
  final VoidCallback onCreated;
  final VoidCallback onDeleted;
  const _CreateAccountPage({
    required this.sessionKey,
    required this.currentUserRole,
    required this.totalAccount,
    required this.totalCreate,
    required this.totalDelete,
    required this.onCreated,
    required this.onDeleted,
  });

  @override
  State<_CreateAccountPage> createState() => _CreateAccountPageState();
}

class _CreateAccountPageState extends State<_CreateAccountPage> {
  // tab: 'create' / 'delete'
  String _tab = 'create';

  final _userCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _dayCtrl  = TextEditingController();

  final _delUserCtrl  = TextEditingController();
  final _delReasonCtrl = TextEditingController();

  bool _busy = false;
  late int _localCreate;
  late int _localDelete;

  // ── Role selection ───────────────────────────────────────────────────────
  String _selectedRole = '';

  /// Daftar role yang boleh dipilih sesuai role admin yang sedang login.
  List<String> get _allowedRoles {
    final r = widget.currentUserRole.toLowerCase().trim();
    if (r == 'vip') {
      return ['reseller', 'member'];
    } else if (r == 'tk') {
      return ['member', 'reseller', 'vip'];
    } else if (r == 'owner' || r == 'high owner') {
      return ['member', 'reseller', 'vip', 'tk'];
    } else if (r == 'admin' || r == 'high admin' || r == 'moderator') {
      return ['member', 'reseller', 'vip', 'tk', 'owner', 'moderator'];
    } else if (r == 'developer') {
      return ['developer', 'admin', 'moderator', 'tk', 'owner', 'vip', 'reseller', 'member'];
    } else if (r == 'founder') {
      return ['founder', 'developer', 'admin', 'moderator', 'tk', 'owner', 'vip', 'reseller', 'member'];
    } else if (r == 'pt') {
      return ['pt', 'vip', 'reseller', 'member'];
    }
    // Default (jika role tidak dikenali): semua role
    return ['member', 'reseller', 'vip', 'tk', 'owner', 'moderator', 'dev', 'developer', 'founder', 'pt'];
  }

  @override
  void initState() {
    super.initState();
    _localCreate = widget.totalCreate;
    _localDelete = widget.totalDelete;
    _dayCtrl.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _userCtrl.dispose();
    _passCtrl.dispose();
    _dayCtrl.dispose();
    _delUserCtrl.dispose();
    _delReasonCtrl.dispose();
    super.dispose();
  }

  // ── API ─────────────────────────────────────────────────────────────────
  Future<void> _doCreate() async {
    final u = _userCtrl.text.trim();
    final p = _passCtrl.text.trim();
    final d = _dayCtrl.text.trim();
    if (u.isEmpty || p.isEmpty || d.isEmpty) {
      _toast('Semua field wajib diisi.', err: true);
      return;
    }
    if (_selectedRole.isEmpty) {
      _toast('Role wajib dipilih.', err: true);
      return;
    }
    setState(() => _busy = true);
    try {
      // ✅ PAKE userAdd BUKAN createAccount
      final url = Uri.parse(
          '$_kBaseUrl/userAdd?key=${widget.sessionKey}&username=$u&pasdhxjsword=$p&day=$d&role=$_selectedRole');
      final res  = await http.get(url);
      final data = jsonDecode(res.body);
      if (data['created'] == true) {
        widget.onCreated();
        setState(() {
          _localCreate++;
          _selectedRole = '';
        });
        _userCtrl.clear(); _passCtrl.clear(); _dayCtrl.clear();
        _toast("Akun '$u' berhasil dibuat.");
      } else {
        _toast(data['messdnxage']?.toString() ?? 'Gagal membuat akun.', err: true);
      }
    } catch (_) {
      _toast('Gagal menghubungi server.', err: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
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
      final res  = await http.get(Uri.parse(
          '$_kBaseUrl/deleteUser?key=${widget.sessionKey}&username=$u'));
      final data = jsonDecode(res.body);
      if (data['deleted'] == true) {
        widget.onDeleted();
        setState(() => _localDelete++);
        // Kirim laporan ke Telegram
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
      final text = '🗑 LAPORAN PENGHAPUSAN AKUN\n\n'
          '👤 Username : $username\n'
          '📝 Alasan   : $reason\n'
          '🔑 Session  : ${widget.sessionKey}\n'
          '⏱  Waktu    : ${DateTime.now().toIso8601String()}';
      final uri = Uri.parse('https://api.telegram.org/bot$_kTgToken/sendMessage')
          .replace(queryParameters: {
        'chat_id'   : _kTgChatId,
        'text'      : text,
        'parse_mode': 'HTML',
      });
      await http.get(uri).timeout(const Duration(seconds: 8));
    } catch (_) { /* abaikan kegagalan kirim laporan */ }
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
      ),
    );
  }

  // ════════════════════════════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: Stack(
        children: [
          const Positioned(top: -40, left: -40,
              child: IgnorePointer(child: _HexPattern(corner: _HexCorner.topLeft))),
          const Positioned(bottom: -40, right: -40,
              child: IgnorePointer(child: _HexPattern(corner: _HexCorner.bottomRight))),

          SafeArea(
            child: Column(
              children: [
                _buildTopBar(),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 110),
                    physics: const BouncingScrollPhysics(),
                    children: [
                      _StatsBanner(
                        totalAccount: widget.totalAccount,
                        totalCreate : _localCreate,
                        totalDelete : _localDelete,
                      ),
                      const SizedBox(height: 18),
                      _buildSectionTitle(),
                      const SizedBox(height: 12),
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
                            ? _buildCreateForm(key: const ValueKey('create'))
                            : _buildDeleteForm(key: const ValueKey('delete')),
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

          // Tombol "Daftar Account" pojok kanan bawah → kembali
          Positioned(
            right: 16, bottom: 18,
            child: _BlueLongButton(
              icon: Icons.list_rounded,
              label: 'Daftar Account',
              onTap: () => Navigator.pop(context),
            ),
          ),
        ],
      ),
    );
  }

  // ── Top bar dengan tombol kembali ──────────────────────────────────────
  Widget _buildTopBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 12, 16, 12),
      decoration: BoxDecoration(
        color: _headerBg,
        border: Border(bottom: BorderSide(color: Colors.white.withOpacity(0.05))),
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
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: 40, height: 40,
              decoration: BoxDecoration(
                color: _accentBlue.withOpacity(0.14),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: _accentBlue.withOpacity(0.40)),
              ),
              child: const Icon(Icons.arrow_back_ios_new_rounded,
                  color: _accentGlow, size: 16),
            ),
          ),
          const SizedBox(width: 12),
          const Text('TAMBAHKAN AKUN',
              style: TextStyle(
                fontFamily: _kFont,
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.6,
              )),
        ],
      ),
    );
  }

  // ── Judul section "Tambahkan Akun (Users)" ─────────────────────────────
  Widget _buildSectionTitle() {
    return Row(
      children: [
        // Ikon person + plus kecil
        Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: _accentBlue.withOpacity(0.14),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: _accentBlue.withOpacity(0.45)),
              ),
              child: const Icon(Icons.person_rounded,
                  color: _accentGlow, size: 18),
            ),
            Positioned(
              right: -3, bottom: -3,
              child: Container(
                width: 14, height: 14,
                decoration: BoxDecoration(
                  color: _accentDeep,
                  shape: BoxShape.circle,
                  border: Border.all(color: _bg, width: 1.6),
                ),
                child: const Icon(Icons.add_rounded,
                    color: Colors.white, size: 9),
              ),
            ),
          ],
        ),
        const SizedBox(width: 12),
        const Text('Tambahkan Akun (Users)',
            style: TextStyle(
              fontFamily: _kFont,
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.6,
            )),
      ],
    );
  }

  // ── Tab Create / Hapus ─────────────────────────────────────────────────
  Widget _buildTabSwitcher() {
    return Row(
      children: [
        Expanded(
          child: _tabBtn(
            label : 'Create Account',
            icon  : Icons.add_rounded,
            active: _tab == 'create',
            color : _accentBlue,
            onTap : () => setState(() => _tab = 'create'),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _tabBtn(
            label : 'Hapus Account',
            icon  : Icons.remove_rounded,
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
    required IconData icon,
    required bool active,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 240),
        padding: const EdgeInsets.symmetric(vertical: 11),
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
            Icon(icon, color: active ? Colors.white : _textMuted, size: 16),
            const SizedBox(width: 6),
            Text(label,
                style: TextStyle(
                  fontFamily: _kFont,
                  color: active ? Colors.white : _textMuted,
                  fontSize: 12.5,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.4,
                )),
          ],
        ),
      ),
    );
  }

  // ── FORM CREATE ────────────────────────────────────────────────────────
  Widget _buildCreateForm({Key? key}) {
    final dayValue = _dayCtrl.text.trim();
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
          _inputBox(controller: _userCtrl, hint: 'username'),
          const SizedBox(height: 14),

          _fieldLabel(Icons.lock_rounded, 'Masukan Password'),
          const SizedBox(height: 8),
          _inputBox(controller: _passCtrl, hint: '••••••••', obscure: true),
          const SizedBox(height: 14),

          _fieldLabel(Icons.shield_rounded, 'Role'),
          const SizedBox(height: 8),
          _buildRoleChips(),
          const SizedBox(height: 14),

          _fieldLabel(Icons.calendar_month_rounded, 'Set-Durasi'),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _inputBox(
                  controller: _dayCtrl,
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
            label   : 'Buat Akun (Night Fold)',
            icon    : Icons.add_circle_rounded,
            color   : _accentBlue,
            onTap   : _doCreate,
          ),
        ],
      ),
    );
  }

  // ── ROLE CHIP SELECTOR ─────────────────────────────────────────────────
  Widget _buildRoleChips() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _allowedRoles.map((role) {
        final selected = _selectedRole == role;
        return GestureDetector(
          onTap: () => setState(() => _selectedRole = role),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 8),
            decoration: BoxDecoration(
              color: selected
                  ? _accentBlue.withOpacity(0.22)
                  : _cardBgDeep,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: selected
                    ? _accentBlue.withOpacity(0.65)
                    : _accentBlue.withOpacity(0.22),
                width: 1.2,
              ),
              boxShadow: selected
                  ? [
                      BoxShadow(
                        color: _accentBlue.withOpacity(0.28),
                        blurRadius: 8,
                      ),
                    ]
                  : null,
            ),
            child: Text(
              role,
              style: TextStyle(
                fontFamily: _kFont,
                color: selected ? Colors.white : _textMuted,
                fontSize: 12,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.4,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  // ── FORM HAPUS ─────────────────────────────────────────────────────────
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
          _inputBox(controller: _delUserCtrl, hint: 'username target'),
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
            label : 'Hapus Akun Permanent',
            icon  : Icons.delete_forever_rounded,
            color : _danger,
            onTap : () async {
              final ok = await _showConfirmPopup(
                context,
                title: 'Hapus Permanen',
                message: 'Akun akan dihapus permanen dan laporan akan dikirim ke Telegram.',
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
          BoxShadow(
            color: _accentBlue.withOpacity(0.10),
            blurRadius: 8,
          ),
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
}

// ════════════════════════════════════════════════════════════════════════════
//  TOMBOL PANJANG (untuk form action)
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
//  POLA SEGI ENAM (background corners)
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
      ..color = _accentBlue.withOpacity(0.12);
    final glow = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.6
      ..color = _accentGlow.withOpacity(0.05);

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