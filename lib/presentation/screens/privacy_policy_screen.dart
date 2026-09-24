import 'package:flutter/material.dart';
import 'package:yakku/core/constants/app_spacing.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Privacy Policy')),
      body: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.screen,
            AppSpacing.screen,
            AppSpacing.screen,
            AppSpacing.xxl,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              //para 1
              const Text(
                'Last updated: September 8, 2026',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
              ),
              const SizedBox(height: 8),
              const Text(
                'Yakku respects your privacy. This Privacy Policy explains how we collect and use your information when you use the Yakku app.',
                style: TextStyle(fontSize: 13),
              ),
              const SizedBox(height: 18),

              //para 2
              const Text(
                'Information We Collect',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
              ),
              const SizedBox(height: 8),
              const Text(
                'We may collect information such as your name, email, address, account information, and content you crete or submit in the app.',
                style: TextStyle(fontSize: 13),
              ),
              const SizedBox(height: 18),

              //para 3
              const Text(
                'How We Use Your Information',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
              ),
              const SizedBox(height: 8),
              const Text(
                'We use your information to:',
                style: TextStyle(fontSize: 13),
              ),
              const SizedBox(height: 8),
              bulletItem('Provide and improve Yakku features.'),
              bulletItem('Manage your account and authentication.'),
              bulletItem('Store and sync your data.'),
              bulletItem('Keep the app secure.'),
              const SizedBox(height: 18),

              //para 4
              const Text(
                'Data Security',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
              ),
              const SizedBox(height: 8),
              const Text(
                'We take reasonable measures to protect your information. However, no online service can guarantee complete security.',
                style: TextStyle(fontSize: 13),
              ),
              const SizedBox(height: 18),

              //para 5
              const Text(
                'Third-Party Services',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
              ),
              const SizedBox(height: 8),
              const Text(
                'Yakku may use trusted third-party services for services such as authentication, database hosting, analytics, or app functionality.',
                style: TextStyle(fontSize: 13),
              ),
              const SizedBox(height: 18),

              //para 6
              const Text(
                'Your Data',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
              ),
              const SizedBox(height: 8),
              const Text(
                'You may request access to or deletion of your personal data by contacting us.',
                style: TextStyle(fontSize: 13),
              ),
              const SizedBox(height: 18),

              //para 7
              const Text(
                'Changes',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
              ),
              const SizedBox(height: 8),
              const Text(
                'We may update this Privacy Policy from time to time. Any changes will be reflected in the app or on this page.',
                style: TextStyle(fontSize: 13),
              ),
              const SizedBox(height: 18),

              //para 8
              const Text(
                'Contact',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
              ),
              const SizedBox(height: 8),
              const Text(
                'If you have questions about this Privacy Policy, contact us at support@heyyakku.com.',
                style: TextStyle(fontSize: 13),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

Widget bulletItem(String text) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('•  '),
        Expanded(child: Text(text)),
      ],
    ),
  );
}
