import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

/// Affiche un texte Markdown (titres `##`, gras `**`, listes `-`)
/// correctement rendu au lieu d'afficher les caractères bruts.
class MarkdownText extends StatelessWidget {
  final String data;
  final TextStyle? style;

  const MarkdownText(
    this.data, {
    super.key,
    this.style,
  });

  @override
  Widget build(BuildContext context) {
    final base = style ?? DefaultTextStyle.of(context).style;
    final fontSize = base.fontSize ?? 14;
    final theme = MarkdownStyleSheet.fromTheme(Theme.of(context));
    return MarkdownBody(
      data: data,
      selectable: false,
      softLineBreak: true,
      styleSheet: theme.copyWith(
        p: base,
        h1: base.copyWith(
          fontSize: fontSize * 1.4,
          fontWeight: FontWeight.w700,
        ),
        h2: base.copyWith(
          fontSize: fontSize * 1.25,
          fontWeight: FontWeight.w700,
        ),
        h3: base.copyWith(
          fontSize: fontSize * 1.1,
          fontWeight: FontWeight.w700,
        ),
        strong: base.copyWith(fontWeight: FontWeight.w700),
        em: base.copyWith(fontStyle: FontStyle.italic),
        listBullet: base,
        blockSpacing: 6,
      ),
    );
  }
}
