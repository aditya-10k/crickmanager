import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';

import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../models/game_performance.dart';

class MainMenuScreen extends StatefulWidget {
  const MainMenuScreen({Key? key}) : super(key: key);

  @override
  State<MainMenuScreen> createState() => _MainMenuScreenState();
}

class _MainMenuScreenState extends State<MainMenuScreen> with SingleTickerProviderStateMixin {
  int _mobileTabIndex = 0;
  late AnimationController _glowController;

  @override
  void initState() {
    super.initState();
    _glowController = AnimationController(vsync: this, duration: const Duration(seconds: 3))
      ..repeat(reverse: true);
  }

  @override
  void dispose() {
    _glowController.dispose();
    super.dispose();
  }

  // ── Campaign Panel ───────────────────────────────────────────
  Widget _buildCampaignPanel(BuildContext context, GameProvider provider) {
    return AnimatedBuilder(
      animation: _glowController,
      builder: (_, child) => Container(
        decoration: BoxDecoration(
          color: AppTheme.surfaceCard,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: AppTheme.neonPink.withOpacity(0.3 + 0.2 * _glowController.value),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: AppTheme.neonPink.withOpacity(0.08 + 0.08 * _glowController.value),
              blurRadius: 30,
              spreadRadius: 2,
            ),
          ],
        ),
        padding: const EdgeInsets.all(28),
        child: child,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: AppTheme.pinkGradient,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.sports_cricket, color: Colors.white, size: 22),
              ),
              const SizedBox(width: 14),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('NEW CAMPAIGN', style: AppTheme.label.copyWith(color: AppTheme.neonPink)),
                  Text('Conquer the IPL', style: AppTheme.headingSmall),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Divider
          Container(height: 1, color: AppTheme.surfaceBorder),
          const SizedBox(height: 16),
          Text(
            'The simulator randomly selects a historic IPL season and loads real opponents. Build your Moneyball XI under a ₹100 Crore budget and dominate the league!',
            style: AppTheme.bodyMedium,
          ),
          const SizedBox(height: 20),
          // Feature chips
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _featureChip(Icons.shuffle, 'Random Season'),
              _featureChip(Icons.currency_rupee, '₹100 Cr Budget'),
              _featureChip(Icons.history_edu, 'Real IPL Data'),
              _featureChip(Icons.emoji_events, 'Playoffs'),
            ],
          ),
          const SizedBox(height: 24),
          // CTA Button
          Container(
            decoration: BoxDecoration(
              gradient: AppTheme.pinkGradient,
              borderRadius: BorderRadius.circular(14),
              boxShadow: AppTheme.pinkGlow,
            ),
            child: ElevatedButton(
              onPressed: provider.isLoading ? null : () => provider.startNewGame(),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 18),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                minimumSize: const Size.fromHeight(52),
              ),
              child: provider.isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.play_arrow_rounded, size: 22),
                        const SizedBox(width: 8),
                        Text(
                          'START RANDOM CAMPAIGN',
                          style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.w800, letterSpacing: 1),
                        ),
                      ],
                    ),
            ),
          ),
          // Error message if campaign fails to start
          if (provider.error != null)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFFEF4444).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFEF4444).withOpacity(0.4)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline, color: Color(0xFFEF4444), size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        provider.error!,
                        style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFFEF4444)),
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

  Widget _featureChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppTheme.neonPinkDim,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.neonPink.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: AppTheme.neonPink),
          const SizedBox(width: 5),
          Text(label, style: GoogleFonts.inter(fontSize: 11, color: AppTheme.neonPink, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  // ── Stats Cards ──────────────────────────────────────────────
  Widget _buildStatsCards(BuildContext context, GameProvider provider) {
    final history = provider.history;
    final totalSeasons = history.length;
    final championships = history.where((h) => h.champion).length;
    int totalWins = 0;
    int totalLosses = 0;
    for (var h in history) {
      totalWins += h.wins;
      totalLosses += h.losses;
    }
    final totalGames = totalWins + totalLosses;
    final winRatio = totalGames > 0 ? (totalWins / totalGames * 100.0).toStringAsFixed(1) : '0.0';

    return Row(
      children: [
        _statCard('SEASONS', '$totalSeasons', Icons.layers_outlined, AppTheme.bowlColor),
        const SizedBox(width: 12),
        _statCard('CHAMPS', '$championships', Icons.emoji_events_rounded, AppTheme.gold),
        const SizedBox(width: 12),
        _statCard('WINS', '$totalWins', Icons.check_circle_outline, AppTheme.batColor),
        const SizedBox(width: 12),
        _statCard('WIN %', '$winRatio%', Icons.trending_up, AppTheme.neonPink),
      ],
    );
  }

  Widget _statCard(String label, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 12),
        decoration: BoxDecoration(
          color: AppTheme.surfaceCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.surfaceBorder),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 8),
            Text(value, style: GoogleFonts.outfit(fontSize: 22, fontWeight: FontWeight.w900, color: color)),
            const SizedBox(height: 4),
            Text(label, style: AppTheme.label, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }

  // ── History Panel ────────────────────────────────────────────
  Widget _buildHistoryPanel(BuildContext context, GameProvider provider) {
    final history = provider.history;
    return Container(
      decoration: AppTheme.cardDecoration(),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _panelHeader(Icons.history_rounded, 'Campaign History', AppTheme.bowlColor),
          const SizedBox(height: 16),
          if (history.isEmpty)
            _emptyState('No campaigns completed yet.\nRun your first campaign to log stats!')
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: history.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, index) => _historyCard(history[index]),
            ),
        ],
      ),
    );
  }

  Widget _historyCard(GamePerformance h) {
    final posColor = h.finalPosition == 1
        ? AppTheme.gold
        : h.finalPosition <= 4
            ? AppTheme.batColor
            : AppTheme.errorColor;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: h.champion ? AppTheme.gold.withOpacity(0.3) : AppTheme.surfaceBorder,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: h.champion ? AppTheme.gold.withOpacity(0.1) : AppTheme.surfaceBorder.withOpacity(0.5),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              h.champion ? Icons.workspace_premium_rounded : Icons.sports_cricket,
              color: h.champion ? AppTheme.gold : AppTheme.textMuted,
              size: 22,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'IPL ${h.seasonBeaten} Campaign',
                  style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 14),
                ),
                const SizedBox(height: 3),
                Text(
                  'MVP: ${h.mvp}',
                  style: AppTheme.bodySmall,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '#${h.finalPosition}',
                style: GoogleFonts.outfit(fontWeight: FontWeight.w900, color: posColor, fontSize: 18),
              ),
              Text('W${h.wins}-L${h.losses}', style: AppTheme.bodySmall),
            ],
          ),
        ],
      ),
    );
  }

  // ── Leaderboard ──────────────────────────────────────────────
  Widget _buildLeaderboardPanel(BuildContext context, GameProvider provider) {
    final leaderboard = provider.leaderboard;
    final currentUser = provider.username;

    return Container(
      decoration: AppTheme.cardDecoration(),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _panelHeader(Icons.leaderboard_rounded, 'Global Leaderboard', AppTheme.gold),
          const SizedBox(height: 16),
          if (leaderboard.isEmpty)
            _emptyState('No players logged yet.\nBe the first to claim a spot!')
          else
            Column(
              children: [
                // Header row
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Row(
                    children: [
                      SizedBox(width: 36, child: Text('#', style: AppTheme.label)),
                      const Expanded(flex: 4, child: SizedBox()),
                      SizedBox(width: 60, child: Text('CHAMPS', style: AppTheme.label, textAlign: TextAlign.center)),
                      SizedBox(width: 60, child: Text('WIN%', style: AppTheme.label, textAlign: TextAlign.center)),
                      SizedBox(width: 50, child: Text('GAMS', style: AppTheme.label, textAlign: TextAlign.center)),
                    ],
                  ),
                ),
                Container(height: 1, color: AppTheme.surfaceBorder),
                const SizedBox(height: 6),
                ...leaderboard.asMap().entries.map((entry) {
                  final idx = entry.key;
                  final lb = entry.value;
                  final isMe = lb['username'] == currentUser;
                  final posColors = [AppTheme.gold, const Color(0xFFC0C0C0), const Color(0xFFCD7F32)];
                  final posColor = idx < 3 ? posColors[idx] : AppTheme.textMuted;

                  return Container(
                    margin: const EdgeInsets.symmetric(vertical: 3),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                    decoration: BoxDecoration(
                      color: isMe ? AppTheme.neonPinkDim : Colors.transparent,
                      borderRadius: BorderRadius.circular(10),
                      border: isMe ? Border.all(color: AppTheme.neonPink.withOpacity(0.3)) : null,
                    ),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 36,
                          child: idx < 3
                              ? Icon(Icons.emoji_events_rounded, color: posColor, size: 18)
                              : Text(
                                  '${idx + 1}',
                                  style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.bold, color: posColor),
                                ),
                        ),
                        Expanded(
                          flex: 4,
                          child: Text(
                            '${lb['username']}${isMe ? " (You)" : ""}',
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: isMe ? FontWeight.bold : FontWeight.normal,
                              color: isMe ? AppTheme.neonPink : Colors.white,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        SizedBox(
                          width: 60,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              if ((lb['championships'] as num) > 0)
                                const Icon(Icons.star_rounded, size: 12, color: AppTheme.gold),
                              Text(
                                ' ${lb['championships']}',
                                style: GoogleFonts.outfit(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: (lb['championships'] as num) > 0 ? AppTheme.gold : AppTheme.textMuted,
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(
                          width: 60,
                          child: Text(
                            '${lb['winRatio']}%',
                            style: GoogleFonts.outfit(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: (lb['winRatio'] as num) >= 60
                                  ? AppTheme.batColor
                                  : (lb['winRatio'] as num) >= 45
                                      ? AppTheme.wkColor
                                      : AppTheme.errorColor,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        SizedBox(
                          width: 50,
                          child: Text(
                            '${lb['campaigns']}',
                            style: GoogleFonts.inter(fontSize: 13, color: AppTheme.textSecondary),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ],
            ),
        ],
      ),
    );
  }

  Widget _panelHeader(IconData icon, String title, Color color) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 12),
        Text(title, style: AppTheme.headingSmall),
      ],
    );
  }

  Widget _emptyState(String msg) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 36),
      alignment: Alignment.center,
      child: Column(
        children: [
          const Icon(Icons.hourglass_empty, color: AppTheme.textMuted, size: 32),
          const SizedBox(height: 12),
          Text(msg, style: AppTheme.bodyMedium, textAlign: TextAlign.center),
        ],
      ),
    );
  }

  // ── Build ────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<GameProvider>(context);
    final size = MediaQuery.of(context).size;
    final isDesktop = size.width >= 900;

    final header = Row(
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            RichText(
              text: TextSpan(
                children: [
                  TextSpan(
                    text: 'Welcome, ',
                    style: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.w400, color: AppTheme.textSecondary),
                  ),
                  TextSpan(
                    text: provider.username ?? 'Manager',
                    style: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.w900, color: AppTheme.neonPink),
                  ),
                ],
              ),
            ),
            Text('Build your Moneyball XI and dominate.', style: AppTheme.bodyMedium),
          ],
        ),
        const Spacer(),
        // Refresh leaderboard
        IconButton(
          onPressed: () => provider.fetchLeaderboard(),
          icon: const Icon(Icons.refresh, color: AppTheme.textSecondary, size: 20),
          tooltip: 'Refresh leaderboard',
        ),
        const SizedBox(width: 4),
        // Logout
        Container(
          decoration: BoxDecoration(
            color: AppTheme.errorColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppTheme.errorColor.withOpacity(0.3)),
          ),
          child: IconButton(
            onPressed: () => provider.logout(),
            icon: const Icon(Icons.logout_rounded, color: AppTheme.errorColor, size: 18),
            tooltip: 'Logout',
          ),
        ),
      ],
    );

    Widget desktopLayout() {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 5,
            child: SingleChildScrollView(
              child: Column(
                children: [
                  _buildCampaignPanel(context, provider),
                  const SizedBox(height: 20),
                  _buildStatsCards(context, provider),
                  const SizedBox(height: 20),
                  _buildHistoryPanel(context, provider),
                ],
              ),
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            flex: 3,
            child: SingleChildScrollView(
              child: _buildLeaderboardPanel(context, provider),
            ),
          ),
        ],
      );
    }

    Widget mobileLayout() {
      switch (_mobileTabIndex) {
        case 0:
          return SingleChildScrollView(
            child: Column(
              children: [
                _buildCampaignPanel(context, provider),
                const SizedBox(height: 20),
                _buildStatsCards(context, provider),
              ],
            ),
          );
        case 1:
          return SingleChildScrollView(child: _buildHistoryPanel(context, provider));
        case 2:
          return SingleChildScrollView(child: _buildLeaderboardPanel(context, provider));
        default:
          return const SizedBox.shrink();
      }
    }

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: Stack(
        children: [
          // Background accent glow (top-right)
          Positioned(
            top: -100,
            right: -100,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [AppTheme.neonPink.withOpacity(0.07), Colors.transparent],
                ),
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  header,
                  const SizedBox(height: 20),
                  Expanded(child: isDesktop ? desktopLayout() : mobileLayout()),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: !isDesktop
          ? Theme(
              data: Theme.of(context).copyWith(
                splashColor: AppTheme.neonPinkDim,
                highlightColor: AppTheme.neonPinkDim,
              ),
              child: BottomNavigationBar(
                currentIndex: _mobileTabIndex,
                onTap: (idx) => setState(() => _mobileTabIndex = idx),
                backgroundColor: AppTheme.surfaceCard,
                selectedItemColor: AppTheme.neonPink,
                unselectedItemColor: AppTheme.textMuted,
                selectedLabelStyle: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.bold),
                unselectedLabelStyle: GoogleFonts.inter(fontSize: 10),
                items: const [
                  BottomNavigationBarItem(icon: Icon(Icons.sports_cricket), label: 'Campaign'),
                  BottomNavigationBarItem(icon: Icon(Icons.history_rounded), label: 'History'),
                  BottomNavigationBarItem(icon: Icon(Icons.leaderboard_rounded), label: 'Leaderboard'),
                ],
              ),
            )
          : null,
    );
  }
}
