import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/converter_state.dart';
import '../theme/app_theme.dart';
import '../widgets/converter_card.dart';
import '../widgets/numeric_keypad.dart';
import '../widgets/pressable.dart';
import '../widgets/recent_pairs.dart';
import 'settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Timer? _tick;

  @override
  void initState() {
    super.initState();
    // "Rates updated 3 min ago" has to age on its own, without an interaction
    // to trigger a rebuild.
    _tick = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _tick?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<ConverterState>();
    final colors = context.colors;

    return Scaffold(
      backgroundColor: colors.groupedBackground,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _NavBar(
              onSettings: () => Navigator.of(context).push(
                MaterialPageRoute(
                  fullscreenDialog: true,
                  builder: (_) => const SettingsScreen(),
                ),
              ),
            ),
            Expanded(
              child: RefreshIndicator(
                onRefresh: state.refreshRates,
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.only(top: 2, bottom: 20),
                  children: const [
                    ConverterCard(),
                    SizedBox(height: 16),
                    _RateInfo(),
                    SizedBox(height: 16),
                    RecentPairs(),
                  ],
                ),
              ),
            ),
            const NumericKeypad(),
          ],
        ),
      ),
    );
  }
}

class _NavBar extends StatelessWidget {
  const _NavBar({required this.onSettings});

  final VoidCallback onSettings;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
      child: Row(
        children: [
          const Text(
            'Kurs',
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
          ),
          const Spacer(),
          Pressable(
            onTap: onSettings,
            child: const Padding(
              padding: EdgeInsets.all(4),
              child: Icon(
                Icons.settings_outlined,
                size: 22,
                color: AppTheme.accent,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// The rate line plus the refresh chip beneath it.
class _RateInfo extends StatelessWidget {
  const _RateInfo();

  @override
  Widget build(BuildContext context) {
    final state = context.watch<ConverterState>();
    final colors = context.colors;
    final stale = state.isStale;
    final tint = stale ? const Color(0xFFFF9500) : AppTheme.accent;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          if (state.isInitialLoad)
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  width: 12,
                  height: 12,
                  child: CircularProgressIndicator(
                    strokeWidth: 1.6,
                    color: colors.secondaryLabel,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'Fetching latest rates…',
                  style: TextStyle(fontSize: 13, color: colors.secondaryLabel),
                ),
              ],
            )
          else
            Text(
              state.rateInfo,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 13, color: colors.secondaryLabel),
            ),
          const SizedBox(height: 9),
          Pressable(
            onTap: state.refreshRates,
            child: Container(
              constraints: const BoxConstraints(minHeight: 32),
              padding: const EdgeInsets.symmetric(horizontal: 13),
              decoration: BoxDecoration(
                color: tint.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (state.isLoading)
                    SizedBox(
                      width: 12,
                      height: 12,
                      child: CircularProgressIndicator(
                        strokeWidth: 1.6,
                        color: tint,
                      ),
                    )
                  else
                    Icon(
                      stale ? Icons.wifi_off : Icons.refresh,
                      size: 14,
                      color: tint,
                    ),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      _chipText(state),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: tint,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// When offline, the last-known-good time stays visible alongside the
  /// warning — knowing the rates are an hour old matters more than knowing
  /// the network is down.
  String _chipText(ConverterState state) {
    if (state.isLoading) return 'Updating…';
    if (state.isStale) return 'Offline · Updated ${state.updatedAgo()}';
    return 'Rates updated ${state.updatedAgo()}';
  }
}
