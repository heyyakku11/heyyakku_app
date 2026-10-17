import 'package:flutter/material.dart';
import 'package:yakku/core/network/dio_error_mapper.dart';
import 'package:yakku/data/models/checks/user_check_response.dart';
import 'package:yakku/data/models/home/mirror_check.dart';
import 'package:yakku/data/repositories/check_api_repository.dart';
import 'package:yakku/presentation/app_scope.dart';
import 'package:yakku/presentation/screens/home/home_feed_dummy.dart';
import 'package:yakku/presentation/screens/home/widgets/home_feed_body.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  CheckApiRepository? _checkApi;
  bool? _wasLoggedIn;

  List<MirrorCheck> _checks = const [];
  List<UserCheckResponse> _myChecks = const [];
  bool _loading = true;
  String? _error;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final scope = AppScope.of(context);

    if (!identical(_checkApi, scope.checkApi)) {
      _checkApi?.removeListener(_load);
      _checkApi = scope.checkApi..addListener(_load);
    }

    // Reload when the user signs in or out (their made checks change).
    final loggedIn = scope.authController.isLoggedIn;
    if (_wasLoggedIn != loggedIn) {
      _wasLoggedIn = loggedIn;
      _load();
    }
  }

  @override
  void dispose() {
    _checkApi?.removeListener(_load);
    super.dispose();
  }

  Future<void> _load() async {
    final api = _checkApi;
    if (api == null) return;

    try {
      final data = await api.loadHome(loggedIn: _wasLoggedIn ?? false);
      if (!mounted) return;
      setState(() {
        _checks = [
          for (final check in data.checks) MirrorCheck.fromCheck(check),
        ];
        _myChecks = data.myChecks;
        _error = null;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = DioErrorMapper.map(
          error,
          fallback: 'Could not load checks. Pull down to retry.',
        ).message;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _load,
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : HomeFeedBody(
                  mirrorChecks: _checks,
                  myChecks: _myChecks,
                  questionsWorthAsking: questionsWorthAsking,
                  errorMessage: _checks.isEmpty ? _error : null,
                ),
        ),
      ),
    );
  }
}
