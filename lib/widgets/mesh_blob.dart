import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:mesh_gradient/mesh_gradient.dart';

/// "Canlı AI" görsel kimliğinin paylaşılan gövdesi (F-5c refactor'ü):
/// amorf blob kırpmalı mini [AnimatedMeshGradient]. Renk ailesi çağırana
/// bırakılır — onboarding orb'u mesh/teal ailesini, acil akışın nefes
/// blob'u sos ailesini kullanır.
class MeshBlob extends StatefulWidget {
  const MeshBlob({
    super.key,
    required this.size,
    required this.colors,
    this.speed = 2,
    this.breathe = false,
  });

  /// Kare kutunun kenarı — blob salınımıyla birlikte bu kutuya sığar.
  final double size;

  /// Mesh renkleri — shader TAM 4 renk ister.
  final List<Color> colors;

  /// Mesh akış hızı.
  final double speed;

  /// true: kendi 3.4 sn'lik hafif nefes ölçeği (1.0→1.06). Ölçek dışarıdan
  /// bir animasyonla sürülüyorsa (acil nefes adımındaki al/ver senkronu)
  /// kapalı bırakılır — iki ölçek üst üste binmesin.
  final bool breathe;

  @override
  State<MeshBlob> createState() => _MeshBlobState();
}

class _MeshBlobState extends State<MeshBlob> with TickerProviderStateMixin {
  late final AnimationController _breath;

  /// Blob kenar salınımının zaman kaynağı: 60 sn'lik tam döngü. Tüm nokta
  /// frekansları bu döngüde tamsayı tur atar (bkz. [_BlobClipper._turns]),
  /// böylece repeat anında sıçrama olmaz.
  late final AnimationController _blob;

  @override
  void initState() {
    super.initState();
    _breath = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3400),
    );
    if (widget.breathe) _breath.repeat(reverse: true);
    _blob = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 60),
    )..repeat();
  }

  @override
  void dispose() {
    _breath.dispose();
    _blob.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Widget body = SizedBox(
      width: widget.size,
      height: widget.size,
      child: AnimatedBuilder(
        animation: _blob,
        // Mesh child olarak bir kez kurulur; her karede yalnızca
        // kırpma yolu değişir, shader rebuild edilmez.
        builder: (context, child) => ClipPath(
          clipper: _BlobClipper(t: _blob.value),
          child: child,
        ),
        child: AnimatedMeshGradient(
          colors: widget.colors,
          options: AnimatedMeshGradientOptions(
            speed: widget.speed,
            frequency: 4,
            amplitude: 25,
          ),
        ),
      ),
    );
    if (widget.breathe) {
      body = ScaleTransition(
        scale: Tween(begin: 1.0, end: 1.06).animate(
          CurvedAnimation(parent: _breath, curve: Curves.easeInOut),
        ),
        child: body,
      );
    }
    return body;
  }
}

/// Ucuz blob (F-6): [MeshBlob]'un shader'sız kardeşi — statik radial degrade
/// + aynı [_BlobClipper] kenar dalgalanması. Sürekli görünen yerlerde (nav
/// sekmesi, chat avatarları, karşılama) canlılık hissini kenar salınımı
/// verir; shader maliyeti yok. Tam mesh yalnız başrol/geçici sahnelerde
/// ([MeshBlob]) kullanılır — performans ilkesi, docs/PROGRESS.md F-6.
class FlatBlob extends StatefulWidget {
  const FlatBlob({super.key, required this.size, this.wobble = true});

  /// Kare kutunun kenarı — blob salınımıyla birlikte bu kutuya sığar.
  final double size;

  /// false: tamamen statik silüet — listelerde tekrar eden avatarlar için
  /// (controller bile kurulmaz, sıfır animasyon maliyeti).
  final bool wobble;

  @override
  State<FlatBlob> createState() => _FlatBlobState();
}

