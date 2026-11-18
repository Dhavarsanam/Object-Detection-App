import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';

import '../../core/motion.dart';
import '../../core/routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text.dart';
import '../../data/app_state.dart';
import '../../data/detection_engine.dart';
import '../../data/live/live_engine.dart';
import '../../data/models.dart';
import '../../widgets/glass.dart';
import '../../widgets/motion_widgets.dart';
import '../../widgets/sound_wave.dart';
import 'insight_sheet.dart';
import 'viewfinder_painters.dart';

void openScanner(BuildContext context, Offset origin) {
  Navigator.of(context).push(CircularRevealRoute(
    origin: origin,
    builder: (_) => const LiveDetectionScreen(),
  ));
}

class LiveDetectionScreen extends StatefulWidget {
  const LiveDetectionScreen({super.key});

  @override
  State<LiveDetectionScreen> createState() => _LiveDetectionScreenState();
}

class _LiveDetectionScreenState extends State<LiveDetectionScreen>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  late DetectionEngine _engine;
  late final Ticker _ticker;
  bool _booting = true;
  Duration _last = Duration.zero;

  late final AnimationController _scene =
      AnimationController(vsync: this, duration: const Duration(seconds: 40))..repeat();
  late final AnimationController _scan =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 2600))..repeat(reverse: true);
  late final AnimationController _pulse =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 1400))..repeat();
  late final AnimationController _flash =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 650));
  late final AnimationController _flip =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 700));

  int? _selected;
  bool _torch = false;
  double _zoom = 1;
  String? _toast;
  IconData _toastIcon = Icons.check_circle_rounded;
  Timer? _toastTimer;
  int _captures = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    final s = AppScope.read(context);
    // Placeholder (paused) until the camera + model are ready.
    _engine = SimulatedDetectionEngine(
      mode: s.mode,
      threshold: s.threshold,
      maxObjects: s.maxObjects,
      baseLatency: s.model.latencyMs,
    )..paused = true;
    _ticker = createTicker((elapsed) {
      final dt = ((elapsed - _last).inMicroseconds / 1e6).clamp(0.0, 0.05);
      _last = elapsed;
      _engine.tick(dt);
    })
      ..start();
    _boot();
  }

  /// Try the real camera + TFLite pipeline; fall back to the demo engine.
  Future<void> _boot() async {
    final s = AppScope.read(context);
    final result = await createLiveEngine(
      mode: s.mode,
      threshold: s.threshold,
      maxObjects: s.maxObjects,
      useGpu: s.gpuDelegate,
    );
    if (!mounted) {
      result.engine?.dispose();
      return;
    }
    final live = result.engine;
    setState(() {
      if (live != null) {
        final old = _engine;
        _engine = live;
        // Dispose after listeners have moved to the new engine.
        WidgetsBinding.instance.addPostFrameCallback((_) => old.dispose());
      }
      _engine.paused = false;
      _booting = false;
    });
    if (live == null) {
      _showToast('Demo mode · ${result.reason}', icon: Icons.info_rounded);
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.inactive || state == AppLifecycleState.paused) {
      _engine.suspend();
    } else if (state == AppLifecycleState.resumed) {
      _engine.resume().then((_) {
        if (_torch) _engine.setTorch(true);
      });
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final s = AppScope.of(context);
    _engine
      ..threshold = s.threshold
      ..maxObjects = s.maxObjects;
    final e = _engine;
    if (e is SimulatedDetectionEngine) e.baseLatency = s.model.latencyMs;
    if (_engine.mode != s.mode) _engine.setMode(s.mode);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _ticker.dispose();
    _engine.dispose();
    _scene.dispose();
    _scan.dispose();
    _pulse.dispose();
    _flash.dispose();
    _flip.dispose();
    _toastTimer?.cancel();
    super.dispose();
  }

  // ---- Actions -------------------------------------------------------------

  void _showToast(String msg, {IconData icon = Icons.check_circle_rounded}) {
    _toastTimer?.cancel();
    setState(() {
      _toast = msg;
      _toastIcon = icon;
    });
    _toastTimer = Timer(const Duration(milliseconds: 2200), () {
      if (mounted) setState(() => _toast = null);
    });
  }

  void _capture() {
    final s = AppScope.read(context);
    final dets = _engine.detections.where((d) => d.visibility > 0.5).toList();
    if (s.haptics) HapticFeedback.heavyImpact();
    _flash.forward(from: 0);
    if (dets.isEmpty) {
      _showToast('Nothing in frame yet — hold steady');
      return;
    }
    if (s.saveCaptures) s.addCaptures(dets);
    setState(() => _captures += dets.length);
    _showToast('Saved ${dets.length} object${dets.length == 1 ? '' : 's'} to history');
  }

  Future<void> _openInsight(Detection d) async {
    final s = AppScope.read(context);
    if (s.haptics) HapticFeedback.lightImpact();
    setState(() {
      _selected = d.trackId;
      _engine.paused = true;
    });
    await showInsightSheet(context, detection: d, mode: s.mode);
    if (!mounted) return;
    setState(() {
      _selected = null;
      _engine.paused = false;
    });
  }

  void _togglePause() {
    setState(() => _engine.paused = !_engine.paused);
    _showToast(_engine.paused ? 'Frame frozen' : 'Live detection resumed');
  }

  void _flipCamera() {
    _flip.forward(from: 0);
    _engine.switchCamera();
    _showToast('Camera switched');
  }

  void _toggleTorch() {
    setState(() => _torch = !_torch);
    _engine.setTorch(_torch);
  }

  void _cycleZoom() {
    setState(() => _zoom = _zoom == 1 ? 1.5 : (_zoom == 1.5 ? 2 : 1));
    _engine.setZoom(_zoom);
  }

  /// Camera preview (live) or synthetic scene (demo), with the detection
  /// overlay sharing exactly the same coordinate space.
  Widget _cameraLayer(AppState s) {
    return ListenableBuilder(
      listenable: _engine,
      builder: (context, _) {
        // Screen-space line below the HUD + mode banner; labels above it
        // would be hidden, so they move inside their box instead.
        final screen = MediaQuery.sizeOf(context);
        final hudBottom = MediaQuery.paddingOf(context).top + 136.0;
        final preview = _engine.isLive ? _engine.buildPreview() : null;
        final size = _engine.isLive ? _engine.previewSize : null;

        var safeTop = hudBottom;
        if (size != null) {
          // Convert to the preview's coordinate space (BoxFit.cover).
          final scale = math.max(screen.width / size.width, screen.height / size.height);
          final offsetY = (size.height * scale - screen.height) / 2;
          safeTop = (hudBottom + offsetY) / scale;
        }

        final overlay = _DetectionLayer(
          detections: _engine.detections,
          selected: _selected,
          showLabels: s.showLabels,
          highContrast: s.highContrast,
          showGhosts: !_engine.isLive,
          labelSafeTop: safeTop,
          pulse: _pulse,
          onTap: _openInsight,
        );
        if (_engine.isLive) {
          if (preview == null || size == null) {
            return const ColoredBox(color: Colors.black);
          }
          return ClipRect(
            child: FittedBox(
              fit: BoxFit.cover,
              child: SizedBox(
                width: size.width,
                height: size.height,
                child: Stack(children: [
                  Positioned.fill(child: preview),
                  Positioned.fill(child: overlay),
                ]),
              ),
            ),
          );
        }
        return AnimatedScale(
          scale: _zoom,
          duration: const Duration(milliseconds: 500),
          curve: Motion.emphasized,
          child: Stack(
            children: [
              Positioned.fill(
                child: RepaintBoundary(
                  child: CustomPaint(painter: SyntheticScenePainter(_scene, bright: _torch)),
                ),
              ),
              Positioned.fill(child: overlay),
            ],
          ),
        );
      },
    );
  }

  // ---- Build ---------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    final pad = MediaQuery.paddingOf(context);

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Camera layer (scene + objects + boxes) with zoom & flip.
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _flip,
              builder: (context, child) {
                final v = Curves.easeInOutCubic.transform(_flip.value);
                final a = math.sin(v * math.pi);
                return Transform(
                  alignment: Alignment.center,
                  transform: Matrix4.identity()
                    ..setEntry(3, 2, 0.0009)
                    ..rotateY(a * 0.9),
                  child: Opacity(opacity: 1 - a * 0.6, child: child),
                );
              },
              child: _cameraLayer(s),
            ),
          ),

          // Scan sweep + frame.
          Positioned.fill(
            child: IgnorePointer(
              child: RepaintBoundary(
                child: CustomPaint(painter: ScanLinePainter(_scan, s.mode.color)),
              ),
            ),
          ),
          Positioned.fill(
            child: IgnorePointer(
              child: CustomPaint(
                painter: FrameCornersPainter(EdgeInsets.fromLTRB(18, pad.top + 76, 18, pad.bottom + 250)),
              ),
            ),
          ),

          // Searching reticle when empty.
          Positioned.fill(
            child: IgnorePointer(
              child: ListenableBuilder(
                listenable: _engine,
                builder: (context, _) => AnimatedOpacity(
                  duration: Motion.medium,
                  opacity: _engine.detections.isEmpty ? 1 : 0,
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox.square(
                          dimension: 120,
                          child: CustomPaint(painter: SearchReticlePainter(_pulse)),
                        ),
                        const SizedBox(height: 14),
                        Text(_booting ? 'Starting camera…' : 'Scanning the scene…',
                            style: AppText.caption.copyWith(color: Colors.white70)),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Top HUD + mode banner
          Positioned(
            top: pad.top + 10,
            left: 16,
            right: 16,
            child: Column(
              children: [
                _TopHud(
                  engine: _engine,
                  title: _booting
                      ? 'Loading model…'
                      : _engine.isLive
                          ? _engine.modelName
                          : 'Demo mode',
                  pulse: _pulse,
                ),
                const SizedBox(height: 10),
                ListenableBuilder(
                  listenable: _engine,
                  builder: (context, _) => _ModeBanner(
                    mode: s.mode,
                    detections: _engine.detections,
                    voice: s.voice,
                    pulse: _pulse,
                  ),
                ),
              ],
            ),
          ),

          // Right tool rail
          Positioned(
            right: 16,
            top: pad.top + 190,
            child: _ToolRail(
              children: [
                _RailButton(
                  icon: s.showLabels ? Icons.label_rounded : Icons.label_off_rounded,
                  active: s.showLabels,
                  onTap: () => s.update(() => s.showLabels = !s.showLabels),
                ),
                _RailButton(
                  icon: _torch ? Icons.flash_on_rounded : Icons.flash_off_rounded,
                  active: _torch,
                  onTap: _toggleTorch,
                ),
                _RailButton(
                  icon: Icons.contrast_rounded,
                  active: s.highContrast,
                  onTap: () => s.update(() => s.highContrast = !s.highContrast),
                ),
                _RailButton(
                  label: '${_zoom == 1 ? 1 : _zoom.toStringAsFixed(1)}×',
                  active: _zoom > 1,
                  onTap: _cycleZoom,
                ),
              ],
            ),
          ),

          // Bottom controls
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: _BottomPanel(
              engine: _engine,
              mode: s.mode,
              selected: _selected,
              captures: _captures,
              onMode: (m) {
                if (s.haptics) HapticFeedback.selectionClick();
                s.setMode(m);
              },
              onCapture: _capture,
              onPause: _togglePause,
              onFlip: _flipCamera,
              onChip: _openInsight,
              bottomPadding: pad.bottom,
            ),
          ),

          // Toast
          Positioned(
            top: pad.top + 140,
            left: 0,
            right: 0,
            child: IgnorePointer(
              child: Center(
                child: AnimatedSwitcher(
                  duration: Motion.medium,
                  switchInCurve: Motion.overshoot,
                  transitionBuilder: (c, a) => FadeTransition(
                    opacity: a,
                    child: ScaleTransition(scale: Tween(begin: 0.85, end: 1.0).animate(a), child: c),
                  ),
                  child: _toast == null
                      ? const SizedBox.shrink()
                      : GlassCard(
                          key: ValueKey(_toast),
                          radius: 100,
                          tint: AppColors.surface,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(_toastIcon,
                                  color: _toastIcon == Icons.info_rounded ? AppColors.amber : AppColors.mint,
                                  size: 18),
                              const SizedBox(width: 8),
                              Flexible(
                                child: Text(_toast!,
                                    style: AppText.bodyStrong.copyWith(fontSize: 13),
                                    overflow: TextOverflow.ellipsis),
                              ),
                            ],
                          ),
                        ),
                ),
              ),
            ),
          ),

          // Shutter flash
          Positioned.fill(
            child: IgnorePointer(
              child: AnimatedBuilder(
                animation: _flash,
                builder: (context, _) {
                  final v = _flash.value;
                  final o = v == 0 ? 0.0 : (1 - Curves.easeOut.transform(v)) * 0.85;
                  return ColoredBox(color: Colors.white.withValues(alpha: o));
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================================

class _DetectionLayer extends StatelessWidget {
  const _DetectionLayer({
    required this.detections,
    required this.selected,
    required this.showLabels,
    required this.highContrast,
    required this.showGhosts,
    this.labelSafeTop = 4,
    required this.pulse,
    required this.onTap,
  });

  final List<Detection> detections;
  final int? selected;
  final bool showLabels;
  final bool highContrast;
  final bool showGhosts;
  final double labelSafeTop;

  /// Label sits above the box, unless that spot is covered by the HUD —
  /// then it tucks inside the box's top edge.
  double _labelTop(Rect r) {
    final above = r.top - 34;
    if (above >= labelSafeTop) return above;
    final inside = math.max(r.top + 6, labelSafeTop);
    return math.min(inside, math.max(r.top + 6, r.bottom - 34));
  }
  final Animation<double> pulse;
  final ValueChanged<Detection> onTap;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, c) {
      final w = c.maxWidth, h = c.maxHeight;
      Rect toPx(Rect r) => Rect.fromLTRB(r.left * w, r.top * h, r.right * w, r.bottom * h);
      return Stack(
        clipBehavior: Clip.none,
        children: [
          // "Objects" in the synthetic scene (demo mode only).
          if (showGhosts)
            for (final d in detections)
            Positioned.fromRect(
              rect: toPx(d.box),
              child: IgnorePointer(
                child: Opacity(
                  opacity: d.visibility,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: RadialGradient(colors: [
                        d.cls.color.withValues(alpha: 0.16),
                        d.cls.color.withValues(alpha: 0),
                      ]),
                    ),
                    child: Center(
                      child: Icon(
                        d.cls.icon,
                        size: toPx(d.box).shortestSide * 0.62,
                        color: d.cls.color.withValues(alpha: 0.22),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          Positioned.fill(
            child: IgnorePointer(
              child: CustomPaint(
                painter: BoxesPainter(
                  detections: detections,
                  selected: selected,
                  highContrast: highContrast,
                  pulse: pulse,
                ),
              ),
            ),
          ),
          for (final d in detections)
            Positioned.fromRect(
              rect: toPx(d.box),
              child: GestureDetector(
                behavior: HitTestBehavior.translucent,
                onTap: () => onTap(d),
              ),
            ),
          if (showLabels)
            for (final d in detections)
              Positioned(
                left: toPx(d.box).left,
                top: _labelTop(toPx(d.box)),
                child: IgnorePointer(
                  child: Opacity(
                    opacity: d.visibility,
                    child: Transform.scale(
                      alignment: Alignment.bottomLeft,
                      scale: 0.85 + 0.15 * d.visibility,
                      child: _BoxLabel(d: d, highContrast: highContrast),
                    ),
                  ),
                ),
              ),
        ],
      );
    });
  }
}

class _BoxLabel extends StatelessWidget {
  const _BoxLabel({required this.d, required this.highContrast});
  final Detection d;
  final bool highContrast;

  @override
  Widget build(BuildContext context) {
    final color = highContrast ? AppColors.lime : d.cls.color;
    return Container(
      padding: const EdgeInsets.fromLTRB(6, 5, 10, 5),
      decoration: BoxDecoration(
        color: highContrast ? Colors.black : const Color(0xCC0A0C16),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.7)),
        boxShadow: [BoxShadow(color: color.withValues(alpha: 0.35), blurRadius: 12)],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(6)),
            child: Icon(d.cls.icon, size: 11, color: AppColors.bg),
          ),
          const SizedBox(width: 6),
          Text(d.cls.label,
              style: TextStyle(
                fontSize: highContrast ? 13 : 12,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              )),
          const SizedBox(width: 6),
          Text('${(d.confidence * 100).toStringAsFixed(0)}%', style: AppText.mono.copyWith(color: color)),
        ],
      ),
    );
  }
}

// ============================================================================

class _TopHud extends StatelessWidget {
  const _TopHud({required this.engine, required this.title, required this.pulse});
  final DetectionEngine engine;
  final String title;
  final Animation<double> pulse;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Pressable(
          onTap: () => Navigator.of(context).pop(),
          child: const GlassCard(
            radius: 18,
            padding: EdgeInsets.all(12),
            child: Icon(Icons.close_rounded, size: 22),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: GlassCard(
            radius: 18,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
            child: Row(
              children: [
                ListenableBuilder(
                  listenable: engine,
                  builder: (context, _) => _LiveDot(pulse: pulse, paused: engine.paused),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(title,
                      style: AppText.bodyStrong.copyWith(fontSize: 13), overflow: TextOverflow.ellipsis),
                ),
                const SizedBox(width: 6),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 104),
                  child: ListenableBuilder(
                    listenable: engine,
                    builder: (context, _) => FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerRight,
                      child: Text(
                        '${engine.fps.toStringAsFixed(0)} FPS · ${engine.latencyMs} ms',
                        style: AppText.mono.copyWith(color: AppColors.mint),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _LiveDot extends StatelessWidget {
  const _LiveDot({required this.pulse, required this.paused});
  final Animation<double> pulse;
  final bool paused;

  @override
  Widget build(BuildContext context) {
    final color = paused ? AppColors.amber : AppColors.red;
    return AnimatedBuilder(
      animation: pulse,
      builder: (context, _) {
        final v = paused ? 0.0 : pulse.value;
        return Row(
          children: [
            SizedBox.square(
              dimension: 14,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    width: 6 + 8 * v,
                    height: 6 + 8 * v,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: color.withValues(alpha: 0.5 * (1 - v)),
                    ),
                  ),
                  Container(
                    width: 7,
                    height: 7,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: color,
                      boxShadow: [BoxShadow(color: color, blurRadius: 6)],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 6),
            Text(paused ? 'PAUSED' : 'LIVE', style: AppText.overline.copyWith(color: color, fontSize: 10)),
          ],
        );
      },
    );
  }
}

class _ModeBanner extends StatelessWidget {
  const _ModeBanner({
    required this.mode,
    required this.detections,
    required this.voice,
    required this.pulse,
  });

  final DetectionMode mode;
  final List<Detection> detections;
  final bool voice;
  final Animation<double> pulse;

  @override
  Widget build(BuildContext context) {
    final (IconData icon, String title, String sub, Color color, Widget? trailing) = switch (mode) {
      DetectionMode.general => (
          mode.icon,
          detections.isEmpty
              ? 'Looking for objects'
              : 'Tracking ${detections.length} object${detections.length == 1 ? '' : 's'}',
          detections.isEmpty ? 'Point the camera at your surroundings' : detections.map((d) => d.cls.label).join(' · '),
          mode.color,
          null,
        ),
      DetectionMode.surveillance => _surveillance(),
      DetectionMode.inventory => _inventory(),
      DetectionMode.accessibility => _accessibility(),
    };

    return AnimatedSwitcher(
      duration: Motion.medium,
      transitionBuilder: (c, a) => FadeTransition(
        opacity: a,
        child: SlideTransition(
          position: Tween(begin: const Offset(0, -0.2), end: Offset.zero).animate(a),
          child: c,
        ),
      ),
      child: GlassCard(
        key: ValueKey('${mode.name}-$title'),
        radius: 20,
        tint: color,
        borderColor: color.withValues(alpha: 0.4),
        padding: const EdgeInsets.fromLTRB(12, 10, 14, 10),
        child: Row(
          children: [
            IconBadge(icon: icon, color: color, size: 36, glow: false),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: AppText.bodyStrong.copyWith(fontSize: mode == DetectionMode.accessibility ? 15.5 : 14),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 2),
                  Text(sub, style: AppText.caption.copyWith(fontSize: 11.5), maxLines: 1, overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
            ?trailing,
          ],
        ),
      ),
    );
  }

  (IconData, String, String, Color, Widget?) _surveillance() {
    final people = detections.where((d) => d.cls.category == ObjectCategory.people).length;
    final vehicles = detections.where((d) => d.cls.category == ObjectCategory.vehicles).length;
    final alert = people > 0;
    return (
      alert ? Icons.warning_amber_rounded : Icons.shield_rounded,
      alert ? 'Person in monitored zone' : 'Zone clear',
      '$people ${people == 1 ? 'person' : 'people'} · $vehicles vehicle${vehicles == 1 ? '' : 's'} · logging',
      alert ? AppColors.red : mode.color,
      alert
          ? AnimatedBuilder(
              animation: pulse,
              builder: (context, _) => Opacity(
                opacity: 0.4 + 0.6 * (1 - pulse.value),
                child: const Pill(label: 'ALERT', color: AppColors.red, dense: true),
              ),
            )
          : const Pill(label: 'ARMED', color: AppColors.mint, dense: true),
    );
  }

  (IconData, String, String, Color, Widget?) _inventory() {
    final tally = <String, int>{};
    for (final d in detections) {
      tally[d.cls.label] = (tally[d.cls.label] ?? 0) + 1;
    }
    final total = detections.length;
    return (
      mode.icon,
      total == 0 ? 'No items in frame' : '$total item${total == 1 ? '' : 's'} counted',
      tally.isEmpty ? 'Hold steady over a shelf or table' : tally.entries.map((e) => '${e.key} ×${e.value}').join('  ·  '),
      mode.color,
      Text('$total', style: AppText.number.copyWith(color: mode.color, fontSize: 24)),
    );
  }

  (IconData, String, String, Color, Widget?) _accessibility() {
    if (detections.isEmpty) {
      return (mode.icon, 'Nothing nearby', 'I will describe what I see', mode.color, null);
    }
    final main = detections.reduce(
        (a, b) => a.box.width * a.box.height >= b.box.width * b.box.height ? a : b);
    return (
      Icons.record_voice_over_rounded,
      '${main.cls.label} ${main.direction}',
      'About ${main.distanceMeters.toStringAsFixed(1)} metres away',
      mode.color,
      voice ? const SoundWave(color: AppColors.amber) : const Icon(Icons.volume_off_rounded, size: 18),
    );
  }
}

class _ToolRail extends StatelessWidget {
  const _ToolRail({required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      radius: 24,
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 6),
      child: Column(
        children: [
          for (var i = 0; i < children.length; i++) ...[
            if (i > 0) const SizedBox(height: 4),
            children[i],
          ],
        ],
      ),
    );
  }
}

class _RailButton extends StatelessWidget {
  const _RailButton({this.icon, this.label, required this.active, required this.onTap});
  final IconData? icon;
  final String? label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: onTap,
      scale: 0.85,
      child: AnimatedContainer(
        duration: Motion.fast,
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(15),
          color: active ? AppColors.cyan.withValues(alpha: 0.18) : Colors.transparent,
        ),
        alignment: Alignment.center,
        child: icon != null
            ? Icon(icon, size: 20, color: active ? AppColors.cyan : Colors.white70)
            : Text(label!, style: AppText.mono.copyWith(fontSize: 12, color: active ? AppColors.cyan : Colors.white)),
      ),
    );
  }
}

// ============================================================================

class _BottomPanel extends StatelessWidget {
  const _BottomPanel({
    required this.engine,
    required this.mode,
    required this.selected,
    required this.captures,
    required this.onMode,
    required this.onCapture,
    required this.onPause,
    required this.onFlip,
    required this.onChip,
    required this.bottomPadding,
  });

  final DetectionEngine engine;
  final DetectionMode mode;
  final int? selected;
  final int captures;
  final ValueChanged<DetectionMode> onMode;
  final VoidCallback onCapture;
  final VoidCallback onPause;
  final VoidCallback onFlip;
  final ValueChanged<Detection> onChip;
  final double bottomPadding;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(bottom: bottomPadding + 12, top: 40),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.transparent, Colors.black.withValues(alpha: 0.85)],
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            height: 40,
            child: ListenableBuilder(
              listenable: engine,
              builder: (context, _) => SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    for (final d in engine.detections)
                      KeyedSubtree(
                        key: ValueKey(d.trackId),
                        child: Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: _TrayChip(d: d, selected: d.trackId == selected, onTap: () => onChip(d)),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          _ModeSwitcher(mode: mode, onChanged: onMode),
          const SizedBox(height: 18),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 36),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                ListenableBuilder(
                  listenable: engine,
                  builder: (context, _) => _RoundButton(
                    icon: engine.paused ? Icons.play_arrow_rounded : Icons.pause_rounded,
                    onTap: onPause,
                    badge: captures > 0 ? '$captures' : null,
                  ),
                ),
                _Shutter(onTap: onCapture, color: mode.color),
                _RoundButton(icon: Icons.flip_camera_ios_rounded, onTap: onFlip),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TrayChip extends StatelessWidget {
  const _TrayChip({required this.d, required this.selected, required this.onTap});
  final Detection d;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 500),
      curve: Motion.overshoot,
      builder: (context, v, child) => Opacity(
        opacity: v.clamp(0.0, 1.0) * d.visibility.clamp(0.3, 1.0),
        child: Transform.scale(scale: 0.6 + 0.4 * v, child: child),
      ),
      child: Pressable(
        onTap: onTap,
        child: AnimatedContainer(
          duration: Motion.fast,
          padding: const EdgeInsets.fromLTRB(6, 6, 12, 6),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(100),
            color: selected ? d.cls.color.withValues(alpha: 0.3) : Colors.white.withValues(alpha: 0.08),
            border: Border.all(color: d.cls.color.withValues(alpha: selected ? 0.9 : 0.4)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 26,
                height: 26,
                decoration: BoxDecoration(shape: BoxShape.circle, color: d.cls.color.withValues(alpha: 0.25)),
                child: Icon(d.cls.icon, size: 14, color: d.cls.color),
              ),
              const SizedBox(width: 8),
              Text(d.cls.label, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700)),
              const SizedBox(width: 6),
              Text('${(d.confidence * 100).round()}%', style: AppText.mono.copyWith(color: d.cls.color)),
            ],
          ),
        ),
      ),
    );
  }
}

