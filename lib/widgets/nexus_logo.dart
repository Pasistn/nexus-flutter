import 'package:flutter/material.dart';

class NexusLogo extends StatelessWidget {
  const NexusLogo({super.key, this.size = 40});

  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: size,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(size / 4),
        child: Transform.scale(
          scale: 1.55,
          child: Image.asset('assets/images/nexus_logo.png', fit: BoxFit.cover),
        ),
      ),
    );
  }
}
