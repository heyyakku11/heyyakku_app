import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:yakku/core/network/dio_error_mapper.dart';
import 'package:yakku/core/theme/yakku_palette.dart';
import 'package:yakku/data/models/ask_back/ask_back_models.dart';
import 'package:yakku/presentation/app_scope.dart';
import 'package:yakku/presentation/widgets/app_toast.dart';
import 'package:yakku/presentation/widgets/skeleton.dart';

/// People the signed-in user blocked from Ask Back; unblock from here.
class BlockedUsersScreen extends StatefulWidget {
  const BlockedUsersScreen({super.key});

  @override
  State<BlockedUsersScreen> createState() => _BlockedUsersScreenState();
}

class _BlockedUsersScreenState extends State<BlockedUsersScreen> {
  final List<AskBackBlockItem> _items = [];
  bool _loading = true;
  bool _loadingMore = false;
  bool _unblocking = false;
  String? _error;
  int _page = 0;
  bool _hasMore = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadFirstPage());
  }

  Future<void> _loadFirstPage() async {
    setState(() {
      _loading = true;
      _error = null;
      _page = 0;
      _hasMore = true;
    });
    try {
      final page = await AppScope.of(context).askBack.listBlocks(page: 1);
      if (!mounted) return;
      setState(() {
        _items
          ..clear()
          ..addAll(page.items);
        _page = page.page;
        _hasMore = page.hasMore;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = DioErrorMapper.map(
          error,
          fallback: 'Could not load blocked people.',
        ).message;
      });
    }
  }

  Future<void> _loadMore() async {
    if (_loadingMore || !_hasMore) return;
    setState(() => _loadingMore = true);
    try {
      final page = await AppScope.of(
        context,
      ).askBack.listBlocks(page: _page + 1);
      if (!mounted) return;
      setState(() {
        _items.addAll(page.items);
        _page = page.page;
        _hasMore = page.hasMore;
        _loadingMore = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() => _loadingMore = false);
      AppToast.show(
        DioErrorMapper.map(
          error,
          fallback: 'Could not load more.',
        ).message,
      );
    }
  }

  Future<void> _confirmUnblock(AskBackBlockItem item) async {
    final name = item.anonymousName.isEmpty ? 'this person' : item.anonymousName;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Unblock?'),
          content: Text(
            'Unblock $name? They will be able to vote on your cards and '
            'ask you back again.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Unblock'),
            ),
          ],
        );
      },
    );
    if (confirmed != true || !mounted) return;
    await _unblock(item);
  }

  Future<void> _unblock(AskBackBlockItem item) async {
    if (_unblocking) return;
    setState(() => _unblocking = true);
    try {
      await AppScope.of(context).askBack.unblockByBlockId(item.blockId);
      if (!mounted) return;
      setState(() {
        _items.removeWhere((row) => row.blockId == item.blockId);
        _unblocking = false;
      });
      AppToast.show('Unblocked');
    } catch (error) {
      if (!mounted) return;
      setState(() => _unblocking = false);
      AppToast.show(
        DioErrorMapper.map(error, fallback: 'Could not unblock').message,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: YakkuPalette.cream,
      appBar: AppBar(
        backgroundColor: YakkuPalette.cream,
        surfaceTintColor: Colors.transparent,
        scrolledUnderElevation: 0,
        centerTitle: true,
        leading: IconButton(
          onPressed: () => Navigator.of(context).maybePop(),
          tooltip: 'Back',
          icon: const FaIcon(
            FontAwesomeIcons.chevronLeft,
            size: 16,
            color: YakkuPalette.Ink,
          ),
        ),
        title: const Text(
          'Blocked',
          style: TextStyle(
            color: YakkuPalette.Ink,
            fontSize: 17,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _loadFirstPage,
        child: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (_loading && _items.isEmpty && _error == null) {
      return const _BlockedUsersSkeleton();
    }

    if (_error != null && _items.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(24, 48, 24, 24),
        children: [
          Text(
            _error!,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: YakkuPalette.textSecondary,
              fontSize: 14,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 16),
          Center(
            child: TextButton(
              onPressed: _loadFirstPage,
              child: const Text('Try again'),
            ),
          ),
        ],
      );
    }

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
      children: [
        if (_items.isEmpty)
          SizedBox(
            height: MediaQuery.sizeOf(context).height * 0.55,
            child: const _BlockedEmptyState(),
          )
        else
          for (final item in _items) ...[
            _BlockedUserTile(
              item: item,
              busy: _unblocking,
              onUnblock: () => _confirmUnblock(item),
            ),
            const SizedBox(height: 10),
          ],
        if (_loadingMore) ...[
          const SizedBox(height: 4),
          const SkeletonPulse(child: _BlockedTileSkeleton()),
        ] else if (_hasMore && _items.isNotEmpty) ...[
          const SizedBox(height: 8),
          Center(
            child: TextButton(
              onPressed: _loadMore,
              child: const Text('Load more'),
            ),
          ),
        ],
      ],
    );
  }
}

class _BlockedUsersSkeleton extends StatelessWidget {
  const _BlockedUsersSkeleton();

  @override
  Widget build(BuildContext context) {
    return SkeletonPulse(
      child: ListView(
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
        children: const [
          _BlockedTileSkeleton(),
          SizedBox(height: 10),
          _BlockedTileSkeleton(),
          SizedBox(height: 10),
          _BlockedTileSkeleton(),
          SizedBox(height: 10),
          _BlockedTileSkeleton(),
        ],
      ),
    );
  }
}

class _BlockedTileSkeleton extends StatelessWidget {
  const _BlockedTileSkeleton();

  @override
  Widget build(BuildContext context) {
    return Material(
      color: YakkuPalette.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(22),
        side: const BorderSide(color: YakkuPalette.roseBorder, width: 1.2),
      ),
      child: const Padding(
        padding: EdgeInsets.fromLTRB(14, 14, 14, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                SkeletonBox(width: 44, height: 44, radius: 14),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SkeletonBox(width: 140, height: 14, radius: 7),
                      SizedBox(height: 8),
                      SkeletonBox(width: 100, height: 11, radius: 6),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: 14),
            SkeletonBox(height: 44, radius: 22),
          ],
        ),
      ),
    );
  }
}

