// ignore_for_file: use_build_context_synchronously, deprecated_member_use
import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:audioplayers/audioplayers.dart';

// ── Tema (selaras dengan VOID ENGINE: hitam + biru) ───────────────────────────
const Color _cBlue = Color(0xFF29B6F6);
const Color _cBlueDark = Color(0xFF0D47A1);
const Color _cBlueMid = Color(0xFF1565C0);
const Color _cBg = Color(0xFF141820);
const Color _cBgCard = Color(0xFF1C2230);
const Color _cBgSidebar = Color(0xFF1A1F2C);
const String _font = "Rajdhani";

// ── ENDPOINT API ──────────────────────────────────────────────────────────────
// Memakai API publik Deezer — GRATIS, tanpa API key, real-time, dan mengembalikan
// link preview .mp3 yang bisa langsung diputar di dalam aplikasi (tanpa membuka
// aplikasi musik lain seperti Spotify).
//   - Search   : https://api.deezer.com/search?q=...
//   - Top Chart: https://api.deezer.com/chart/0/tracks
const String _kSearchEndpoint = "https://api.deezer.com/search";
const String _kTopChartEndpoint = "https://api.deezer.com/chart/0/tracks?limit=25";

class MusicPage extends StatefulWidget {
  const MusicPage({super.key});

  @override
  State<MusicPage> createState() => _MusicPageState();
}

class _MusicPageState extends State<MusicPage> with TickerProviderStateMixin {
  final TextEditingController _searchCtrl = TextEditingController();
  final FocusNode _searchFocus = FocusNode();
  final AudioPlayer _player = AudioPlayer();

  List<_Track> _searchResults = [];
  List<_Track> _topTracks = [];

  bool _isSearching = false;
  bool _hasSearched = false;
  bool _isLoadingTop = true;
  String? _topError;
  String? _searchError;

  String? _currentlyPlayingId;
  bool _isPlaying = false;
  Duration _currentPosition = Duration.zero;
  Duration _currentDuration = Duration.zero;
  _Track? _currentTrack;

  Timer? _debounce;

  late AnimationController _entryAnim;

  @override
  void initState() {
    super.initState();

    _entryAnim = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    )..forward();

    _fetchTopTracks();

    _player.onPlayerComplete.listen((_) {
      if (!mounted) return;
      setState(() {
        _isPlaying = false;
        _currentlyPlayingId = null;
        _currentTrack = null;
        _currentPosition = Duration.zero;
      });
    });

    _player.onDurationChanged.listen((d) {
      if (!mounted) return;
      setState(() => _currentDuration = d);
    });

