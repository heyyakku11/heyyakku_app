# Razorpay Checkout (required when minify/shrink is enabled for release).
# See https://pub.dev/packages/razorpay_flutter
-keepattributes *Annotation*
-dontwarn com.razorpay.**
-keep class com.razorpay.** {*;}
-optimizations !method/inlining/
-keepclasseswithmembers class * {
  public void onPayment*(...);
}
