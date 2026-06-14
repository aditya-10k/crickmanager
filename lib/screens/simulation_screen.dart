import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';

import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../models/standing.dart';
import '../models/sim_match_result.dart';

class SimulationScreen extends StatefulWidget {
  const SimulationScreen({Key? key}) : super(key: key);

  @override
  State<SimulationScreen> createState() => _SimulationScreenState();
}

class _SimulationScreenState extends State<SimulationScreen> {
  int _mobileTabIndex = 0;

  // ── Points Table ─────────────────────────────────────────────
  Widget _buildPointsTable(BuildContext context, GameProvider provider) {
    final standings = provider.standings;

    return Container(
      decoration: AppTheme.cardDecoration(),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _panelHeader(Icons.table_chart_rounded, 'Points Table', AppTheme.bowlColor),
          const SizedBox(height: 16),
          if (standings.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 32),
              child: Center(
                child: Text(
                  'Simulate matches to populate standings.',
                  style: AppTheme.bodyMedium,
                ),
              ),
            )
          else ...[
            // Header row
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                children: [
                  _tblHead('#', flex: 1),
                  _tblHead('TEAM', flex: 5, align: TextAlign.left),
                  _tblHead('P', flex: 1),
                  _tblHead('W', flex: 1),
                  _tblHead('L', flex: 1),
                  _tblHead('PTS', flex: 2),
                ],
              ),
            ),
            Container(height: 1, color: AppTheme.surfaceBorder),
            const SizedBox(height: 6),
            for (int idx = 0; idx < standings.length; idx++) ...[
              _standingRow(standings[idx], idx),
              if (idx == 3) _playoffDivider(),
            ],
          ],
        ],
      ),
    );
  }

  Widget _tblHead(String txt, {required int flex, TextAlign align = TextAlign.center}) {
    return Expanded(flex: flex, child: Text(txt, style: AppTheme.label, textAlign: align));
  }

  Widget _standingRow(Standing s, int idx) {
    final isUser = s.team == 'Your Moneyball XI';
    final inPlayoffs = idx < 4;
    final posColors = [AppTheme.gold, const Color(0xFFC0C0C0), const Color(0xFFCD7F32)];

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 2),
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
      decoration: BoxDecoration(
        color: isUser
            ? AppTheme.neonPinkDim
            : inPlayoffs
                ? AppTheme.batColor.withOpacity(0.04)
                : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        border: isUser ? Border.all(color: AppTheme.neonPink.withOpacity(0.3)) : null,
      ),
      child: Row(
        children: [
          Expanded(
            flex: 1,
            child: idx < 3
                ? Icon(Icons.emoji_events_rounded, size: 16, color: posColors[idx])
                : Text(
                    '${idx + 1}',
                    style: GoogleFonts.outfit(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: inPlayoffs ? AppTheme.batColor : AppTheme.textMuted,
                    ),
                  ),
          ),
          Expanded(
            flex: 5,
            child: Row(
              children: [
                if (isUser) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppTheme.neonPink,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text('YOU', style: GoogleFonts.outfit(fontSize: 8, fontWeight: FontWeight.w900, color: Colors.white)),
                  ),
                  const SizedBox(width: 6),
                ],
                Flexible(
                  child: Text(
                    s.team,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: isUser ? FontWeight.bold : FontWeight.normal,
                      color: isUser ? AppTheme.neonPink : Colors.white,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          _tblCell('${s.played}'),
          _tblCell('${s.wins}', color: AppTheme.batColor),
          _tblCell('${s.losses}', color: AppTheme.errorColor),
          Expanded(
            flex: 2,
            child: Text(
              '${s.points}',
              style: GoogleFonts.outfit(
                fontSize: 15,
                fontWeight: FontWeight.w900,
                color: isUser ? AppTheme.neonPink : Colors.white,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  Widget _tblCell(String txt, {Color? color}) {
    return Expanded(
      flex: 1,
      child: Text(
        txt,
        style: GoogleFonts.inter(fontSize: 13, color: color ?? AppTheme.textSecondary),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _playoffDivider() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Container(
            height: 1,
            width: 12,
            color: AppTheme.wkColor.withOpacity(0.5),
          ),
          const SizedBox(width: 6),
          Text(
            'PLAYOFF CUT',
            style: GoogleFonts.inter(fontSize: 9, color: AppTheme.wkColor, fontWeight: FontWeight.bold, letterSpacing: 1),
          ),
          const SizedBox(width: 6),
          Expanded(child: Container(height: 1, color: AppTheme.wkColor.withOpacity(0.3))),
        ],
      ),
    );
  }

  // ── Match Result Row ─────────────────────────────────────────
  Widget _buildMatchResultRow(SimMatchResult res) {
    final isHomeUser = res.homeTeam == 'Your Moneyball XI';
    final isAwayUser = res.awayTeam == 'Your Moneyball XI';
    final userWon = res.winner == 'Your Moneyball XI';

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: (isHomeUser || isAwayUser)
              ? (userWon ? AppTheme.batColor.withOpacity(0.4) : AppTheme.errorColor.withOpacity(0.3))
              : AppTheme.surfaceBorder,
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              // Home
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      res.homeTeam,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: isHomeUser ? FontWeight.bold : FontWeight.normal,
                        color: isHomeUser ? AppTheme.neonPink : AppTheme.textSecondary,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${res.homeScore}/${res.homeWickets}',
                      style: GoogleFonts.outfit(fontWeight: FontWeight.w900, fontSize: 18, color: Colors.white),
                    ),
                  ],
                ),
              ),
              // VS pill
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceBorder,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text('VS', style: GoogleFonts.outfit(fontSize: 10, color: AppTheme.textMuted, fontWeight: FontWeight.bold)),
              ),
              // Away
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      res.awayTeam,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: isAwayUser ? FontWeight.bold : FontWeight.normal,
                        color: isAwayUser ? AppTheme.neonPink : AppTheme.textSecondary,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${res.awayScore}/${res.awayWickets}',
                      style: GoogleFonts.outfit(fontWeight: FontWeight.w900, fontSize: 18, color: Colors.white),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
            decoration: BoxDecoration(
              color: (isHomeUser || isAwayUser)
                  ? (userWon ? AppTheme.batColor.withOpacity(0.1) : AppTheme.errorColor.withOpacity(0.1))
                  : AppTheme.surfaceBorder.withOpacity(0.5),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              res.winner == 'Draw' ? 'Match Tied!' : '🏆 ${res.winner} won',
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: (isHomeUser || isAwayUser)
                    ? (userWon ? AppTheme.batColor : AppTheme.errorColor)
                    : AppTheme.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Playoffs Centre ──────────────────────────────────────────
  Widget _buildPlayoffsCenter(BuildContext context, GameProvider provider) {
    final top4 = provider.playoffTeams;
    final stage = provider.playoffStage;

    String q1Home = top4.isNotEmpty ? top4[0] : '1st Place';
    String q1Away = top4.isNotEmpty ? top4[1] : '2nd Place';
    String elimHome = top4.isNotEmpty ? top4[2] : '3rd Place';
    String elimAway = top4.isNotEmpty ? top4[3] : '4th Place';

    String q2Home = 'Loser Q1';
    String q2Away = 'Winner Eliminator';
    if (provider.playoffQ1 != null) {
      q2Home = provider.playoffQ1!.winner == q1Home ? q1Away : q1Home;
    }
    if (provider.playoffElim != null) q2Away = provider.playoffElim!.winner;

    String fHome = 'Winner Q1';
    String fAway = 'Winner Q2';
    if (provider.playoffQ1 != null) fHome = provider.playoffQ1!.winner;
    if (provider.playoffQ2 != null) fAway = provider.playoffQ2!.winner;

    return Column(
      children: [
        Container(
          decoration: AppTheme.cardDecoration(highlighted: true),
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _panelHeader(Icons.flash_on_rounded, 'Playoff Brackets', AppTheme.wkColor),
              const SizedBox(height: 20),
              _playoffBracket('QUALIFIER 1', 'Q1 – 1st vs 2nd', provider.playoffQ1, q1Home, q1Away),
              const SizedBox(height: 12),
              _playoffBracket('ELIMINATOR', 'Do-or-Die – 3rd vs 4th', provider.playoffElim, elimHome, elimAway),
              const SizedBox(height: 12),
              _playoffBracket('QUALIFIER 2', 'Q2 – Q1 loser vs Elim winner', provider.playoffQ2, q2Home, q2Away),
              const SizedBox(height: 12),
              _playoffBracket('GRAND FINAL', '🏆 Championship Match', provider.playoffFinal, fHome, fAway),
              const SizedBox(height: 24),
              Container(
                decoration: BoxDecoration(
                  gradient: AppTheme.pinkGradient,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: AppTheme.pinkGlow,
                ),
                child: ElevatedButton(
                  onPressed: provider.isLoading
                      ? null
                      : () async {
                          final err = await provider.handlePlayoffs();
                          if (err != null && context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(err),
                                backgroundColor: AppTheme.errorColor,
                              ),
                            );
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
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
                            const Icon(Icons.flash_on_rounded, size: 20),
                            const SizedBox(width: 8),
                            Text(
                              stage == 'q1'
                                  ? 'SIMULATE QUALIFIER 1'
                                  : stage == 'elim'
                                      ? 'SIMULATE ELIMINATOR'
                                      : stage == 'q2'
                                          ? 'SIMULATE QUALIFIER 2'
                                          : 'SIMULATE GRAND FINAL',
                              style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.w800, letterSpacing: 1),
                            ),
                          ],
                        ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _playoffBracket(String stage, String desc, SimMatchResult? res, String teamA, String teamB) {
    final isSimulated = res != null;
    final isUserInvolved = res != null &&
        (res.homeTeam == 'Your Moneyball XI' || res.awayTeam == 'Your Moneyball XI');
    final userWon = res?.winner == 'Your Moneyball XI';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isSimulated
            ? (isUserInvolved ? (userWon ? AppTheme.batColor.withOpacity(0.06) : AppTheme.errorColor.withOpacity(0.05)) : AppTheme.surface)
            : AppTheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isSimulated
              ? (isUserInvolved ? (userWon ? AppTheme.batColor.withOpacity(0.4) : AppTheme.errorColor.withOpacity(0.3)) : AppTheme.surfaceBorder)
              : AppTheme.surfaceBorder,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(stage, style: AppTheme.label.copyWith(color: AppTheme.wkColor)),
              const Spacer(),
              if (!isSimulated)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceBorder,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text('PENDING', style: AppTheme.bodySmall.copyWith(fontSize: 9, letterSpacing: 1)),
                )
              else
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppTheme.batColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppTheme.batColor.withOpacity(0.3)),
                  ),
                  child: Text('DONE', style: AppTheme.bodySmall.copyWith(fontSize: 9, letterSpacing: 1, color: AppTheme.batColor)),
                ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isSimulated ? res.homeTeam : teamA,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: isSimulated && res.homeTeam == 'Your Moneyball XI'
                            ? AppTheme.neonPink
                            : Colors.white,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (isSimulated)
                      Text(
                        '${res.homeScore}/${res.homeWickets}',
                        style: GoogleFonts.outfit(
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          color: res.winner == res.homeTeam ? AppTheme.batColor : AppTheme.textMuted,
                        ),
                      ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Text('VS', style: GoogleFonts.outfit(fontSize: 11, color: AppTheme.textMuted, fontWeight: FontWeight.bold)),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      isSimulated ? res.awayTeam : teamB,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: isSimulated && res.awayTeam == 'Your Moneyball XI'
                            ? AppTheme.neonPink
                            : Colors.white,
                      ),
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.end,
                    ),
                    if (isSimulated)
                      Text(
                        '${res.awayScore}/${res.awayWickets}',
                        style: GoogleFonts.outfit(
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          color: res.winner == res.awayTeam ? AppTheme.batColor : AppTheme.textMuted,
                        ),
                        textAlign: TextAlign.end,
                      ),
                  ],
                ),
              ),
            ],
          ),
          if (isSimulated) ...[
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.center,
              child: Text(
                '🏆 ${res.winner} advanced',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: res.winner == 'Your Moneyball XI' ? AppTheme.neonPink : AppTheme.textSecondary,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ── Match Centre ─────────────────────────────────────────────
  Widget _buildMatchCentre(BuildContext context, GameProvider provider) {
    if (provider.playoffStage != 'none') {
      return _buildPlayoffsCenter(context, provider);
    }

    final oppCount = provider.opponents.length;
    final totalRounds = oppCount * 2;

    return Container(
      decoration: AppTheme.cardDecoration(),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _panelHeader(
                Icons.sports_cricket,
                'League Stage (14 Rounds)',
                AppTheme.neonPink,
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppTheme.neonPinkDim,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppTheme.neonPink.withOpacity(0.3)),
                ),
                child: Text(
                  'Pending',
                  style: GoogleFonts.inter(fontSize: 11, color: AppTheme.neonPink, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: const LinearProgressIndicator(
              value: 0.0,
              minHeight: 4,
              backgroundColor: AppTheme.surfaceBorder,
              valueColor: AlwaysStoppedAnimation<Color>(AppTheme.neonPink),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'CAMPAIGN DETAILS',
            style: AppTheme.label,
          ),
          const SizedBox(height: 12),
          Text(
            'Your Moneyball XI is about to play a 14-round double-round-robin league stage in IPL ${provider.selectedSeason}. All matches (both yours and other teams\') will be calculated on the server using strategic team ratings and historical player performance.',
            style: AppTheme.bodyMedium,
          ),
          const SizedBox(height: 20),
          Text(
            'OPPONENT TEAMS',
            style: AppTheme.label,
          ),
          const SizedBox(height: 10),
          for (final opp in provider.opponents)
            Container(
              margin: const EdgeInsets.only(bottom: 6),
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
              decoration: BoxDecoration(
                color: AppTheme.surface,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppTheme.surfaceBorder),
              ),
              child: Row(
                children: [
                  const Icon(Icons.shield, size: 14, color: AppTheme.textSecondary),
                  const SizedBox(width: 10),
                  Text(
                    opp.team,
                    style: GoogleFonts.inter(fontSize: 13, color: Colors.white),
                  ),
                  const Spacer(),
                  Text(
                    'IPL ${opp.season}',
                    style: GoogleFonts.outfit(fontSize: 11, color: AppTheme.textSecondary),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 24),
          if (provider.isLoading)
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: CircularProgressIndicator(color: AppTheme.neonPink),
              ),
            )
          else
            Container(
              decoration: BoxDecoration(
                gradient: AppTheme.pinkGradient,
                borderRadius: BorderRadius.circular(14),
                boxShadow: AppTheme.pinkGlow,
              ),
              child: ElevatedButton(
                onPressed: () async {
                  final err = await provider.simulateGroupStage();
                  if (err != null && context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(err),
                        backgroundColor: AppTheme.errorColor,
                      ),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  minimumSize: const Size.fromHeight(52),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.flash_on_rounded, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'SIMULATE GROUP STAGE',
                      style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.w800, letterSpacing: 1),
                    ),
                  ],
                ),
              ),
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

  // ── Build ────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<GameProvider>(context);
    final size = MediaQuery.of(context).size;
    final isDesktop = size.width >= 900;

    final header = Row(
      children: [
        GestureDetector(
          onTap: () => provider.restartToMenu(),
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppTheme.surfaceCard,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.surfaceBorder),
            ),
            child: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 16),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    'IPL ${provider.selectedSeason} ',
                    style: GoogleFonts.outfit(fontSize: 22, fontWeight: FontWeight.w900, color: Colors.white),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      gradient: AppTheme.pinkGradient,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'SIMULATION',
                      style: GoogleFonts.outfit(fontSize: 10, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 1.5),
                    ),
                  ),
                ],
              ),
              Text('Match Centre — simulate rounds, track standings', style: AppTheme.bodyMedium),
            ],
          ),
        ),
      ],
    );

    Widget desktopLayout() {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 3,
            child: SingleChildScrollView(child: _buildMatchCentre(context, provider)),
          ),
          const SizedBox(width: 20),
          Expanded(
            flex: 2,
            child: SingleChildScrollView(child: _buildPointsTable(context, provider)),
          ),
        ],
      );
    }

    Widget mobileLayout() {
      switch (_mobileTabIndex) {
        case 0:
          return SingleChildScrollView(child: _buildMatchCentre(context, provider));
        case 1:
          return SingleChildScrollView(child: _buildPointsTable(context, provider));
        default:
          return const SizedBox.shrink();
      }
    }

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: Stack(
        children: [
          Positioned(
            bottom: -80,
            left: -80,
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [AppTheme.neonPink.withOpacity(0.06), Colors.transparent],
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
          ? BottomNavigationBar(
              currentIndex: _mobileTabIndex,
              onTap: (idx) => setState(() => _mobileTabIndex = idx),
              backgroundColor: AppTheme.surfaceCard,
              selectedItemColor: AppTheme.neonPink,
              unselectedItemColor: AppTheme.textMuted,
              selectedLabelStyle: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.bold),
              unselectedLabelStyle: GoogleFonts.inter(fontSize: 10),
              items: const [
                BottomNavigationBarItem(icon: Icon(Icons.sports_cricket), label: 'Match Centre'),
                BottomNavigationBarItem(icon: Icon(Icons.table_chart_rounded), label: 'Points Table'),
              ],
            )
          : null,
    );
  }
}
