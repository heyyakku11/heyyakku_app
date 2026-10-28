import 'package:flutter/material.dart';
import 'package:yakku/core/theme/yakku_palette.dart';
import 'package:yakku/presentation/widgets/mobile_login_bottom_sheet.dart';
import 'package:yakku/presentation/widgets/otp_bottom_sheet.dart';

const _sheetShape = RoundedRectangleBorder(
  borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
);

/// Mobile (+91) then OTP sheets used by Activity, You tab, and guest login.
///
/// Credentials sheet enqueues send-OTP on the background worker and returns
/// immediately; [OtpBottomSheet] observes the in-flight send.
Future<void> openMobileLogin(BuildContext context) async {
  final sent = await showModalBottomSheet<MobileLoginResult>(
    context: context,
    isScrollControlled: true,
    backgroundColor: YakkuPalette.cream,
    shape: _sheetShape,
    builder: (context) => const MobileLoginBottomSheet(),
  );
  if (!context.mounted || sent == null) return;

  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    isDismissible: false,
    enableDrag: false,
    backgroundColor: YakkuPalette.white,
    shape: _sheetShape,
    builder: (context) {
      return OtpBottomSheet(phone: sent.phone, firstName: sent.firstName);
    },
  );
}
