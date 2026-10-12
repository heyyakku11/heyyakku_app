import 'package:flutter/material.dart';
import 'package:yakku/presentation/widgets/email_login_bottom_sheet.dart';
import 'package:yakku/presentation/widgets/otp_bottom_sheet.dart';

const _sheetShape = RoundedRectangleBorder(
  borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
);

/// Email then OTP sheets used by onboarding and the guest You tab.
Future<void> openEmailLogin(BuildContext context) async {
  final sent = await showModalBottomSheet<EmailLoginResult>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    shape: _sheetShape,
    builder: (context) => const EmailLoginBottomSheet(),
  );
  if (!context.mounted || sent == null) return;

  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    isDismissible: false,
    enableDrag: false,
    backgroundColor: Colors.white,
    shape: _sheetShape,
    builder: (context) {
      return OtpBottomSheet(
        email: sent.email,
        expiresInMinutes: sent.expiresInMinutes,
      );
    },
  );
}