class _BlockedEmptyState extends StatelessWidget {
  const _BlockedEmptyState();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 36),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 88,
            height: 88,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: YakkuPalette.Blush.withValues(alpha: 0.55),
              borderRadius: BorderRadius.circular(28),
            ),
            child: const FaIcon(
              FontAwesomeIcons.ban,
              size: 32,
              color: YakkuPalette.Raspberry,
            ),
          ),
          const SizedBox(height: 22),
          const Text(
            'No blocked people',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: YakkuPalette.Ink,
              fontSize: 24,
              height: 1.1,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.6,
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'When you block someone from Ask Back, they show up here so you can unblock them later.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: YakkuPalette.textSecondary,
              fontSize: 15,
              height: 1.4,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _BlockedUserTile extends StatelessWidget {
  const _BlockedUserTile({
    required this.item,
    required this.busy,
    required this.onUnblock,
  });

  final AskBackBlockItem item;
  final bool busy;
  final VoidCallback onUnblock;

  @override
  Widget build(BuildContext context) {
    final name = item.anonymousName.isEmpty ? 'Someone' : item.anonymousName;
    return Material(
      color: YakkuPalette.pinkMist,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(22),
        side: const BorderSide(color: YakkuPalette.roseBorder, width: 1.4),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: YakkuPalette.white,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const FaIcon(
                    FontAwesomeIcons.userSlash,
                    size: 16,
                    color: YakkuPalette.Raspberry,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: const TextStyle(
                          color: YakkuPalette.Ink,
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          height: 1.15,
                          letterSpacing: -0.2,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Blocked ${_formatDate(item.blockedAt)}',
                        style: const TextStyle(
                          color: YakkuPalette.textSecondary,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              height: 44,
              child: Semantics(
                button: true,
                enabled: !busy,
                label: busy ? 'Unblocking' : 'Unblock $name',
                child: OutlinedButton(
                  onPressed: busy ? null : onUnblock,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: YakkuPalette.Raspberry,
                    disabledForegroundColor: YakkuPalette.disabledMauve,
                    side: BorderSide(
                      color: busy
                          ? YakkuPalette.disabledMauve
                          : YakkuPalette.Raspberry,
                      width: 1.5,
                    ),
                    shape: const StadiumBorder(),
                  ),
                  child: Text(
                    busy ? 'Unblocking…' : 'Unblock',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

String _formatDate(DateTime value) {
  final local = value.toLocal();
  final day = local.day.toString().padLeft(2, '0');
  final month = local.month.toString().padLeft(2, '0');
  return '$day/$month/${local.year}';
}
