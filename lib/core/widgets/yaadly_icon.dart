import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// Icon set from the design (`ui.tsx`), drawn as 24×24 SVG paths so they match exactly.
enum YaadlyIcons {
  mic('M12 14a3 3 0 0 0 3-3V6a3 3 0 0 0-6 0v5a3 3 0 0 0 3 3Zm5-3a5 5 0 0 1-10 0H5a7 7 0 0 0 6 6.92V21h2v-3.08A7 7 0 0 0 19 11h-2Z'),
  cal('M7 2v2H5a2 2 0 0 0-2 2v13a2 2 0 0 0 2 2h14a2 2 0 0 0 2-2V6a2 2 0 0 0-2-2h-2V2h-2v2H9V2H7Zm9.7 8.7-5 5a1 1 0 0 1-1.4 0l-2-2 1.4-1.4 1.3 1.3 4.3-4.3 1.4 1.4Z'),
  check('M9.5 16.2 5.3 12l-1.4 1.4 5.6 5.6L21 7.4 19.6 6 9.5 16.2Z'),
  basket('M5.5 9 9 3h2L8 9h8l-3-6h2l3.5 6H22v2h-1l-1.6 9a2 2 0 0 1-2 1.6H6.6a2 2 0 0 1-2-1.6L3 11H2V9h3.5ZM9 13v5h2v-5H9Zm4 0v5h2v-5h-2Z'),
  link('M10.6 13.4a1 1 0 0 1 0-1.4l3-3a3 3 0 0 1 4.2 4.2l-2 2-1.4-1.4 2-2a1 1 0 0 0-1.4-1.4l-3 3a1 1 0 0 1-1.4 0ZM13.4 10.6a1 1 0 0 1 0 1.4l-3 3a3 3 0 0 1-4.2-4.2l2-2 1.4 1.4-2 2a1 1 0 0 0 1.4 1.4l3-3a1 1 0 0 1 1.4 0Z'),
  play('M8 5v14l11-7L8 5Z'),
  plus('M11 5h2v6h6v2h-6v6h-2v-6H5v-2h6V5Z'),
  back('M15.4 5.6 9 12l6.4 6.4-1.4 1.4L6.2 12 14 4.2l1.4 1.4Z'),
  chev('M8.6 5.6 15 12l-6.4 6.4 1.4 1.4L17.8 12 10 4.2 8.6 5.6Z'),
  today('M12 2a10 10 0 1 0 0 20 10 10 0 0 0 0-20Zm1 5v5.4l3.7 2.2-1 1.7L11 13V7h2Z'),
  inbox('M4 4h16a1 1 0 0 1 1 1v14a1 1 0 0 1-1 1H4a1 1 0 0 1-1-1V5a1 1 0 0 1 1-1Zm1 11v3h14v-3h-4a3 3 0 0 1-6 0H5Z'),
  list('M4 6h2v2H4V6Zm4 0h12v2H8V6Zm-4 5h2v2H4v-2Zm4 0h12v2H8v-2Zm-4 5h2v2H4v-2Zm4 0h12v2H8v-2Z'),
  more('M5 10a2 2 0 1 1 0 4 2 2 0 0 1 0-4Zm7 0a2 2 0 1 1 0 4 2 2 0 0 1 0-4Zm7 0a2 2 0 1 1 0 4 2 2 0 0 1 0-4Z'),
  warn('M12 3 1.5 21h21L12 3Zm-1 7h2v5h-2v-5Zm0 6.5h2v2h-2v-2Z'),
  copy('M8 3h11a2 2 0 0 1 2 2v12h-2V5H8V3ZM5 7h10a2 2 0 0 1 2 2v11a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2V9a2 2 0 0 1 2-2Z'),
  x('m6.4 5 5.6 5.6L17.6 5 19 6.4 13.4 12l5.6 5.6-1.4 1.4-5.6-5.6L6.4 19 5 17.6l5.6-5.6L5 6.4 6.4 5Z'),
  bolt('M13 2 4 14h6l-1 8 9-12h-6l1-8Z');

  const YaadlyIcons(this.path);
  final String path;
}

class YaadlyIcon extends StatelessWidget {
  const YaadlyIcon(this.icon, {super.key, this.size = 20, this.color});

  final YaadlyIcons icon;
  final double size;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final c = color ?? IconTheme.of(context).color ?? DefaultTextStyle.of(context).style.color!;
    return ExcludeSemantics(
      child: SvgPicture.string(
        '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24"><path d="${icon.path}"/></svg>',
        width: size,
        height: size,
        colorFilter: ColorFilter.mode(c, BlendMode.srcIn),
      ),
    );
  }
}
