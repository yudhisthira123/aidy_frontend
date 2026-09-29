import 'package:flutter/material.dart' as material;

import 'app_localizations.dart';

material.InputDecoration localizedInput(
  material.BuildContext context,
  material.InputDecoration decoration,
) {
  final strings = AppLocalizations.of(context);
  String? localize(String? value) => value == null ? null : strings.t(value);
  return decoration.copyWith(
    labelText: localize(decoration.labelText),
    hintText: localize(decoration.hintText),
    helperText: localize(decoration.helperText),
  );
}

/// Drop-in text widget for system-owned copy. Unknown values (including user
/// content) are returned unchanged by [AppLocalizations].
class Text extends material.StatelessWidget {
  const Text(
    this.data, {
    super.key,
    this.style,
    this.strutStyle,
    this.textAlign,
    this.textDirection,
    this.locale,
    this.softWrap,
    this.overflow,
    this.textScaler,
    this.maxLines,
    this.semanticsLabel,
    this.textWidthBasis,
    this.textHeightBehavior,
    this.selectionColor,
  });

  final String data;
  final material.TextStyle? style;
  final material.StrutStyle? strutStyle;
  final material.TextAlign? textAlign;
  final material.TextDirection? textDirection;
  final material.Locale? locale;
  final bool? softWrap;
  final material.TextOverflow? overflow;
  final material.TextScaler? textScaler;
  final int? maxLines;
  final String? semanticsLabel;
  final material.TextWidthBasis? textWidthBasis;
  final material.TextHeightBehavior? textHeightBehavior;
  final material.Color? selectionColor;

  material.TextStyle? _accessibleStyle(material.BuildContext context) {
    if (style == null ||
        material.Theme.of(context).brightness != material.Brightness.dark) {
      return style;
    }
    final color = style!.color;
    if (color == const material.Color(0xFF1B1D36)) {
      return style!.copyWith(
        color: material.Theme.of(context).colorScheme.onSurface,
      );
    }
    if (color == const material.Color(0xFF627178) ||
        color == const material.Color(0xFF60766E) ||
        color == const material.Color(0xFF68777C) ||
        color == const material.Color(0xFF718087) ||
        color == const material.Color(0xFF76758A)) {
      return style!.copyWith(
        color: material.Theme.of(context).colorScheme.onSurfaceVariant,
      );
    }
    return style;
  }

  @override
  material.Widget build(material.BuildContext context) => material.Text(
    AppLocalizations.of(context).t(data),
    style: _accessibleStyle(context),
    strutStyle: strutStyle,
    textAlign: textAlign,
    textDirection: textDirection,
    locale: locale,
    softWrap: softWrap,
    overflow: overflow,
    textScaler: textScaler,
    maxLines: maxLines,
    semanticsLabel: semanticsLabel,
    textWidthBasis: textWidthBasis,
    textHeightBehavior: textHeightBehavior,
    selectionColor: selectionColor,
  );
}
