import 'package:flutter/cupertino.dart';

class BrandLogo extends StatelessWidget {
  final double size;
  const BrandLogo({super.key, required this.size});
  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    padding: EdgeInsets.all(size * .08),
    decoration: BoxDecoration(
      color: const Color(0xFFF3F8F6),
      borderRadius: BorderRadius.circular(size * .24),
    ),
    child: Image.asset(
      'assets/lokale-app-icon.png',
      fit: BoxFit.contain,
    ),
  );
}