class _FlatBlobState extends State<FlatBlob>
    with SingleTickerProviderStateMixin {
  /// MeshBlob'la aynı zaman kaynağı deseni: 60 sn'lik döngü, tamsayı turlar
  /// sayesinde repeat sıçramasız. Yalnız [FlatBlob.wobble] açıkken kurulur.
  AnimationController? _blob;

  @override
  void initState() {
    super.initState();
    if (widget.wobble) {
      _blob = AnimationController(
        vsync: this,
        duration: const Duration(seconds: 60),
      )..repeat();
    }
  }

  @override
  void dispose() {
    _blob?.dispose();
    super.dispose();
  }

  /// Statik degrade dolgu — mesh yok, tek radial geçiş (açık meshB tonu →
  /// primary). Işık sol üstten gelir, hafif hacim hissi verir.
  static const _fill = DecoratedBox(
    decoration: BoxDecoration(
      gradient: RadialGradient(
        center: Alignment(-0.35, -0.35),
        radius: 1.1,
        colors: [Color(0xFF7FB0A5), Color(0xFF3E6660)],
      ),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final blob = _blob;
    final body = SizedBox(
      width: widget.size,
      height: widget.size,
      child: blob == null
          ? ClipPath(clipper: _BlobClipper(t: 0), child: _fill)
          : AnimatedBuilder(
              animation: blob,
              // Dolgu child olarak bir kez kurulur; her karede yalnızca
              // kırpma yolu değişir.
              builder: (context, child) => ClipPath(
                clipper: _BlobClipper(t: blob.value),
                child: child,
              ),
              child: _fill,
            ),
    );
    // Kenar salınımı yalnız kendi alanını boyasın, üst ağacı kirletmesin.
    return RepaintBoundary(child: body);
  }
}

/// Blob'un organik silüeti (canlı hücre hissi — kusursuz daire fazla "ölü"
/// duruyordu). 7 kontrol noktası daire üzerine yerleşir; her noktanın
/// yarıçapı kendi frekans/fazında salınır — frekanslar birbirinden farklı,
/// asla senkronlaşmaz (senkron olsa "nabız" gibi dururdu). Noktalar
/// Catmull-Rom'dan türetilen kübik bezier'le kapatılır: hiçbir anda köşe,
/// hiçbir anda tam daire yok.
class _BlobClipper extends CustomClipper<Path> {
  _BlobClipper({required this.t});

  /// Döngü ilerlemesi [0,1) — 60 sn'lik controller değeri.
  final double t;

  static const int _pointCount = 7;

  /// Nokta başına döngüdeki tam tur sayısı (60 sn'de periyot 60/k:
  /// 4.0–6.7 sn). Hepsi farklı; tamsayı olmaları repeat'i sıçramasız yapar.
  static const List<double> _turns = [9, 11, 13, 10, 15, 12, 14];

  /// Sabit faz ofsetleri — başlangıçtan itibaren düzensiz görünüm.
  static const List<double> _phases = [0.0, 2.1, 4.4, 1.2, 5.3, 3.0, 0.7];

  /// Yarıçap salınım genliği (taban yarıçapın oranı).
  static const double _amplitude = 0.12;

  @override
  Path getClip(Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    // Salınım payı: en şişkin anda bile kutuya sığar (0.88 × 1.12 < 1).
    final baseRadius = size.shortestSide / 2 * 0.88;

    final points = <Offset>[];
    for (var i = 0; i < _pointCount; i++) {
      final angle = 2 * math.pi * i / _pointCount;
      final wobble = math.sin(2 * math.pi * _turns[i] * t + _phases[i]);
      final radius = baseRadius * (1 + _amplitude * wobble);
      points.add(center + Offset(math.cos(angle), math.sin(angle)) * radius);
    }

    // Catmull-Rom → kübik bezier, kapalı eğri.
    final path = Path()..moveTo(points[0].dx, points[0].dy);
    for (var i = 0; i < _pointCount; i++) {
      final p0 = points[(i - 1 + _pointCount) % _pointCount];
      final p1 = points[i];
      final p2 = points[(i + 1) % _pointCount];
      final p3 = points[(i + 2) % _pointCount];
      final c1 = p1 + (p2 - p0) / 6;
      final c2 = p2 - (p3 - p1) / 6;
      path.cubicTo(c1.dx, c1.dy, c2.dx, c2.dy, p2.dx, p2.dy);
    }
    return path..close();
  }

  @override
  bool shouldReclip(_BlobClipper oldClipper) => oldClipper.t != t;
}
