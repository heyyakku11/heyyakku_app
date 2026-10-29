import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';
import 'package:yakku/presentation/widgets/story_card.dart';

typedef TempDirProvider = Future<Directory> Function();

/// Thrown when a story image could not be produced.
class StoryImageException implements Exception {
  const StoryImageException(this.message, [this.cause]);

  final String message;
  final Object? cause;

  @override
  String toString() => 'StoryImageException: $message';
}

/// Renders the Yakku [StoryCard] to a 1080x1920 PNG in a temp file. The card is
/// painted from its own offscreen render tree, not a screen capture, so it
/// needs no visible widget or BuildContext.
class StoryImageService {
  StoryImageService({
    TempDirProvider tempDir = getTemporaryDirectory,
    ui.FlutterView? view,
  }) : _tempDir = tempDir,
       _view = view;

  final TempDirProvider _tempDir;
  final ui.FlutterView? _view;

  static const int pixelRatio = 3;
  static const int width = 1080;
  static const int height = 1920;
  static const String _folder = 'yakku_story';

  /// Writes the card to a new PNG file and returns it. Stale files from earlier
  /// shares are removed first. Call [delete] once the file has been handed off.
  Future<File> render({
    required String question,
    List<String> options = const [],
  }) async {
    try {
      final bytes = await renderPng(question: question, options: options);
      final dir = Directory('${(await _tempDir()).path}/$_folder');
      await _clearDir(dir);
      await dir.create(recursive: true);
      final file = File(
        '${dir.path}/story_${DateTime.now().microsecondsSinceEpoch}.png',
      );
      return await file.writeAsBytes(bytes, flush: true);
    } on StoryImageException {
      rethrow;
    } catch (e) {
      throw StoryImageException('Could not save the story image.', e);
    }
  }

  /// Encodes the card as PNG bytes (1080x1920).
  Future<Uint8List> renderPng({
    required String question,
    List<String> options = const [],
  }) async {
    if (question.trim().isEmpty) {
      throw const StoryImageException('Question is empty.');
    }
    final view =
        _view ?? WidgetsBinding.instance.platformDispatcher.views.first;
    const size = StoryCard.size;
    final boundary = RenderRepaintBoundary();
    final renderView = RenderView(
      view: view,
      configuration: ViewConfiguration(
        logicalConstraints: BoxConstraints.tight(size),
        physicalConstraints: BoxConstraints.tight(size),
      ),
      child: RenderPositionedBox(child: boundary),
    );
    final pipelineOwner = PipelineOwner()..rootNode = renderView;
    final buildOwner = BuildOwner(focusManager: FocusManager());
    ui.Image? image;
    RenderObjectToWidgetElement<RenderBox>? root;
    try {
      renderView.prepareInitialFrame();
      root = RenderObjectToWidgetAdapter<RenderBox>(
        container: boundary,
        child: Directionality(
          textDirection: TextDirection.ltr,
          child: MediaQuery(
            data: const MediaQueryData(size: size),
            child: StoryCard(question: question, options: options),
          ),
        ),
      ).attachToRenderTree(buildOwner);
      buildOwner
        ..buildScope(root)
        ..finalizeTree();
      pipelineOwner
        ..flushLayout()
        ..flushCompositingBits()
        ..flushPaint();
      image = await boundary.toImage(pixelRatio: pixelRatio.toDouble());
      if (image.width != width || image.height != height) {
        throw StoryImageException(
          'Unexpected image size ${image.width}x${image.height}.',
        );
      }
      final data = await image.toByteData(format: ui.ImageByteFormat.png);
      if (data == null) {
        throw const StoryImageException('Could not encode the story image.');
      }
      return data.buffer.asUint8List();
    } on StoryImageException {
      rethrow;
    } catch (e) {
      throw StoryImageException('Could not render the story image.', e);
    } finally {
      image?.dispose();
      if (root != null) {
        // Unmount the widgets so their render objects are detached cleanly.
        RenderObjectToWidgetAdapter<RenderBox>(
          container: boundary,
        ).attachToRenderTree(buildOwner, root);
        buildOwner
          ..buildScope(root)
          ..finalizeTree();
      }
      pipelineOwner.rootNode = null;
      renderView.dispose();
    }
  }

  /// Removes a file produced by [render]; never throws.
  Future<void> delete(File file) async {
    try {
      if (await file.exists()) await file.delete();
    } catch (e) {
      debugPrint('Story image cleanup failed: $e');
    }
  }

  Future<void> _clearDir(Directory dir) async {
    try {
      if (await dir.exists()) await dir.delete(recursive: true);
    } catch (e) {
      debugPrint('Story image cleanup failed: $e');
    }
  }
}
