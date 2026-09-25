import 'package:flutter/material.dart';
import 'package:uno_reverse/features/shell/app_bottom_nav.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SizedBox(
          width: 220,
          height: 150,
          child: CustomPaint(painter: _HomeScenePainter()),
        ),
        SizedBox(height: 28),
        Text(
          'Welcome Home',
          style: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.w800,
            color: Color(0xFF1C1C1E),
          ),
        ),
        SizedBox(height: 10),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 48),
          child: Text(
            'Manage your money, access your vault,\nand more from here.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 15,
              height: 1.45,
              color: shellMuted,
            ),
          ),
        ),
      ],
    );
  }
}

class _HomeScenePainter extends CustomPainter {
  const _HomeScenePainter();

  @override
  void paint(Canvas canvas, Size size) {
    final sun = Paint()..color = const Color(0xFFF6D7CC);
    final cloud = Paint()..color = const Color(0xFFF3E4E0);
    final house = Paint()..color = const Color(0xFFF4D2CB);
    final roof = Paint()..color = const Color(0xFFE8B7B0);
    final tree = Paint()..color = const Color(0xFFE7C3BB);
    final ground = Paint()..color = const Color(0xFFF3E6E3);
    final detail = Paint()..color = const Color(0xFFC44747);

    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(size.width * 0.5, size.height * 0.86),
        width: size.width * 0.72,
        height: 28,
      ),
      ground,
    );
    canvas.drawCircle(Offset(size.width * 0.72, size.height * 0.22), 22, sun);
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(size.width * 0.28, size.height * 0.24),
        width: 54,
        height: 22,
      ),
      cloud,
    );
    canvas.drawCircle(Offset(size.width * 0.24, size.height * 0.2), 10, cloud);
    canvas.drawCircle(Offset(size.width * 0.36, size.height * 0.2), 12, cloud);

    _tree(canvas, Offset(size.width * 0.22, size.height * 0.62), tree, detail);
    _tree(canvas, Offset(size.width * 0.78, size.height * 0.66), tree, detail, 0.8);

    final body = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(size.width * 0.5, size.height * 0.62),
        width: 78,
        height: 58,
      ),
      const Radius.circular(8),
    );
    canvas.drawRRect(body, house);

    final roofPath = Path()
      ..moveTo(size.width * 0.5 - 52, size.height * 0.48)
      ..lineTo(size.width * 0.5, size.height * 0.28)
      ..lineTo(size.width * 0.5 + 52, size.height * 0.48)
      ..close();
    canvas.drawPath(roofPath, roof);

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(size.width * 0.5, size.height * 0.7),
          width: 16,
          height: 24,
        ),
        const Radius.circular(3),
      ),
      detail,
    );
    canvas.drawCircle(
      Offset(size.width * 0.42, size.height * 0.58),
      6,
      Paint()..color = const Color(0xFFFFF8F6),
    );
  }

  void _tree(Canvas canvas, Offset base, Paint leaves, Paint trunk, [double scale = 1]) {
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(base.dx, base.dy + 8 * scale),
          width: 6 * scale,
          height: 22 * scale,
        ),
        const Radius.circular(2),
      ),
      trunk,
    );
    canvas.drawCircle(Offset(base.dx, base.dy - 8 * scale), 16 * scale, leaves);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
