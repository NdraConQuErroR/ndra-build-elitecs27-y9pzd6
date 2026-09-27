import 'dart:async'; // ✅ TAMBAHKAN INI
import 'dart:convert';
import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

const String _baseUrl = 'http://zyromodeapa.pteroq.biz.id:10750';
const String _font = 'AROMA';

// ─── Palette ──────────────────────────────────────────────────────────────────
class _C {
  static const bg        = Color(0xFF020617);
  static const surface   = Color(0xFF020B1F);
  static const card      = Color(0xFF0A1124);
  static const cardAlt   = Color(0xFF0F172A);
  static const border    = Color(0xFF1E293B);
  static const borderLit = Color(0xFF334155);
  static const borderHit = Color(0xFF3B82F6);
  static const accent    = Color(0xFF3B82F6);
  static const accentDim = Color(0xFF1D4ED8);
  static const green     = Color(0xFF22C55E);
  static const greenDim  = Color(0xFF15803D);
  static const amber     = Color(0xFFFACC15);
  static const red       = Color(0xFFEF4444);
  static const blue      = Color(0xFF60A5FA);
  static const text      = Color(0xFFE2E8F0);
  static const textSub   = Color(0xFF94A3B8);
 static const textDim   = Color(0xFF475569);

  static const LinearGradient btnGrad = LinearGradient(
    colors: [Color(0xFF1E3A8A), Color(0xFF1D4ED8)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}

// ─── Constants ────────────────────────────────────────────────────────────────
const Color _tealAccent = Color(0xFF22D3EE);
const Color _greenAccent = Color(0xFF4ADE80);
const Color _textWhite = Color(0xFFFFFFFF);
const Color _textGrey = Color(0xFF94A3B8);
const Color kSilverLight = Color(0xFFE8E8EC);
const Color kSilver = Color(0xFFC5C5CB);
const Color kSilverMid = Color(0xFF9A9AA2);
const Color kSilverDark = Color(0xFF5A5A62);
const Color kGraphite = Color(0xFF2A2A30);
const Color kObsidian = Color(0xFF141418);

// ─── GroupBugPage ──────────────────────────────────────────────────────────────
class GroupBugPage extends StatefulWidget {
  final String username;
  final String password;
  final String sessionKey;
  final String role;
  final String expiredDate;

  const GroupBugPage({
    super.key,
    required this.username,
    required this.password,
    required this.sessionKey,
    required this.role,
    required this.expiredDate,
  });

  @override
  State<GroupBugPage> createState() => _GroupBugPageState();
}

class _GroupBugPageState extends State<GroupBugPage> with TickerProviderStateMixin {
  // ── Controllers ────────────────────────────────────────────────────────────
  final TextEditingController linkGroupController = TextEditingController();

  // ── Animations ─────────────────────────────────────────────────────────────
  late AnimationController _fadeController;
  late AnimationController _shimmerController;
  late AnimationController _scanController;
  late AnimationController _pulseController;
  late AnimationController _holdController;
  late VideoPlayerController _videoController;

  bool _videoInitialized = false;
  bool _videoError = false;
  bool _isSending = false;
  bool _isHolding = false;
  int _activeStep = 0;
  bool _linkValid = false;

  // ── Timeline ──────────────────────────────────────────────────────────────
  final List<_TimelineStep> _steps = [
    _TimelineStep(title: "INPUT", subtitle: "scan target", icon: Icons.link_rounded),
    _TimelineStep(title: "VALIDATE", subtitle: "check link", icon: Icons.fact_check_rounded),
    _TimelineStep(title: "INJECT", subtitle: "join + send", icon: FontAwesomeIcons.userNinja),
    _TimelineStep(title: "EXFIL", subtitle: "leave clean", icon: Icons.logout_rounded),
  ];

  // ── Live Ticker ────────────────────────────────────────────────────────────
  final List<String> _logs = [];
  Timer? _logTimer;

  // ─── Init ──────────────────────────────────────────────────────────────────
  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    )..forward();

    _shimmerController = AnimationController(
      duration: const Duration(milliseconds: 2500),
      vsync: this,
    )..repeat();

    _scanController = AnimationController(
      duration: const Duration(seconds: 5),
      vsync: this,
    )..repeat();

    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1800),
      vsync: this,
    )..repeat(reverse: true);

    _holdController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _initVideo();
    _startAmbientLogs();

    linkGroupController.addListener(() {
      final valid = _isValidGroupLink(linkGroupController.text.trim());
      if (valid != _linkValid) {
        setState(() {
          _linkValid = valid;
          if (valid) _activeStep = 1;
          else _activeStep = 0;
        });
        if (valid) HapticFeedback.lightImpact();
      }
    });
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _shimmerController.dispose();
    _scanController.dispose();
    _pulseController.dispose();
    _holdController.dispose();
    _videoController.dispose();
    _logTimer?.cancel();
    linkGroupController.dispose();
    super.dispose();
  }

  // ─── Video ──────────────────────────────────────────────────────────────────
  void _initVideo() {
    try {
      _videoController = VideoPlayerController.asset('assets/videos/banner.mp4')
        ..initialize().then((_) {
          if (mounted) {
            setState(() => _videoInitialized = true);
            _videoController.setLooping(true);
            _videoController.setVolume(0);
            _videoController.play();
          }
        }).catchError((e) {
          if (mounted) setState(() => _videoError = true);
        });
    } catch (_) {
      if (mounted) setState(() => _videoError = true);
    }
  }

  // ─── Logs ──────────────────────────────────────────────────────────────────
  void _startAmbientLogs() {
    _addLog("> system initialized");
    _addLog("> awaiting target link...");
    _logTimer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (!mounted || _isSending) return;
      final ambient = [
        "> idle: monitoring",
        "> heartbeat ok",
        "> tunnel ready",
        "> proxy rotated",
      ];
      _addLog(ambient[math.Random().nextInt(ambient.length)]);
    });
  }

  void _addLog(String msg) {
    if (!mounted) return;
    setState(() {
      _logs.add(msg);
      if (_logs.length > 30) _logs.removeAt(0);
    });
  }

  // ─── Validasi ──────────────────────────────────────────────────────────────
  bool _isValidGroupLink(String input) {
    return RegExp(r'https://chat\.whatsapp\.com/[a-zA-Z0-9]{22}').hasMatch(input);
  }

  // ─── Execute Attack ───────────────────────────────────────────────────────
  Future<void> _executeAttack() async {
    if (_isSending || !_linkValid) return;

    HapticFeedback.heavyImpact();
    setState(() {
      _isSending = true;
      _activeStep = 2;
      _logs.clear();
    });

    _addLog("> ⚡ ATTACK INITIATED");
    _addLog("> target: ${linkGroupController.text.substring(0, 40)}...");
    await Future.delayed(const Duration(milliseconds: 600));
    _addLog("> joining group...");

    try {
      final res = await http.get(
        Uri.parse(
          "$_baseUrl/api/whatsapp/groupBug?key=${widget.sessionKey}&linkGroup=${linkGroupController.text.trim()}",
        ),
      );
      final data = jsonDecode(res.body);

      if (data["valid"] == false) {
        _addLog("> ✗ FAILED: ${data["message"] ?? "unknown"}");
        _showAlert("✗ Failed", data["message"] ?? "Failed to send group bug.");
        setState(() {
          _isSending = false;
          _activeStep = 1;
        });
        return;
      }

      _addLog("> ✓ joined group");
      await Future.delayed(const Duration(milliseconds: 400));
      _addLog("> deploying payload...");
      await Future.delayed(const Duration(milliseconds: 600));
      _addLog("> ✓ payload sent");
      await Future.delayed(const Duration(milliseconds: 300));

      setState(() => _activeStep = 3);
      _addLog("> exfiltrating...");
      await Future.delayed(const Duration(milliseconds: 500));
      _addLog("> ✓ left group, no trace");
      _addLog("> ⚡ MISSION COMPLETE");

      setState(() {
        _isSending = false;
        _activeStep = 4;
      });
      _showSuccessDialog(linkGroupController.text.trim(), data);
    } catch (e) {
      _addLog("> ✗ ERROR: $e");
      _showAlert("✗ Error", "Network error, retry.");
      setState(() {
        _isSending = false;
        _activeStep = 1;
      });
    }
  }

  // ─── Dialogs ──────────────────────────────────────────────────────────────
  void _showAlert(String title, String msg) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: BackdropFilter(
            filter: ui.ImageFilter.blur(sigmaX: 14, sigmaY: 14),
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [
                  kGraphite.withOpacity(0.95),
                  kObsidian.withOpacity(0.98),
                ]),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFFF6B6B).withOpacity(0.4)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.error_outline_rounded, color: Color(0xFFFF6B6B), size: 36),
                  const SizedBox(height: 12),
                  Text(title,
                      style: const TextStyle(
                          color: kSilverLight,
                          fontSize: 14,
                          fontFamily: "AROMA",
                          fontWeight: FontWeight.w900,
                          letterSpacing: 2)),
                  const SizedBox(height: 8),
                  Text(msg,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          color: kSilver.withOpacity(0.75),
                          fontSize: 12,
                          fontFamily: "AROMA")),
                  const SizedBox(height: 16),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: double.infinity,
                      height: 38,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        gradient: const LinearGradient(colors: [kSilverLight, kSilver]),
                      ),
                      child: const Center(
                        child: Text("OK",
                            style: TextStyle(
                                color: kObsidian,
                                fontWeight: FontWeight.w900,
                                fontFamily: "AROMA",
                                letterSpacing: 2)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showSuccessDialog(String linkGroup, Map<String, dynamic> data) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        backgroundColor: kObsidian,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: const Color(0xFF22E07A).withOpacity(0.4)),
        ),
        title: const Text('✅ MISSION COMPLETE',
            style: TextStyle(color: Color(0xFF22E07A), fontFamily: 'AROMA')),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.check_circle_rounded, color: Color(0xFF22E07A), size: 48),
            const SizedBox(height: 12),
            Text('Group: $linkGroup',
                style: TextStyle(color: Colors.white, fontFamily: 'AROMA', fontSize: 12)),
            const SizedBox(height: 8),
            Text('Status: ${data['status'] ?? 'Success'}',
                style: TextStyle(color: kSilver, fontFamily: 'AROMA', fontSize: 11)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK', style: TextStyle(color: Color(0xFF22E07A), fontFamily: 'AROMA')),
          ),
        ],
      ),
    );
  }

  // ─── Build ──────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    if (!["dev", "team_project", "founder", "moderator", "high_owner", "tk", "owner", "vip"].contains(widget.role.toLowerCase())) {
      return _buildAccessDenied();
    }

    return Scaffold(
      backgroundColor: kObsidian,
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          _buildVideoBackground(),
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    kObsidian.withOpacity(0.6),
                    kObsidian.withOpacity(0.85),
                    kObsidian.withOpacity(0.95),
                  ],
                ),
              ),
            ),
          ),
          AnimatedBuilder(
            animation: _scanController,
            builder: (_, __) => Positioned(
              top: MediaQuery.of(context).size.height * _scanController.value,
              left: 0,
              right: 0,
              child: IgnorePointer(
                child: Container(
                  height: 80,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        kSilverLight.withOpacity(0.05),
                        kSilverLight.withOpacity(0.12),
                        kSilverLight.withOpacity(0.05),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          SafeArea(
            child: FadeTransition(
              opacity: _fadeController,
              child: Column(
                children: [
                  _buildFloatingHeader(),
                  Expanded(
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 30),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildVerticalTimeline(),
                          const SizedBox(width: 14),
                          Expanded(child: _buildMainContent()),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Video Background ──────────────────────────────────────────────────────
  Widget _buildVideoBackground() {
    if (_videoInitialized && !_videoError) {
      return Positioned.fill(
        child: FittedBox(
          fit: BoxFit.cover,
          child: SizedBox(
            width: _videoController.value.size.width,
            height: _videoController.value.size.height,
            child: VideoPlayer(_videoController),
          ),
        ),
      );
    }
    return Positioned.fill(
      child: AnimatedBuilder(
        animation: _scanController,
        builder: (_, __) => CustomPaint(
          painter: _MetallicGridPainter(progress: _scanController.value),
        ),
      ),
    );
  }

  // ─── Floating Header ──────────────────────────────────────────────────────
  Widget _buildFloatingHeader() {
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 8, 12, 12),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(colors: [
          kGraphite.withOpacity(0.85),
          kObsidian.withOpacity(0.92),
        ]),
        border: Border.all(color: kSilver.withOpacity(0.25), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.4),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _shimmerText("GROUP BUG", size: 14),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Container(
                      width: 5,
                      height: 5,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _isSending
                            ? const Color(0xFFFF6B6B)
                            : (_linkValid
                                ? const Color(0xFF22E07A)
                                : kSilver.withOpacity(0.5)),
                      ),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      _isSending
                          ? "EXECUTING"
                          : (_linkValid ? "READY TO ATTACK" : "AWAITING TARGET"),
                      style: TextStyle(
                        color: kSilver.withOpacity(0.7),
                        fontSize: 9,
                        fontFamily: "AROMA",
                        letterSpacing: 1.5,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Row(
            children: List.generate(_steps.length, (i) {
              final done = i < _activeStep;
              final current = i == _activeStep && _isSending;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 280),
                margin: const EdgeInsets.symmetric(horizontal: 2),
                width: current ? 18 : 6,
                height: 6,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(3),
                  color: done
                      ? kSilverLight
                      : (current
                          ? const Color(0xFF22E07A)
                          : kSilverDark.withOpacity(0.5)),
                  boxShadow: (done || current)
                      ? [
                          BoxShadow(
                            color: (done ? kSilverLight : const Color(0xFF22E07A))
                                .withOpacity(0.5),
                            blurRadius: 6,
                          ),
                        ]
                      : null,
                ),
              );
            }),
          ),
          const SizedBox(width: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              gradient: LinearGradient(colors: [
                _roleColor().withOpacity(0.3),
                _roleColor().withOpacity(0.1),
              ]),
              border: Border.all(color: _roleColor().withOpacity(0.6)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  widget.role.toLowerCase() == "owner"
                      ? FontAwesomeIcons.userShield
                      : FontAwesomeIcons.crown,
                  color: _roleColor(),
                  size: 9,
                ),
                const SizedBox(width: 4),
                Text(
                  widget.role.toUpperCase(),
                  style: TextStyle(
                    color: _roleColor(),
                    fontSize: 9,
                    fontFamily: "AROMA",
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.2,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _roleColor() {
    switch (widget.role.toLowerCase()) {
      case 'owner':
        return const Color(0xFFFF6B6B);
      case 'vip':
        return const Color(0xFFFFD166);
      default:
        return kSilverLight;
    }
  }

  // ─── Vertical Timeline ────────────────────────────────────────────────────
  Widget _buildVerticalTimeline() {
    return SizedBox(
      width: 60,
      child: Column(
        children: List.generate(_steps.length, (i) {
          final done = i < _activeStep;
          final current = i == _activeStep && _isSending;
          return _timelineNode(
            step: _steps[i],
            index: i,
            done: done,
            current: current,
            isLast: i == _steps.length - 1,
          );
        }),
      ),
    );
  }

  Widget _timelineNode({
    required _TimelineStep step,
    required int index,
    required bool done,
    required bool current,
    required bool isLast,
  }) {
    final color = done
        ? kSilverLight
        : current
            ? const Color(0xFF22E07A)
            : kSilverDark;

    return Column(
      children: [
        AnimatedBuilder(
          animation: _pulseController,
          builder: (_, __) {
            final pulse = current ? (0.4 + _pulseController.value * 0.5) : 0.0;
            return Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: done || current
                    ? LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: done
                            ? [kSilverLight, kSilver, kSilverMid]
                            : [
                                const Color(0xFF22E07A).withOpacity(0.6),
                                const Color(0xFF22E07A).withOpacity(0.3),
                              ],
                      )
                    : null,
                color: done || current ? null : kGraphite.withOpacity(0.6),
                border: Border.all(
                  color: color.withOpacity(done ? 0.5 : 0.4),
                  width: 1.5,
                ),
                boxShadow: (done || current)
                    ? [
                        BoxShadow(
                          color: color.withOpacity(pulse + 0.2),
                          blurRadius: 12 + _pulseController.value * 6,
                          spreadRadius: 0.5,
                        ),
                      ]
                    : null,
              ),
              child: Icon(
                done ? Icons.check_rounded : step.icon,
                color: done ? kObsidian : color,
                size: 18,
              ),
            );
          },
        ),
        const SizedBox(height: 4),
        Text(
          step.title,
          style: TextStyle(
            color: color.withOpacity(done || current ? 1 : 0.6),
            fontSize: 8,
            fontFamily: "AROMA",
            fontWeight: FontWeight.w900,
            letterSpacing: 1,
          ),
        ),
        Text(
          step.subtitle,
          style: TextStyle(
            color: kSilver.withOpacity(0.4),
            fontSize: 7,
            fontFamily: "AROMA",
          ),
        ),
        if (!isLast) ...[
          const SizedBox(height: 6),
          Container(
            width: 2,
            height: 40,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  color.withOpacity(done ? 0.6 : 0.2),
                  color.withOpacity(done && index + 1 < _activeStep ? 0.6 : 0.15),
                ],
              ),
              borderRadius: BorderRadius.circular(1),
            ),
          ),
          const SizedBox(height: 6),
        ] else
          const SizedBox(height: 16),
      ],
    );
  }

  // ─── Main Content ──────────────────────────────────────────────────────────
  Widget _buildMainContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLinkInputCard(),
        const SizedBox(height: 14),
        if (_linkValid) ...[
          _buildGroupPreviewCard(),
          const SizedBox(height: 14),
        ],
        _buildTerminalLog(),
        const SizedBox(height: 18),
        _buildHoldToAttackButton(),
        const SizedBox(height: 12),
        _buildWarningStrip(),
      ],
    );
  }

  // ─── Link Input Card ──────────────────────────────────────────────────────
  Widget _buildLinkInputCard() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 320),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(colors: [
          kGraphite.withOpacity(0.7),
          kObsidian.withOpacity(0.85),
        ]),
        border: Border.all(
          color: _linkValid
              ? const Color(0xFF22E07A).withOpacity(0.5)
              : kSilver.withOpacity(0.2),
          width: 1,
        ),
        boxShadow: _linkValid
            ? [
                BoxShadow(
                  color: const Color(0xFF22E07A).withOpacity(0.15),
                  blurRadius: 14,
                  spreadRadius: 0.5,
                ),
              ]
            : null,
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  gradient: const LinearGradient(colors: [kSilverLight, kSilver]),
                ),
                child: const Icon(FontAwesomeIcons.link, color: kObsidian, size: 12),
              ),
              const SizedBox(width: 10),
              const Text("TARGET LINK",
                  style: TextStyle(
                    color: kSilverLight,
                    fontSize: 10.5,
                    fontFamily: "AROMA",
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.8,
                  )),
              const Spacer(),
              if (_linkValid)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(4),
                    color: const Color(0xFF22E07A).withOpacity(0.15),
                    border: Border.all(color: const Color(0xFF22E07A).withOpacity(0.5)),
                  ),
                  child: const Text("VALID",
                      style: TextStyle(
                        color: Color(0xFF22E07A),
                        fontSize: 7.5,
                        fontFamily: "AROMA",
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1,
                      )),
                ),
            ],
          ),
          const SizedBox(height: 10),
          TextField(
            controller: linkGroupController,
            enabled: !_isSending,
            style: const TextStyle(
              color: kSilverLight,
              fontSize: 12,
              fontFamily: "AROMA",
            ),
            cursorColor: kSilverLight,
            decoration: InputDecoration(
              hintText: "https://chat.whatsapp.com/...",
              hintStyle: TextStyle(
                color: kSilver.withOpacity(0.35),
                fontFamily: "AROMA",
                fontSize: 11,
              ),
              filled: true,
              fillColor: kObsidian.withOpacity(0.5),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Group Preview Card ────────────────────────────────────────────────────
  Widget _buildGroupPreviewCard() {
    final link = linkGroupController.text.trim();
    final groupId = link.length > 30 ? link.substring(link.length - 22) : link;

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOutCubic,
      builder: (_, t, __) => Transform.translate(
        offset: Offset(0, (1 - t) * 14),
        child: Opacity(
          opacity: t,
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  const Color(0xFF22E07A).withOpacity(0.12),
                  kObsidian.withOpacity(0.7),
                ],
              ),
              border: Border.all(color: const Color(0xFF22E07A).withOpacity(0.3)),
            ),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    gradient: const LinearGradient(
                      colors: [Color(0xFF25D366), Color(0xFF128C7E)],
                    ),
                  ),
                  child: const Icon(FontAwesomeIcons.whatsapp, color: Colors.white, size: 18),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("GROUP DETECTED",
                          style: TextStyle(
                            color: Color(0xFF22E07A),
                            fontSize: 9.5,
                            fontFamily: "AROMA",
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.5,
                          )),
                      const SizedBox(height: 2),
                      Text("ID: $groupId",
                          style: TextStyle(
                            color: kSilver.withOpacity(0.7),
                            fontSize: 9,
                            fontFamily: "AROMA",
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis),
                    ],
                  ),
                ),
                AnimatedBuilder(
                  animation: _pulseController,
                  builder: (_, __) => Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFF22E07A),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF22E07A).withOpacity(
                            0.4 + _pulseController.value * 0.5,
                          ),
                          blurRadius: 6 + _pulseController.value * 4,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ─── Terminal Log ──────────────────────────────────────────────────────────
  Widget _buildTerminalLog() {
    return Container(
      height: 130,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Colors.black.withOpacity(0.55),
        border: Border.all(color: kSilverDark.withOpacity(0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color(0xFF22E07A),
                ),
              ),
              const SizedBox(width: 5),
              Text("LIVE.LOG",
                  style: TextStyle(
                    color: kSilver.withOpacity(0.7),
                    fontSize: 8.5,
                    fontFamily: "AROMA",
                    letterSpacing: 1.5,
                  )),
              const Spacer(),
              Text("${_logs.length}",
                  style: TextStyle(
                    color: kSilver.withOpacity(0.45),
                    fontSize: 8,
                    fontFamily: "AROMA",
                  )),
            ],
          ),
          const SizedBox(height: 6),
          Expanded(
            child: ListView.builder(
              reverse: true,
              padding: EdgeInsets.zero,
              itemCount: _logs.length,
              itemBuilder: (_, i) {
                final log = _logs[_logs.length - 1 - i];
                final isOk = log.contains("✓") || log.contains("⚡");
                final isErr = log.contains("✗");
                return Padding(
                  padding: const EdgeInsets.only(bottom: 1),
                  child: Text(
                    log,
                    style: TextStyle(
                      color: isOk
                          ? const Color(0xFF22E07A)
                          : isErr
                              ? const Color(0xFFFF6B6B)
                              : kSilver.withOpacity(0.7),
                      fontSize: 9,
                      fontFamily: "AROMA",
                      height: 1.4,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // ─── Hold to Attack Button ────────────────────────────────────────────────
  Widget _buildHoldToAttackButton() {
    final canAttack = _linkValid && !_isSending;

    return GestureDetector(
      onLongPressStart: canAttack
          ? (_) {
              HapticFeedback.mediumImpact();
              setState(() => _isHolding = true);
              _holdController.forward().then((_) {
                if (_isHolding) _executeAttack();
              });
            }
          : null,
      onLongPressEnd: (_) {
        if (_isHolding && _holdController.value < 1) {
          _holdController.reverse();
          setState(() => _isHolding = false);
        }
      },
      onLongPressCancel: () {
        if (_isHolding) {
          _holdController.reverse();
          setState(() => _isHolding = false);
        }
      },
      child: AnimatedBuilder(
        animation: _holdController,
        builder: (_, __) {
          final progress = _holdController.value;
          return Container(
            width: double.infinity,
            height: 70,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: canAttack
                    ? [
                        Color.lerp(kSilverLight, const Color(0xFFFF6B6B), progress)!,
                        Color.lerp(kSilver, const Color(0xFFB0185C), progress)!,
                        Color.lerp(kSilverMid, const Color(0xFF7A0D3F), progress)!,
                      ]
                    : [
                        kSilverDark.withOpacity(0.4),
                        kGraphite.withOpacity(0.6),
                      ],
              ),
              border: Border.all(
                color: Colors.white.withOpacity(canAttack ? 0.4 : 0.15),
                width: 1.5,
              ),
              boxShadow: canAttack
                  ? [
                      BoxShadow(
                        color: Color.lerp(
                          kSilverLight.withOpacity(0.3),
                          const Color(0xFFFF6B6B).withOpacity(0.5),
                          progress,
                        )!,
                        blurRadius: 14 + progress * 14,
                        spreadRadius: progress * 3,
                      ),
                    ]
                  : null,
            ),
            child: Stack(
              children: [
                if (canAttack)
                  Positioned.fill(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(19),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: FractionallySizedBox(
                          widthFactor: progress,
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Colors.white.withOpacity(0.25),
                                  Colors.white.withOpacity(0.05),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                Center(
                  child: _isSending
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2.5,
                          ),
                        )
                      : Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.black.withOpacity(0.25),
                              ),
                              child: Icon(
                                progress > 0.5
                                    ? Icons.flash_on_rounded
                                    : FontAwesomeIcons.handPointer,
                                color: Colors.white,
                                size: 16,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  canAttack
                                      ? (progress > 0
                                          ? "RELEASING IN..."
                                          : "HOLD TO EXECUTE")
                                      : "ENTER VALID LINK",
                                  style: TextStyle(
                                    color: canAttack ? Colors.white : kSilver.withOpacity(0.5),
                                    fontSize: 13,
                                    fontFamily: "AROMA",
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 2,
                                  ),
                                ),
                                if (canAttack)
                                  Text(
                                    progress > 0
                                        ? "${(progress * 100).toInt()}% — keep holding"
                                        : "press & hold 1.2s",
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.7),
                                      fontSize: 9,
                                      fontFamily: "AROMA",
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                              ],
                            ),
                          ],
                        ),
                ),
                Positioned(
                  top: 6,
                  left: 6,
                  child: _cornerBracket(canAttack),
                ),
                Positioned(
                  bottom: 6,
                  right: 6,
                  child: Transform.rotate(
                    angle: math.pi,
                    child: _cornerBracket(canAttack),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _cornerBracket(bool active) {
    final color = active ? Colors.white : kSilver.withOpacity(0.4);
    return SizedBox(
      width: 10,
      height: 10,
      child: CustomPaint(
        painter: _CornerPainter(color: color),
      ),
    );
  }

  // ─── Warning Strip ─────────────────────────────────────────────────────────
  Widget _buildWarningStrip() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        color: kSilverDark.withOpacity(0.25),
        border: Border.all(color: kSilverDark.withOpacity(0.4)),
      ),
      child: Row(
        children: [
          Icon(Icons.shield_rounded, color: kSilver.withOpacity(0.6), size: 12),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              "AUTO-LEAVE • NO TRACE • IRREVERSIBLE",
              style: TextStyle(
                color: kSilver.withOpacity(0.55),
                fontSize: 8.5,
                fontFamily: "AROMA",
                letterSpacing: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Shimmer Text ───────────────────────────────────────────────────────────
  Widget _shimmerText(String text, {double size = 14}) {
    return AnimatedBuilder(
      animation: _shimmerController,
      builder: (_, __) => ShaderMask(
        shaderCallback: (bounds) => LinearGradient(
          begin: Alignment(-1 + _shimmerController.value * 2, 0),
          end: Alignment(1 + _shimmerController.value * 2, 0),
          colors: const [kSilverDark, kSilverLight, Colors.white, kSilverLight, kSilverDark],
          stops: const [0.0, 0.35, 0.5, 0.65, 1.0],
        ).createShader(bounds),
        child: Text(
          text,
          style: TextStyle(
            color: Colors.white,
            fontSize: size,
            fontWeight: FontWeight.w900,
            fontFamily: "AROMA",
            letterSpacing: 2,
          ),
        ),
      ),
    );
  }

  // ─── Access Denied ──────────────────────────────────────────────────────────
  Widget _buildAccessDenied() {
    return Scaffold(
      backgroundColor: kObsidian,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedBuilder(
              animation: _pulseController,
              builder: (_, __) => Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFFFF6B6B).withOpacity(0.1),
                  border: Border.all(color: const Color(0xFFFF6B6B).withOpacity(0.4)),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFFF6B6B)
                          .withOpacity(0.2 + _pulseController.value * 0.3),
                      blurRadius: 20,
                      spreadRadius: 4,
                    ),
                  ],
                ),
                child: const Icon(FontAwesomeIcons.lock, color: Color(0xFFFF6B6B), size: 50),
              ),
            ),
            const SizedBox(height: 20),
            const Text("ACCESS DENIED",
                style: TextStyle(
                  color: Color(0xFFFF6B6B),
                  fontSize: 22,
                  fontFamily: "AROMA",
                  fontWeight: FontWeight.w900,
                  letterSpacing: 3,
                )),
            const SizedBox(height: 8),
            Text("VIP / OWNER ONLY",
                style: TextStyle(
                  color: kSilver.withOpacity(0.6),
                  fontSize: 11,
                  fontFamily: "AROMA",
                  letterSpacing: 2,
                )),
          ],
        ),
      ),
    );
  }
}

// ─── Models & Painters ──────────────────────────────────────────────────────
class _TimelineStep {
  final String title;
  final String subtitle;
  final IconData icon;
  _TimelineStep({required this.title, required this.subtitle, required this.icon});
}

class _CornerPainter extends CustomPainter {
  final Color color;
  _CornerPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = color
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;
    canvas.drawLine(Offset.zero, Offset(size.width, 0), p);
    canvas.drawLine(Offset.zero, Offset(0, size.height), p);
  }

  @override
  bool shouldRepaint(_) => false;
}

class _MetallicGridPainter extends CustomPainter {
  final double progress;
  _MetallicGridPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final bg = Paint()
      ..shader = const RadialGradient(
        center: Alignment(-0.6, -0.9),
        radius: 1.6,
        colors: [kGraphite, kObsidian],
      ).createShader(Offset.zero & size);
    canvas.drawRect(Offset.zero & size, bg);

    final grid = Paint()
      ..color = kSilverLight.withOpacity(0.04)
      ..strokeWidth = 0.5;
    const spacing = 32.0;
    for (double x = 0; x < size.width; x += spacing) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), grid);
    }
    for (double y = 0; y < size.height; y += spacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), grid);
    }
  }

  @override
  bool shouldRepaint(_) => true;
}