import 'package:flutter/material.dart';
import 'package:yakku/core/constants/app_spacing.dart';

class TermsOfServiceScreen extends StatelessWidget {
  const TermsOfServiceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Terms of Service ')),
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
                'Welcome to Yakku. By using Yakku, you agree to these Terms of Service.',
                style: TextStyle(fontSize: 13),
              ),
              const SizedBox(height: 18),

              //para 2
              const Text(
                'Using Yakku',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
              ),
              const SizedBox(height: 8),
              const Text(
                'You may use Yakku for personal and lawful purposes. You agree not to misuse the app, disrupt its services, or use it for illegal activities.',
                style: TextStyle(fontSize: 13),
              ),
              const SizedBox(height: 18),

              //para 3
              const Text(
                'Your Account',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
              ),
              const SizedBox(height: 8),
              const Text(
                'You are responsible for keeping your account information secure and for activity performed through your account.',
                style: TextStyle(fontSize: 13),
              ),
              const SizedBox(height: 18),

              //para 4
              const Text(
                'Your Content',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
              ),
              const SizedBox(height: 8),
              const Text(
                'You own the content you create and share on Yakku. By posting content, you give Yakku permission to display and use it as necessary to provide the service.\n\nYou must not post content that is illegal, harmful, abusive, misleading, or violates another person\'s rights.',
                style: TextStyle(fontSize: 13),
              ),
              const SizedBox(height: 18),

              //para 5
              const Text(
                'Other Users',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
              ),
              const SizedBox(height: 8),
              const Text(
                'Please treat other users respectfully. Yakku is not responsible for interactions or transactions between users.',
                style: TextStyle(fontSize: 13),
              ),
              const SizedBox(height: 18),

              //para 6
              const Text(
                'Service Availability',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
              ),
              const SizedBox(height: 8),
              const Text(
                'We aim to keep Yakku available and reliable, but we cannot guarantee that the service will always be available or error-free.',
                style: TextStyle(fontSize: 13),
              ),
              const SizedBox(height: 18),

              //para 7
              const Text(
                'Account Termination',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
              ),
              const SizedBox(height: 8),
              const Text(
                'We may suspend or terminate accounts that violate these Terms or misuse Yakku.',
                style: TextStyle(fontSize: 13),
              ),
              const SizedBox(height: 18),

              //para 8
              const Text(
                'Changes to These Terms',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
              ),
              const SizedBox(height: 8),
              const Text(
                'We may update these Terms from time to time. Continued use of Yakku after changes means you accept the updated Terms.',
                style: TextStyle(fontSize: 13),
              ),
              const SizedBox(height: 18),

              //para 9
              const Text(
                'Contact',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
              ),
              const SizedBox(height: 8),
              const Text(
                'If you have questions about these Terms, contact us at support@heyyaku.com.',
                style: TextStyle(fontSize: 13),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
