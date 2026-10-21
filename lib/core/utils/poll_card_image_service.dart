import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:gal/gal.dart';

class PollCardImageException implements Exception {
  const PollCardImageException(this.message);

  final String message;
}

/// Renders a poll card widget to a transparent PNG and saves it to the gallery.
class PollCardImageService {
  const PollCardImageService();

  /// Renders the [RepaintBoundary] behind [boundaryKey] as PNG bytes. Areas the
  /// widget doesn't paint stay transparent.
  Future<Uint8List> createPng(GlobalKey boundaryKey, {double scale = 3}) async {
    final boundary = boundaryKey.currentContext?.findRenderObject();
    if (boundary is! RenderRepaintBoundary) {
      throw const PollCardImageException('The card is not ready yet.');
    }
    final image = await boundary.toImage(pixelRatio: scale);
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    image.dispose();
    if (data == null) {
      throw const PollCardImageException('Could not render the card.');
    }
    return data.buffer.asUint8List();
  }

  /// Renders the card and saves it to the gallery.
  Future<void> download(GlobalKey boundaryKey) async {
    if (!await Gal.hasAccess() && !await Gal.requestAccess()) {
      throw const PollCardImageException('Photo access was denied.');
    }
    final png = await createPng(boundaryKey);
    await Gal.putImageBytes(
      png,
      name: 'yakku_card_${DateTime.now().millisecondsSinceEpoch}.png',
    );
  }
}