class _ModeSwitcher extends StatelessWidget {
  const _ModeSwitcher({required this.mode, required this.onChanged});
  final DetectionMode mode;
  final ValueChanged<DetectionMode> onChanged;

  @override
  Widget build(BuildContext context) {
    return FittedBox(
      fit: BoxFit.scaleDown,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final m in DetectionMode.values)
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => onChanged(m),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                child: Column(
                  children: [
                    AnimatedDefaultTextStyle(
                      duration: Motion.fast,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.6,
                        color: m == mode ? m.color : Colors.white54,
                        shadows: m == mode ? [Shadow(color: m.color, blurRadius: 12)] : null,
                      ),
                      child: Text(m.short),
                    ),
                    const SizedBox(height: 6),
                    AnimatedContainer(
                      duration: Motion.medium,
                      curve: Motion.overshoot,
                      width: m == mode ? 18 : 0,
                      height: 3,
                      decoration: BoxDecoration(
                        color: m.color,
                        borderRadius: BorderRadius.circular(3),
                        boxShadow: [BoxShadow(color: m.color, blurRadius: 8)],
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
}

class _RoundButton extends StatelessWidget {
  const _RoundButton({required this.icon, required this.onTap, this.badge});
  final IconData icon;
  final VoidCallback onTap;
  final String? badge;

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: onTap,
      scale: 0.85,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          GlassCard(
            radius: 100,
            padding: const EdgeInsets.all(14),
            child: Icon(icon, size: 24),
          ),
          if (badge != null)
            Positioned(
              right: -2,
              top: -2,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(badge!, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800)),
              ),
            ),
        ],
      ),
    );
  }
}

