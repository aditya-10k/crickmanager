import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';

import '../services/api_service.dart';
import '../widgets/glass_panel.dart';
import '../models/player_season.dart';
import '../theme/app_theme.dart';

class DraftRoomScreen extends StatelessWidget {
  const DraftRoomScreen({Key? key}) : super(key: key);

  Widget _buildRosterStatus(BuildContext context, GameProvider provider) {
    final drafted = provider.draftedPlayers;
    final wks = drafted.where((p) => p.isWicketkeeperCareer == 1 || p.role == 'WK').length;
    final bowlers = drafted.where((p) => p.role == 'BOWL' || p.role == 'AR').length;
    final spinners = drafted.where((p) => p.bowlingStyle.toLowerCase().contains('spin') || p.bowlingStyle.toLowerCase().contains('break')).length;
    final pacers = drafted.where((p) => p.bowlingStyle.toLowerCase().contains('fast') || p.bowlingStyle.toLowerCase().contains('medium')).length;
    final foreigners = drafted.where((p) => p.inferredNationality.toLowerCase() != 'india').length;

    Widget checkRow(String label, bool isMet, String countStr) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            Icon(
              isMet ? Icons.check_circle : Icons.radio_button_unchecked,
              color: isMet ? AppTheme.neonPink : const Color(0xFF64748B),
              size: 16,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 12,
                color: isMet ? Colors.white70 : const Color(0xFF94A3B8),
                fontWeight: isMet ? FontWeight.bold : FontWeight.normal,
              ),
            ),
            const Spacer(),
            Text(
              countStr,
              style: GoogleFonts.outfit(
                fontSize: 12,
                color: isMet ? AppTheme.neonPink : const Color(0xFF64748B),
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'ROSTER REQUIREMENTS',
          style: GoogleFonts.inter(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF94A3B8),
            letterSpacing: 1.0,
          ),
        ),
        const SizedBox(height: 10),
        checkRow('At least 1 Wicketkeeper (WK)', wks >= 1, '$wks / 1'),
        checkRow('At least 4 Bowlers/ARs', bowlers >= 4, '$bowlers / 4'),
        checkRow('At least 1 Spin Bowler', spinners >= 1, '$spinners / 1'),
        checkRow('At least 1 Pace Bowler', pacers >= 1, '$pacers / 1'),
        checkRow('Overseas Players (Max: 5)', foreigners <= 5, '$foreigners / 5'),
        checkRow('Complete 12-Man Squad', drafted.length == 12, '${drafted.length} / 12'),
      ],
    );
  }

  Widget _buildDraftedList(BuildContext context, GameProvider provider) {
    final drafted = provider.draftedPlayers;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'MY DRAFTED SQUAD',
          style: GoogleFonts.inter(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF94A3B8),
            letterSpacing: 1.0,
          ),
        ),
        const SizedBox(height: 10),
        if (drafted.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Text(
              'No players selected yet.',
              style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF64748B)),
            ),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: drafted.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final p = drafted[index];
              final isWk = p.isWicketkeeperCareer == 1 || p.role == 'WK';
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0x1F0F172A),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.white.withOpacity(0.04)),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 12,
                      backgroundColor: isWk
                          ? const Color(0x1FFFBF24)
                          : p.role == 'BOWL'
                              ? const Color(0x1F3B82F6)
                              : p.role == 'AR'
                                  ? const Color(0x1FA855F7)
                                  : AppTheme.neonPink.withOpacity(0.12),
                      child: Text(
                        p.role,
                        style: GoogleFonts.outfit(
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                          color: isWk
                              ? const Color(0xFFFBBF24)
                              : p.role == 'BOWL'
                                  ? const Color(0xFF3B82F6)
                                  : p.role == 'AR'
                                      ? const Color(0xFFA855F7)
                                      : AppTheme.neonPink,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            p.player,
                            style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white),
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            '${p.team} (${p.season})',
                            style: GoogleFonts.inter(fontSize: 10, color: const Color(0xFF64748B)),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '${p.cost} Cr',
                          style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.neonPink),
                        ),
                        Text(
                          'Rtg: ${p.overallRating.round()}',
                          style: GoogleFonts.inter(fontSize: 10, color: const Color(0xFF94A3B8)),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
      ],
    );
  }

  Widget _buildPlayerPoolGrid(BuildContext context, GameProvider provider, bool isDesktop) {
    final players = provider.currentDraftPlayers;
    final budget = provider.budget;

    if (players.isEmpty) {
      return const Center(child: CircularProgressIndicator(color: AppTheme.neonPink));
    }

    // Compact card builder — no Spacers, horizontal layout
    Widget playerCard(PlayerSeason p) {
      final drafted = provider.draftedPlayers;
      final canAfford = p.cost <= budget;
      final isLocalReserve = p.id < 0;
      final valueRatio = p.cost > 0 ? (p.overallRating / p.cost).toStringAsFixed(1) : 'N/A';
      final isWk = p.isWicketkeeperCareer == 1 || p.role == 'WK';
      final isForeigner = p.inferredNationality.toLowerCase() != 'india';
      final overseasCount = drafted.where((x) => x.inferredNationality.toLowerCase() != 'india').length;
      final reachesOverseasCap = isForeigner && overseasCount >= 5;

      final roleColor = isWk
          ? const Color(0xFFFBBF24)
          : p.role == 'BOWL'
              ? const Color(0xFF3B82F6)
              : p.role == 'AR'
                  ? const Color(0xFFA855F7)
                  : AppTheme.neonPink;

      final buttonColor = isLocalReserve ? const Color(0xFFFF7A00) : AppTheme.neonPink;

      // ── Compute Season Stats ──────────────────────────
      // Batting
      final batSR = p.ballsFaced > 0
          ? (p.runsScored / p.ballsFaced * 100).toStringAsFixed(0)
          : '-';
      // Rough innings estimate: ~2 balls per dot, treat ballsFaced as proxy
      // Use a simple dismissal-based avg: runs / max(1, wickets of team, just show runs/10 as approx)
      // Since we don't have innings/dismissals, show Runs & SR only
      final batAvg = p.ballsFaced > 10
          ? p.runsScored.toString()
          : '-';

      // Bowling
      final overs = p.ballsBowled > 0 ? p.ballsBowled / 6.0 : 0.0;
      // We don't have runsConceded in model — use bowlingRating as proxy indicator
      // We DO have wicketsTaken and ballsBowled
      final bowlSR = (p.wicketsTaken > 0 && p.ballsBowled > 0)
          ? (p.ballsBowled / p.wicketsTaken).toStringAsFixed(1)
          : '-';
      final bowlOvers = overs > 0 ? overs.toStringAsFixed(1) : '-';

      final isBatter = p.role == 'BAT' || isWk;
      final isBowler = p.role == 'BOWL';
      final isAR = p.role == 'AR';

      // Season stats chips to show
      Widget statsRow() {
        if (isLocalReserve) return const SizedBox.shrink();

        final batStats = [
          if (p.runsScored > 0) _statChip('🏏', '${p.runsScored} runs', const Color(0xFF34D399)),
          if (p.ballsFaced > 0) _statChip('SR', batSR, Colors.white70),
        ];

        final bowlStats = [
          if (p.wicketsTaken > 0) _statChip('🎯', '${p.wicketsTaken} wkts', const Color(0xFF60A5FA)),
          if (p.ballsBowled > 0) _statChip('Ov', bowlOvers, Colors.white70),
          if (p.wicketsTaken > 0 && p.ballsBowled > 0) _statChip('SR', bowlSR, const Color(0xFFA78BFA)),
        ];

        List<Widget> chips = [];
        if (isBatter) chips = batStats;
        else if (isBowler) chips = bowlStats;
        else if (isAR) chips = [...batStats, ...bowlStats];

        if (chips.isEmpty) return const SizedBox.shrink();

        return Padding(
          padding: const EdgeInsets.only(top: 5),
          child: Wrap(spacing: 4, runSpacing: 4, children: chips),
        );
      }

      return Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFF0D0D0D),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isLocalReserve
                ? Colors.deepOrangeAccent.withOpacity(0.2)
                : Colors.white.withOpacity(0.06),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                // Left: Name + team + role badge
                Expanded(
                  flex: 5,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              p.player,
                              style: GoogleFonts.outfit(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: isLocalReserve ? const Color(0xFFFF7A00) : Colors.white,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: roleColor.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(color: roleColor.withOpacity(0.3)),
                            ),
                            child: Text(
                              isWk ? 'WK' : p.role,
                              style: GoogleFonts.outfit(fontSize: 9, fontWeight: FontWeight.w800, color: roleColor),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        isLocalReserve ? 'Local reserve' : '${p.team} · ${p.season}',
                        style: GoogleFonts.inter(fontSize: 10, color: const Color(0xFF4B5563)),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                // Middle: Ratings row
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        _miniStat('RTG', '${p.overallRating.round()}', Colors.white),
                        const SizedBox(width: 12),
                        _miniStat('COST', '${p.cost}Cr', AppTheme.neonPink),
                        const SizedBox(width: 12),
                        _miniStat('VAL', valueRatio, const Color(0xFFF59E0B)),
                      ],
                    ),
                  ],
                ),
                const SizedBox(width: 10),
                // Right: Draft button
                SizedBox(
                  width: 72,
                  height: 32,
                  child: ElevatedButton(
                    onPressed: (canAfford && !reachesOverseasCap && !provider.isLoading) ? () => provider.draftPlayer(p) : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: reachesOverseasCap ? const Color(0xFF1A1A1A) : buttonColor,
                      disabledBackgroundColor: const Color(0xFF1A1A1A),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                      padding: EdgeInsets.zero,
                      elevation: 0,
                    ),
                    child: Text(
                      reachesOverseasCap
                          ? 'Limit'
                          : canAfford
                              ? 'Draft'
                              : '✕',
                      style: GoogleFonts.outfit(fontSize: 11, fontWeight: FontWeight.w800),
                    ),
                  ),
                ),
              ],
            ),
            // Season stats row (below the main row)
            statsRow(),
          ],
        ),
      );
    }

    if (isDesktop) {
      // Two-column grid on desktop using a Wrap-like layout
      final half = (players.length / 2).ceil();
      final leftCol = players.sublist(0, half);
      final rightCol = players.sublist(half);
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              children: leftCol.map(playerCard).toList(),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              children: rightCol.map(playerCard).toList(),
            ),
          ),
        ],
      );
    } else {
      return Column(
        children: players.map(playerCard).toList(),
      );
    }
  }

  Widget _miniStat(String label, String value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label, style: GoogleFonts.inter(fontSize: 8, color: const Color(0xFF4B5563), fontWeight: FontWeight.bold)),
        Text(value, style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.w800, color: color)),
      ],
    );
  }

  Widget _statChip(String icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(5),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Text(
        '$icon $label',
        style: GoogleFonts.inter(fontSize: 9, fontWeight: FontWeight.w600, color: color),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<GameProvider>(context);
    final size = MediaQuery.of(context).size;
    final isDesktop = size.width >= 900;

    final header = GlassPanel(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'DRAFT ROUND',
                    style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.bold, color: const Color(0xFF64748B)),
                  ),
                  Text(
                    '${provider.draftRound} / 12',
                    style: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.w800, color: AppTheme.neonPink),
                  ),
                ],
              ),
              const SizedBox(width: 24),
              Container(
                width: 1,
                height: 40,
                color: Colors.white.withOpacity(0.08),
              ),
              const SizedBox(width: 24),
              if (provider.currentDraftSquad != null)
                Row(
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'DRAFT POOL SQUAD',
                          style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.bold, color: const Color(0xFF64748B)),
                        ),
                        Text(
                          '${provider.currentDraftSquad!.team} (${provider.currentDraftSquad!.season})',
                          style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                      ],
                    ),
                    const SizedBox(width: 12),
                    // Skip button — one use per campaign
                    provider.skipUsed
                        ? Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.04),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: const Color(0xFF374151)),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.block, size: 13, color: Color(0xFF64748B)),
                                const SizedBox(width: 5),
                                Text(
                                  'Skip Used (1×)',
                                  style: GoogleFonts.inter(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: const Color(0xFF64748B),
                                  ),
                                ),
                              ],
                            ),
                          )
                        : TextButton.icon(
                            onPressed: provider.canSkip ? () => provider.skipCurrentSquad() : null,
                            icon: const Icon(Icons.skip_next, size: 14, color: Color(0xFFFF7A00)),
                            label: Row(
                              children: [
                                Text(
                                  'Skip Chance',
                                  style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(width: 4),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFF7A00).withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    '1×',
                                    style: GoogleFonts.outfit(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w800,
                                      color: const Color(0xFFFF7A00),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            style: TextButton.styleFrom(
                              foregroundColor: const Color(0xFFFF7A00),
                              disabledForegroundColor: const Color(0xFF64748B),
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              backgroundColor: Colors.white.withOpacity(0.04),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              minimumSize: Size.zero,
                            ),
                          ),
                  ],
                ),
            ],
          ),
          Row(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'TARGET SEASON',
                    style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.bold, color: const Color(0xFF64748B)),
                  ),
                  Text(
                    'IPL ${provider.selectedSeason}',
                    style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.w800, color: const Color(0xFF3B82F6)),
                  ),
                ],
              ),
              const SizedBox(width: 24),
              Container(
                width: 1,
                height: 40,
                color: Colors.white.withOpacity(0.08),
              ),
              const SizedBox(width: 24),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'BUDGET REMAINING',
                    style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.bold, color: const Color(0xFF64748B)),
                  ),
                  Row(
                    children: [
                      const Icon(Icons.currency_rupee, color: AppTheme.neonPink, size: 18),
                      Text(
                        '${provider.budget} Cr',
                        style: GoogleFonts.outfit(
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          color: provider.budget > 30.0
                              ? AppTheme.neonPink
                              : provider.budget > 12.0
                                  ? const Color(0xFFF59E0B)
                                  : const Color(0xFFEF4444),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );

    // Desktop: Split Screen
    Widget desktopLayout() {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 3,
            child: SingleChildScrollView(
              child: _buildPlayerPoolGrid(context, provider, true),
            ),
          ),
          const SizedBox(width: 24),
          Expanded(
            flex: 1,
            child: SingleChildScrollView(
              child: Column(
                children: [
                  GlassPanel(
                    padding: const EdgeInsets.all(20),
                    child: _buildRosterStatus(context, provider),
                  ),
                  const SizedBox(height: 24),
                  GlassPanel(
                    padding: const EdgeInsets.all(20),
                    child: _buildDraftedList(context, provider),
                  ),
                ],
              ),
            ),
          ),
        ],
      );
    }

    // Mobile Layout (List of Pool, with floating action drawer for Roster)
    Widget mobileLayout() {
      return Stack(
        children: [
          Positioned.fill(
            child: SingleChildScrollView(
              padding: const EdgeInsets.only(bottom: 80),
              child: _buildPlayerPoolGrid(context, provider, false),
            ),
          ),
          Positioned(
            bottom: 16,
            left: 16,
            right: 16,
            child: FloatingActionButton.extended(
              onPressed: () {
                showModalBottomSheet(
                  context: context,
                  backgroundColor: AppTheme.surfaceCard,
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                  ),
                  builder: (context) {
                    return SafeArea(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _buildRosterStatus(context, provider),
                            const Divider(color: Colors.white12, height: 32),
                            _buildDraftedList(context, provider),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
              backgroundColor: AppTheme.surfaceCard,
              label: Row(
                children: [
                  const Icon(Icons.assignment, color: AppTheme.neonPink),
                  const SizedBox(width: 8),
                  Text(
                    'View My Roster (${provider.draftedPlayers.length}/12)',
                    style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.white),
                  ),
                ],
              ),
            ),
          ),
        ],
      );
    }

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              header,
              const SizedBox(height: 24),
              Expanded(
                child: isDesktop ? desktopLayout() : mobileLayout(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
