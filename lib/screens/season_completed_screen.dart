import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';

import '../services/api_service.dart';
import '../widgets/glass_panel.dart';
import '../models/standing.dart';
import '../theme/app_theme.dart';

class SeasonCompletedScreen extends StatelessWidget {
  const SeasonCompletedScreen({Key? key}) : super(key: key);

  Widget _buildSummaryCard(BuildContext context, GameProvider provider) {
    final standings = provider.standings;
    final userRecord = standings.firstWhere(
      (s) => s.team == 'Your Moneyball XI',
      orElse: () => Standing(team: 'Your Moneyball XI'),
    );

    final wins = userRecord.wins;
    final losses = userRecord.losses;
    final finalPos = standings.indexWhere((s) => s.team == 'Your Moneyball XI') + 1;
    final isChampion = provider.playoffFinal != null && provider.playoffFinal!.winner == 'Your Moneyball XI';

    return GlassPanel(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isChampion ? AppTheme.gold.withOpacity(0.12) : AppTheme.neonPinkDim,
              shape: BoxShape.circle,
              boxShadow: isChampion
                  ? [BoxShadow(color: AppTheme.gold.withOpacity(0.3), blurRadius: 30, spreadRadius: 5)]
                  : AppTheme.pinkGlow,
            ),
            child: Icon(
              isChampion ? Icons.workspace_premium_rounded : Icons.sports_cricket,
              color: isChampion ? AppTheme.gold : AppTheme.neonPink,
              size: 48,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            isChampion ? '🏆 CONGRATULATIONS CHAMPION!' : 'SEASON COMPLETED',
            style: GoogleFonts.outfit(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: isChampion ? AppTheme.gold : Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Your Moneyball XI finished the IPL ${provider.selectedSeason} campaign!',
            style: AppTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
          const Divider(color: Colors.white12, height: 32),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Column(
                children: [
                  Text('RECORD', style: GoogleFonts.inter(fontSize: 10, color: const Color(0xFF64748B), fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text('$wins W - $losses L', style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                ],
              ),
              Container(width: 1, height: 32, color: Colors.white12),
              Column(
                children: [
                  Text('POSITION', style: GoogleFonts.inter(fontSize: 10, color: const Color(0xFF64748B), fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text('#$finalPos', style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: const Color(0xFF10B981))),
                ],
              ),
              Container(width: 1, height: 32, color: Colors.white12),
              Column(
                children: [
                  Text('RESULT', style: AppTheme.label),
                  const SizedBox(height: 4),
                  Text(
                    isChampion ? 'CHAMPION' : finalPos <= 4 ? 'PLAYOFFS' : 'LEAGUE',
                    style: GoogleFonts.outfit(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isChampion ? AppTheme.gold : AppTheme.neonPink,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAwardRow(String label, String value, IconData icon, Color accentColor) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: accentColor.withOpacity(0.25)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: accentColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: accentColor, size: 22),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: const Color(0xFF64748B), letterSpacing: 0.5),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAwardsCard(BuildContext context, GameProvider provider) {
    final mvp = provider.mvpPlayer;
    final bargain = provider.bargainPlayer;

    final mvpStr = mvp != null ? '${mvp.player} (${mvp.team} - ${mvp.season}) [Rtg: ${mvp.overallRating.round()}]' : 'None';
    final bargainStr = bargain != null ? '${bargain.player} (${bargain.team} - ${bargain.season}) [Value Ratio: ${(bargain.overallRating / bargain.cost).toStringAsFixed(1)}]' : 'None';

    return GlassPanel(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.military_tech, color: Color(0xFFF59E0B), size: 24),
              const SizedBox(width: 8),
              Text(
                'Moneyball Performance Awards',
                style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _buildAwardRow('MOST VALUABLE PLAYER (MVP)', mvpStr, Icons.star, const Color(0xFFFBBF24)),
          const SizedBox(height: 12),
          _buildAwardRow('BIGGEST BARGAIN', bargainStr, Icons.trending_up, const Color(0xFF10B981)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<GameProvider>(context);
    final size = MediaQuery.of(context).size;
    final isDesktop = size.width >= 900;

    final actionButtons = Column(
      children: [
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
                    final err = await provider.saveSeasonPerformance();
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
                      const Icon(Icons.cloud_upload_rounded),
                      const SizedBox(width: 8),
                      Text(
                        'SAVE & LOG PERFORMANCE',
                        style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.w800, letterSpacing: 1),
                      ),
                    ],
                  ),
          ),
        ),
        const SizedBox(height: 12),
        TextButton(
          onPressed: () => provider.restartToMenu(),
          style: TextButton.styleFrom(foregroundColor: const Color(0xFF64748B)),
          child: Text(
            'Discard & Return to Menu',
            style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );

    Widget desktopLayout() {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 1,
            child: SingleChildScrollView(
              child: Column(
                children: [
                  _buildSummaryCard(context, provider),
                  const SizedBox(height: 24),
                  actionButtons,
                ],
              ),
            ),
          ),
          const SizedBox(width: 24),
          Expanded(
            flex: 1,
            child: SingleChildScrollView(
              child: _buildAwardsCard(context, provider),
            ),
          ),
        ],
      );
    }

    Widget mobileLayout() {
      return SingleChildScrollView(
        child: Column(
          children: [
            _buildSummaryCard(context, provider),
            const SizedBox(height: 24),
            _buildAwardsCard(context, provider),
            const SizedBox(height: 24),
            actionButtons,
          ],
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Campaign Completed',
                style: GoogleFonts.outfit(fontSize: 26, fontWeight: FontWeight.w800, color: Colors.white),
              ),
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