class _Shutter extends StatefulWidget {
  const _Shutter({required this.onTap, required this.color});
  final VoidCallback onTap;
  final Color color;

  @override
  State<_Shutter> createState() => _ShutterState();
}

class _ShutterState extends State<_Shutter> with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 700));

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Pressable(
      haptic: false,
      scale: 0.88,
      onTap: () {
        _c.forward(from: 0);
        widget.onTap();
      },
      child: AnimatedBuilder(
        animation: _c,
        builder: (context, _) {
          final v = _c.value;
          return SizedBox.square(
            dimension: 84,
            child: CustomPaint(
              painter: _ShutterRingPainter(v, widget.color),
              child: Center(
                child: AnimatedContainer(
                  duration: Motion.medium,
                  width: 64 - 10 * math.sin(v * math.pi),
                  height: 64 - 10 * math.sin(v * math.pi),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(colors: [Colors.white, Color.lerp(Colors.white, widget.color, 0.35)!]),
                    boxShadow: [BoxShadow(color: widget.color.withValues(alpha: 0.6), blurRadius: 24)],
                  ),
                  child: Icon(Icons.center_focus_weak_rounded, color: AppColors.bg.withValues(alpha: 0.7), size: 26),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _ShutterRingPainter extends CustomPainter {
  _ShutterRingPainter(this.v, this.color);
  final double v;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = (Offset.zero & size).deflate(2);
    canvas.drawOval(
      rect,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..color = Colors.white.withValues(alpha: 0.85),
    );
    if (v > 0 && v < 1) {
      canvas.drawArc(
        rect,
        -math.pi / 2,
        math.pi * 2 * Curves.easeOutCubic.transform(v),
        false,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 4
          ..strokeCap = StrokeCap.round
          ..color = color,
      );
    }
  }

  @override
  bool shouldRepaint(_ShutterRingPainter old) => old.v != v || old.color != color;
}
