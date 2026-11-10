import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:yakku/core/network/api_exception.dart';
import 'package:yakku/core/network/dio_error_mapper.dart';
import 'package:yakku/core/profile/avatar_preferences.dart';
import 'package:yakku/core/theme/yakku_palette.dart';
import 'package:yakku/presentation/app_scope.dart';
import 'package:yakku/presentation/screens/profile/widgets/profile_avatar.dart';
import 'package:yakku/presentation/widgets/app_toast.dart';

/// Change the anonymous name (the server picks a new unique one) and the
/// avatar's background colour (kept on this device).
class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({
    super.key,
    required this.name,
    required this.avatarColor,
  });

  final String name;
  final AvatarColor avatarColor;

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  late String _name = widget.name;
  late AvatarColor _color = widget.avatarColor;
  bool _regenerating = false;

  final _avatarPrefs = AvatarPreferences();

  Future<void> _regenerate() async {
    if (_regenerating) return;
    final scope = AppScope.of(context);
    setState(() => _regenerating = true);
    try {
      final name = await scope.userRemote.regenerateAnonymousName();
      await scope.authController.updateDisplayName(name);
      if (!mounted) return;
      setState(() => _name = name);
    } catch (error) {
      if (!mounted) return;
      AppToast.show(_errorMessage(error));
    } finally {
      if (mounted) setState(() => _regenerating = false);
    }
  }

  String _errorMessage(Object error) {
    final api = DioErrorMapper.map(
      error,
      fallback: 'Could not change your name. Please try again.',
    );
    if (api.code == 'ANONYMOUS_NAME_UNAVAILABLE') {
      return 'Could not find a free name right now. Please try again.';
    }
    return switch (api.kind) {
      ApiErrorKind.rateLimited =>
        'You are changing your name too fast. Try again in a minute.',
      ApiErrorKind.connection ||
      ApiErrorKind.timeout => 'No connection. Check your network and retry.',
      _ => api.message,
    };
  }

  /// Applies the colour straight away and remembers it on this device.
  void _pickColor(AvatarColor color) {
    if (color.id == _color.id) return;
    HapticFeedback.selectionClick();
    setState(() => _color = color);
    _avatarPrefs.save(color);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: YakkuPalette.cream,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(
                height: 48,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Align(
                      alignment: Alignment.centerLeft,
                      child: IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        tooltip: 'Close',
                        icon: const Icon(
                          Icons.close_rounded,
                          color: YakkuPalette.Ink,
                        ),
                      ),
                    ),
                    const Text(
                      'Edit',
                      style: TextStyle(
                        color: YakkuPalette.Ink,
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Center(child: ProfileAvatar(color: _color.color, size: 84)),
              const SizedBox(height: 28),
              const Text(
                'Your anonymous name',
                style: TextStyle(
                  color: YakkuPalette.Ink,
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 18,
                ),
                decoration: BoxDecoration(
                  color: YakkuPalette.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: YakkuPalette.roseBorder),
                ),
                child: Text(
                  _name,
                  style: const TextStyle(
                    color: YakkuPalette.Ink,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.3,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'Nobody ever knows who you are',
                style: TextStyle(
                  color: YakkuPalette.textSecondary,
                  fontSize: 12.5,
                ),
              ),
              const SizedBox(height: 14),
              SizedBox(
                height: 52,
                child: FilledButton(
                  onPressed: _regenerating ? null : _regenerate,
                  style: FilledButton.styleFrom(
                    backgroundColor: AvatarColors.lavender.color,
                    disabledBackgroundColor: AvatarColors.lavender.color,
                    foregroundColor: YakkuPalette.Ink,
                    disabledForegroundColor: YakkuPalette.Ink,
                    shape: const StadiumBorder(),
                  ),
                  child: _regenerating
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.2,
                            color: YakkuPalette.Ink,
                          ),
                        )
                      : const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            FaIcon(FontAwesomeIcons.shuffle, size: 15),
                            SizedBox(width: 10),
                            Text(
                              'Give me another name',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                ),
              ),
              const SizedBox(height: 26),
              const Text(
                'Avatar',
                style: TextStyle(
                  color: YakkuPalette.Ink,
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  for (final option in AvatarColors.all)
                    _ColorDot(
                      option: option,
                      selected: option.id == _color.id,
                      onTap: () => _pickColor(option),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ColorDot extends StatelessWidget {
  const _ColorDot({
    required this.option,
    required this.selected,
    required this.onTap,
  });

  final AvatarColor option;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: 'Avatar colour ${option.id}',
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          width: 46,
          height: 46,
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: selected ? YakkuPalette.Raspberry : Colors.transparent,
              width: 2,
            ),
          ),
          child: DecoratedBox(
            decoration: BoxDecoration(shape: BoxShape.circle, color: option.color),
          ),
        ),
      ),
    );
  }
}
