import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// Draws the display lettering used in the MEMBER and stadium content.
class SiteDisplayHeading extends StatelessWidget {
  const SiteDisplayHeading(
    this.label, {
    super.key,
    required this.size,
    required this.accent,
  });

  final String label;
  final double size;
  final int accent;

  @override
  Widget build(BuildContext context) {
    if (label.trim().isEmpty) return const SizedBox.shrink();
    final letters = label.split('').map((letter) {
      return _glyphs[letter] ?? _glyphs[letter.toUpperCase()];
    }).toList();
    if (letters.contains(null)) return _fallback();

    var offset = 0;
    final paths = StringBuffer();
    for (final (index, glyph) in letters.indexed) {
      final (width, path) = glyph!;
      if (path.isNotEmpty) {
        final color = index == accent ? '#ff0000' : '#002b6d';
        paths.write(
          '<path transform="translate($offset 0)" fill="$color" fill-rule="evenodd" d="$path"/>',
        );
      }
      offset += width + 5;
    }
    final width = offset - 5;
    final visualWidth = switch (label) {
      'MeMBeRS' => 174.0,
      'HOST INFORMATION' => 319.0,
      'HOST STADIUM' => 183.0,
      _ => size * width / 66 * .91,
    };
    final viewWidth = visualWidth * 66 / size;
    final height = MediaQuery.textScalerOf(context).scale(size);
    final displayWidth = height * viewWidth / 66;
    return LayoutBuilder(
      builder: (context, constraints) {
        if (displayWidth > constraints.maxWidth) return _fallback();
        return SvgPicture.string(
          '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 -4 $viewWidth 66"><g transform="scale(${viewWidth / width} 1)">$paths</g></svg>',
          height: height,
          width: displayWidth,
          semanticsLabel: label.toUpperCase(),
        );
      },
    );
  }

  Widget _fallback() => Text.rich(
        TextSpan(
          children: [
            for (final (index, letter) in label.split('').indexed)
              TextSpan(
                text: letter,
                style: index == accent
                    ? const TextStyle(color: Color(0xffff0000))
                    : null,
              ),
          ],
        ),
        style: TextStyle(
          fontFamily: 'LINESeedJPExtraBold',
          fontWeight: FontWeight.w800,
          fontSize: size,
          height: 1,
          color: const Color(0xff002b6d),
        ),
      );

  static const _glyphs = <String, (int, String)>{
    ' ': (16, ''),
    'A': (55, 'M19 1H36L55 57H40L37 47H18L15 57H0ZM22 34H33L28 16Z'),
    'B': (
      40,
      'M0 1H18C31 1 37 8 37 17C37 23 35 27 30 29C36 31 40 35 40 42C40 52 33 57 19 57H0ZM14 13V23H19C23 23 25 21 25 18C25 15 23 13 19 13ZM14 34V45H20C24 45 26 43 26 39C26 36 24 34 20 34Z',
    ),
    'C': (
      58,
      'M57 20H42C39 15 35 13 29 13C20 13 13 20 13 29C13 38 20 45 29 45C35 45 39 43 42 38H57C53 50 42 58 29 58C13 58 0 45 0 29C0 13 13 0 29 0C42 0 53 8 57 20Z',
    ),
    'D': (
      53,
      'M0 1H22C40 1 53 12 53 29C53 46 40 57 22 57H0ZM14 14V44H21C32 44 39 38 39 29C39 20 32 14 21 14Z',
    ),
    'E': (37, 'M0 1H37V14H14V23H35V35H14V44H37V57H0Z'),
    'e': (
      58,
      'M29 0C45 0 58 12 58 28V33H14C16 41 22 46 30 46C36 46 41 43 44 39H57C53 51 42 58 29 58C13 58 0 45 0 29C0 13 13 0 29 0ZM15 23H43C41 16 36 12 29 12C22 12 17 16 15 23Z',
    ),
    'F': (37, 'M0 1H37V14H14V24H34V37H14V57H0Z'),
    'G': (
      59,
      'M57 20H42C39 15 35 13 29 13C20 13 13 20 13 29C13 38 20 45 29 45C35 45 41 42 44 36H28V24H59V29C59 45 46 58 29 58C13 58 0 45 0 29C0 13 13 0 29 0C42 0 53 8 57 20Z',
    ),
    'H': (45, 'M0 1H14V22H31V1H45V57H31V36H14V57H0Z'),
    'I': (14, 'M0 1H14V57H0Z'),
    'K': (47, 'M0 1H14V25L30 1H46L27 28L47 57H30L14 32V57H0Z'),
    'L': (36, 'M0 1H14V44H36V57H0Z'),
    'M': (64, 'M0 1H18L32 38L46 1H64V57H50V24L38 57H26L14 24V57H0Z'),
    'N': (48, 'M0 1H14L34 33V1H48V57H34L14 25V57H0Z'),
    'O': (
      58,
      'M29 0A29 29 0 1 1 29 58A29 29 0 1 1 29 0ZM29 13A16 16 0 1 1 29 45A16 16 0 1 1 29 13Z',
    ),
    'P': (
      41,
      'M0 1H19C33 1 41 9 41 22C41 35 33 43 19 43H14V57H0ZM14 14V30H18C24 30 27 27 27 22C27 17 24 14 18 14Z',
    ),
    'R': (
      41,
      'M0 1H18C31 1 39 9 39 22C39 30 36 35 31 39L41 57H26L19 45H14V57H0ZM14 14V32H18C23 32 26 29 26 23C26 17 23 14 18 14Z',
    ),
    'S': (
      27,
      'M27 0V14C22 14 20 18 20 24V34C20 49 12 58 0 58V44C5 44 7 40 7 34V24C7 9 14 0 27 0Z',
    ),
    'T': (42, 'M0 1H42V14H28V57H14V14H0Z'),
    'U': (
      49,
      'M0 1H14V34C14 41 18 45 24 45C31 45 35 41 35 34V1H49V34C49 49 39 58 24 58C9 58 0 49 0 34Z',
    ),
    'W': (76, 'M0 1H15L23 37L31 1H45L53 37L61 1H76L61 57H46L38 24L30 57H15Z'),
    'Y': (49, 'M0 1H16L25 20L34 1H49L32 35V57H18V35Z'),
    '8': (
      44,
      'M22 0C34 0 42 7 42 17C42 23 39 27 35 29C41 32 44 36 44 43C44 52 35 58 22 58C9 58 0 52 0 43C0 36 3 32 9 29C5 27 2 23 2 17C2 7 10 0 22 0ZM22 11C18 11 15 14 15 18C15 22 18 24 22 24C26 24 29 22 29 18C29 14 26 11 22 11ZM22 34C17 34 14 37 14 41C14 45 17 48 22 48C27 48 30 45 30 41C30 37 27 34 22 34Z',
    ),
  };
}
