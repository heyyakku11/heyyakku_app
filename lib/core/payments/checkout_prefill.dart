/// Helpers for Razorpay Checkout prefill / display fields.
abstract final class CheckoutPrefill {
  /// Razorpay expects a 10-digit Indian mobile for `prefill.contact`.
  ///
  /// Strips non-digits and keeps the last 10 when longer (e.g. `+91…`).
  /// Returns null when there are not enough digits.
  static String? contact(String? raw) {
    if (raw == null) return null;
    final digits = raw.replaceAll(RegExp(r'\D'), '');
    if (digits.length >= 10) {
      return digits.substring(digits.length - 10);
    }
    return null;
  }

  /// Trims email; empty becomes null.
  static String? email(String? raw) {
    final value = raw?.trim();
    if (value == null || value.isEmpty) return null;
    return value;
  }
}