    _player.onPositionChanged.listen((p) {
      if (!mounted) return;
      setState(() => _currentPosition = p);
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _entryAnim.dispose();
    _searchCtrl.dispose();
    _searchFocus.dispose();
    _player.dispose();
    super.dispose();
  }

  // ── DATA FETCH ────────────────────────────────────────────────────────────
  Future<void> _fetchTopTracks() async {
    setState(() {
      _isLoadingTop = true;
      _topError = null;
    });
    try {
      final res = await http
          .get(Uri.parse(_kTopChartEndpoint))
          .timeout(const Duration(seconds: 15));
      if (res.statusCode == 200) {
        final body = jsonDecode(res.body) as Map<String, dynamic>;
        final raw = (body['data'] as List?) ?? const [];
        final list = raw
            .whereType<Map<String, dynamic>>()
            .map(_Track.fromDeezer)
            .where((t) => t.previewUrl.isNotEmpty)
            .toList();
        if (mounted) {
          setState(() {
            _topTracks = list;
            _isLoadingTop = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _isLoadingTop = false;
            _topError = "Gagal memuat (HTTP ${res.statusCode})";
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingTop = false;
          _topError = "Gagal memuat: $e";
        });
      }
    }
  }

  Future<void> _searchMusic(String query) async {
    final q = query.trim();
    if (q.isEmpty) {
      setState(() {
        _searchResults = [];
        _isSearching = false;
        _hasSearched = false;
        _searchError = null;
      });
      return;
    }

    setState(() {
      _isSearching = true;
      _hasSearched = true;
      _searchError = null;
    });

    try {
      final uri = Uri.parse(
          "$_kSearchEndpoint?q=${Uri.encodeQueryComponent(q)}&limit=40");
      final res = await http.get(uri).timeout(const Duration(seconds: 15));
      if (res.statusCode == 200) {
        final body = jsonDecode(res.body) as Map<String, dynamic>;
        final raw = (body['data'] as List?) ?? const [];
        final list = raw
            .whereType<Map<String, dynamic>>()
            .map(_Track.fromDeezer)
            .toList();
        if (mounted) {
          setState(() {
            _searchResults = list;
            _isSearching = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _isSearching = false;
            _searchError = "Gagal mencari (HTTP ${res.statusCode})";
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSearching = false;
          _searchError = "Gagal mencari: $e";
        });
      }
    }
  }

  void _onSearchChanged(String q) {
    _debounce?.cancel();
    _debounce =
        Timer(const Duration(milliseconds: 500), () => _searchMusic(q));
  }

  // ── PLAYER CONTROL ────────────────────────────────────────────────────────
  Future<void> _togglePlay(_Track track) async {
    if (track.previewUrl.isEmpty) {
      _showSnack("Preview audio tidak tersedia untuk lagu ini.");
      return;
    }

    try {
      if (_currentlyPlayingId == track.id && _isPlaying) {
        await _player.pause();
        if (mounted) setState(() => _isPlaying = false);
        return;
      }
      if (_currentlyPlayingId == track.id && !_isPlaying) {
        await _player.resume();
        if (mounted) setState(() => _isPlaying = true);
        return;
      }
      await _player.stop();
      await _player.play(UrlSource(track.previewUrl));
      if (mounted) {
        setState(() {
          _currentlyPlayingId = track.id;
          _currentTrack = track;
          _isPlaying = true;
          _currentPosition = Duration.zero;
        });
      }
    } catch (e) {
      _showSnack("Gagal memutar: $e");
    }
  }

  Future<void> _stopPlayer() async {
    await _player.stop();
    if (mounted) {
      setState(() {
        _isPlaying = false;
        _currentlyPlayingId = null;
        _currentTrack = null;
        _currentPosition = Duration.zero;
      });
    }
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: _cBgCard,
        content: Text(
          msg,
          style: const TextStyle(color: Colors.white, fontFamily: _font),
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // ── BUILD ─────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _cBg,
      body: Stack(
        children: [
          // Background gradient + hex pattern
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [_cBg, Color(0xFF0E1118), _cBg],
              ),
            ),
          ),
          Positioned(
            top: -40,
            left: -40,
            child: Opacity(
              opacity: 0.12,
              child: _MusicHexPattern(
                  size: 220, color: _cBlue.withOpacity(0.4)),
            ),
          ),
          Positioned(
            bottom: -50,
            right: -50,
            child: Opacity(
              opacity: 0.10,
              child: _MusicHexPattern(
                  size: 260, color: _cBlue.withOpacity(0.4)),
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                _buildHeader(),
                _buildSearchBar(),
                Expanded(
                  child: FadeTransition(
                    opacity: CurvedAnimation(
                        parent: _entryAnim, curve: Curves.easeOut),
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.only(bottom: 120),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (_hasSearched) ...[
                            _buildSectionHeader(
                              icon: Icons.search_rounded,
                              title: "HASIL PENCARIAN",
                              count: _searchResults.length,
                            ),
                            const SizedBox(height: 8),
                            _buildResultsList(_searchResults,
                                isLoading: _isSearching,
                                error: _searchError,
                                emptyMsg:
                                    "Tidak ada hasil untuk \"${_searchCtrl.text}\""),
                            const SizedBox(height: 24),
                          ],
                          _buildSectionHeader(
                            icon: Icons.local_fire_department_rounded,
                            title: "MUSIC TERPOPULER",
                            count: _topTracks.length,
                            iconColor: Colors.orangeAccent,
                          ),
                          const SizedBox(height: 8),
                          _buildResultsList(_topTracks,
                              isLoading: _isLoadingTop,
                              error: _topError,
                              emptyMsg: "Belum ada data."),
                          const SizedBox(height: 12),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Mini player overlay
          if (_currentTrack != null)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: _buildMiniPlayer(),
            ),
        ],
      ),
    );
  }

  // ── HEADER ────────────────────────────────────────────────────────────────
  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.of(context).maybePop(),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.06),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.white.withOpacity(0.12)),
              ),
              child: const Icon(Icons.arrow_back_rounded,
                  color: Colors.white, size: 22),
            ),
          ),
          const SizedBox(width: 12),
          Container(
            width: 38,
            height: 38,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [_cBlueDark, _cBlue],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(10),
              boxShadow: [
                BoxShadow(color: _cBlue.withOpacity(0.55), blurRadius: 12),
              ],
            ),
            child: const Icon(Icons.music_note_rounded,
                color: Colors.white, size: 22),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "MUSIC",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    fontFamily: _font,
                    letterSpacing: 2.5,
                  ),
                ),
                Text(
                  "Cari & putar musik favoritmu",
                  style: TextStyle(
                    color: Colors.white54,
                    fontSize: 11,
                    fontFamily: _font,
                  ),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: _fetchTopTracks,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: _cBlue.withOpacity(0.14),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: _cBlue.withOpacity(0.35)),
              ),
              child: const Icon(Icons.refresh_rounded,
                  color: _cBlue, size: 20),
            ),
          ),
        ],
      ),
    );
  }

  // ── SEARCH BAR ────────────────────────────────────────────────────────────
  Widget _buildSearchBar() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 6, 16, 14),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      decoration: BoxDecoration(
        color: _cBgCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _cBlue.withOpacity(0.30)),
        boxShadow: [
          BoxShadow(color: _cBlue.withOpacity(0.10), blurRadius: 14),
          BoxShadow(color: Colors.black.withOpacity(0.4), blurRadius: 8),
        ],
      ),
      child: Row(
        children: [
          const Icon(Icons.search_rounded, color: _cBlue, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: _searchCtrl,
              focusNode: _searchFocus,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14.5,
                fontFamily: _font,
              ),
              cursorColor: _cBlue,
              decoration: const InputDecoration(
                isDense: true,
                border: InputBorder.none,
                hintText: "Cari judul lagu, artis, atau album...",
                hintStyle: TextStyle(
                  color: Colors.white38,
                  fontSize: 13.5,
                  fontFamily: _font,
                ),
              ),
              onChanged: _onSearchChanged,
              onSubmitted: _searchMusic,
              textInputAction: TextInputAction.search,
            ),
          ),
          if (_searchCtrl.text.isNotEmpty)
            GestureDetector(
              onTap: () {
                _searchCtrl.clear();
                _onSearchChanged('');
              },
              child: const Padding(
                padding: EdgeInsets.all(6),
                child: Icon(Icons.close_rounded,
                    color: Colors.white60, size: 18),
              ),
            ),
        ],
      ),
    );
  }

  // ── SECTION HEADER ────────────────────────────────────────────────────────
  Widget _buildSectionHeader({
    required IconData icon,
    required String title,
    required int count,
    Color iconColor = _cBlue,
  }) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 0),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.16),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: iconColor.withOpacity(0.4)),
            ),
            child: Icon(icon, color: iconColor, size: 16),
          ),
          const SizedBox(width: 10),
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.w900,
              fontFamily: _font,
              letterSpacing: 1.6,
            ),
          ),
          const Spacer(),
          if (count > 0)
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: _cBlue.withOpacity(0.16),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: _cBlue.withOpacity(0.4)),
              ),
              child: Text(
                "$count",
                style: const TextStyle(
                  color: _cBlue,
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                  fontFamily: _font,
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ── RESULTS LIST ──────────────────────────────────────────────────────────
  Widget _buildResultsList(
    List<_Track> tracks, {
    required bool isLoading,
    String? error,
    String emptyMsg = "Tidak ada data.",
  }) {
    if (isLoading) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Center(
          child: Column(
            children: [
              SizedBox(
                width: 28,
                height: 28,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  valueColor: AlwaysStoppedAnimation(_cBlue),
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                "Memuat...",
                style: TextStyle(
                  color: Colors.white54,
                  fontSize: 12,
                  fontFamily: _font,
                ),
              ),
            ],
          ),
        ),
      );
    }
    if (error != null) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.red.withOpacity(0.08),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.red.withOpacity(0.4)),
          ),
          child: Row(
            children: [
              const Icon(Icons.error_outline_rounded,
                  color: Colors.redAccent, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  error,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12.5,
                    fontFamily: _font,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }
    if (tracks.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 30, horizontal: 16),
        child: Center(
          child: Text(
            emptyMsg,
            style: const TextStyle(
              color: Colors.white54,
              fontSize: 13,
              fontFamily: _font,
            ),
          ),
        ),
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
      itemCount: tracks.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (_, i) => _buildTrackCard(tracks[i]),
    );
  }

  // ── TRACK CARD ────────────────────────────────────────────────────────────
  Widget _buildTrackCard(_Track t) {
    final bool isActive = _currentlyPlayingId == t.id;
    final bool playing = isActive && _isPlaying;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isActive
              ? [
                  _cBlueDark.withOpacity(0.55),
                  _cBgCard,
                ]
              : [_cBgCard, _cBgCard],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isActive
              ? _cBlue.withOpacity(0.65)
              : Colors.white.withOpacity(0.06),
          width: isActive ? 1.4 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: isActive
                ? _cBlue.withOpacity(0.30)
                : Colors.black.withOpacity(0.45),
            blurRadius: isActive ? 18 : 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => _togglePlay(t),
            splashColor: _cBlue.withOpacity(0.2),
            highlightColor: _cBlue.withOpacity(0.05),
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: Row(
                children: [
                  // Thumbnail
                  Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: t.thumbnail.isEmpty
                            ? Container(
                                width: 64,
                                height: 64,
                                color: _cBgSidebar,
                                child: const Icon(Icons.music_note_rounded,
                                    color: Colors.white24, size: 28),
                              )
                            : Image.network(
                                t.thumbnail,
                                width: 64,
                                height: 64,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => Container(
                                  width: 64,
                                  height: 64,
                                  color: _cBgSidebar,
                                  child: const Icon(
                                      Icons.broken_image_rounded,
                                      color: Colors.white24,
                                      size: 28),
                                ),
                              ),
                      ),
                      if (isActive)
                        Positioned.fill(
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              color: Colors.black.withOpacity(0.45),
                            ),
                            alignment: Alignment.center,
                            child: Icon(
                              playing
                                  ? Icons.equalizer_rounded
                                  : Icons.pause_rounded,
                              color: _cBlue,
                              size: 26,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(width: 12),
                  // Info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          t.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: isActive ? _cBlue : Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            fontFamily: _font,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          t.artist,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                            fontFamily: _font,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Icon(Icons.access_time_rounded,
                                color: Colors.white38, size: 11),
                            const SizedBox(width: 3),
                            Text(
                              _fmtDuration(t.duration),
                              style: const TextStyle(
                                color: Colors.white54,
                                fontSize: 10.5,
                                fontFamily: _font,
                              ),
                            ),
                            if (t.album.isNotEmpty) ...[
                              const SizedBox(width: 8),
                              Container(
                                  width: 3,
                                  height: 3,
                                  decoration: const BoxDecoration(
                                      color: Colors.white24,
                                      shape: BoxShape.circle)),
                              const SizedBox(width: 8),
                              Flexible(
                                child: Text(
                                  t.album,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: Colors.white54,
                                    fontSize: 10.5,
                                    fontFamily: _font,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Play / Pause Button (top-right corner)
                  GestureDetector(
                    onTap: () => _togglePlay(t),
                    child: Container(
                      width: 44,
                      height: 44,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: const LinearGradient(
                          colors: [_cBlueDark, _cBlue],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        boxShadow: [
                          BoxShadow(
                              color: _cBlue.withOpacity(0.55),
                              blurRadius: 12,
                              spreadRadius: 1),
                        ],
                      ),
                      child: Icon(
                        playing
                            ? Icons.pause_rounded
                            : Icons.play_arrow_rounded,
                        color: Colors.white,
                        size: 24,
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

  // ── MINI PLAYER (overlay bottom) ──────────────────────────────────────────
  Widget _buildMiniPlayer() {
    final t = _currentTrack!;
    final pos = _currentPosition.inMilliseconds.toDouble();
    final dur = _currentDuration.inMilliseconds <= 0
        ? 1.0
        : _currentDuration.inMilliseconds.toDouble();
    final progress = (pos / dur).clamp(0.0, 1.0);

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 14),
          decoration: BoxDecoration(
            color: _cBgSidebar.withOpacity(0.92),
            border: Border(
              top: BorderSide(color: _cBlue.withOpacity(0.4), width: 1.2),
            ),
            boxShadow: [
              BoxShadow(color: _cBlue.withOpacity(0.20), blurRadius: 18),
              BoxShadow(color: Colors.black.withOpacity(0.5), blurRadius: 14),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: t.thumbnail.isEmpty
                        ? Container(
                            width: 42,
                            height: 42,
                            color: _cBgCard,
                            child: const Icon(Icons.music_note,
                                color: Colors.white24, size: 20))
                        : Image.network(t.thumbnail,
                            width: 42,
                            height: 42,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(
                                width: 42,
                                height: 42,
                                color: _cBgCard,
                                child: const Icon(Icons.music_note,
                                    color: Colors.white24, size: 20))),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          t.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            fontFamily: _font,
                          ),
                        ),
                        const SizedBox(height: 1),
                        Text(
                          t.artist,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white60,
                            fontSize: 11,
                            fontFamily: _font,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      _isPlaying
                          ? Icons.pause_circle_filled_rounded
                          : Icons.play_circle_filled_rounded,
                      color: _cBlue,
                      size: 36,
                    ),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onPressed: () => _togglePlay(t),
                  ),
                  const SizedBox(width: 6),
                  IconButton(
                    icon: const Icon(Icons.close_rounded,
                        color: Colors.white60, size: 22),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onPressed: _stopPlayer,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              // progress
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 3,
                  backgroundColor: Colors.white12,
                  valueColor: const AlwaysStoppedAnimation(_cBlue),
                ),
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _fmtMs(_currentPosition),
                    style: const TextStyle(
                      color: Colors.white60,
                      fontSize: 10,
                      fontFamily: _font,
                    ),
                  ),
                  Text(
                    _fmtMs(_currentDuration),
                    style: const TextStyle(
                      color: Colors.white60,
                      fontSize: 10,
                      fontFamily: _font,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── HELPERS ───────────────────────────────────────────────────────────────
  String _fmtDuration(int seconds) {
    if (seconds <= 0) return "--:--";
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return "$m:${s.toString().padLeft(2, '0')}";
  }

  String _fmtMs(Duration d) {
    final m = d.inMinutes;
    final s = d.inSeconds % 60;
    return "$m:${s.toString().padLeft(2, '0')}";
  }
}

// ── MODEL ────────────────────────────────────────────────────────────────────
class _Track {
  final String id;
  final String title;
  final String artist;
  final String album;
  final String thumbnail;
  final String previewUrl;
  final int duration;
  final int rank;

  _Track({
    required this.id,
    required this.title,
    required this.artist,
    required this.album,
    required this.thumbnail,
    required this.previewUrl,
    required this.duration,
    required this.rank,
  });

  factory _Track.fromDeezer(Map<String, dynamic> json) {
    final artistMap = json['artist'];
    final albumMap = json['album'];
    String thumb = '';
    if (albumMap is Map) {
      thumb = (albumMap['cover_xl'] ??
              albumMap['cover_big'] ??
              albumMap['cover_medium'] ??
              albumMap['cover'] ??
              '')
          .toString();
    }
    return _Track(
      id: (json['id'] ?? '').toString(),
      title: (json['title_short'] ?? json['title'] ?? '').toString(),
      artist: (artistMap is Map ? (artistMap['name'] ?? '') : '').toString(),
      album: (albumMap is Map ? (albumMap['title'] ?? '') : '').toString(),
      thumbnail: thumb,
      previewUrl: (json['preview'] ?? '').toString(),
      duration: (json['duration'] is int)
          ? json['duration'] as int
          : int.tryParse((json['duration'] ?? '0').toString()) ?? 0,
      rank: (json['rank'] is int)
          ? json['rank'] as int
          : int.tryParse((json['rank'] ?? '0').toString()) ?? 0,
    );
  }
}

// ── HEX PATTERN (background dekorasi) ─────────────────────────────────────────
class _MusicHexPattern extends StatelessWidget {
  final double size;
  final Color color;
  const _MusicHexPattern({required this.size, required this.color});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(painter: _MusicHexPainter(color: color)),
    );
  }
}

class _MusicHexPainter extends CustomPainter {
  final Color color;
  _MusicHexPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    const double r = 16;
    final double w = math.sqrt(3) * r;
    final double h = 2 * r;
    final double vert = h * 3 / 4;

    for (double y = -h; y < size.height + h; y += vert) {
      bool offset = ((y / vert).round() % 2) == 1;
      for (double x = -w; x < size.width + w; x += w) {
        final double cx = x + (offset ? w / 2 : 0);
        _drawHex(canvas, Offset(cx, y), r, paint);
      }
    }
  }

  void _drawHex(Canvas canvas, Offset c, double r, Paint paint) {
    final path = Path();
    for (int i = 0; i < 6; i++) {
      final a = (math.pi / 3) * i + math.pi / 6;
      final p = Offset(c.dx + r * math.cos(a), c.dy + r * math.sin(a));
      if (i == 0) {
        path.moveTo(p.dx, p.dy);
      } else {
        path.lineTo(p.dx, p.dy);
      }
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
