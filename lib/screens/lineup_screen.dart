import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';

import '../services/api_service.dart';
import '../widgets/glass_panel.dart';
import '../models/player_season.dart';
import '../theme/app_theme.dart';

class LineupScreen extends StatefulWidget {
  const LineupScreen({Key? key}) : super(key: key);

  @override
  State<LineupScreen> createState() => _LineupScreenState();
}

class _LineupScreenState extends State<LineupScreen> {
  final List<PlayerSeason> _tempStartingXI = [];
  PlayerSeason? _tempImpactPlayer;
  PlayerSeason? _tempWicketkeeper;

  @override
  void initState() {
    super.initState();
    final provider = Provider.of<GameProvider>(context, listen: false);
    _tempStartingXI.addAll(provider.startingXI);
    _tempImpactPlayer = provider.impactPlayer;
    _tempWicketkeeper = provider.wicketkeeper;
  }

  void _toggleStartingPlayer(PlayerSeason p) {
    setState(() {
      if (_tempStartingXI.any((x) => x.id == p.id)) {
        _tempStartingXI.removeWhere((x) => x.id == p.id);
        if (_tempWicketkeeper?.id == p.id) {
          _tempWicketkeeper = null;
        }
      } else {
        if (_tempStartingXI.length < 11) {
          _tempStartingXI.add(p);
          // If this is the only keeper, auto-designate
          if (_tempWicketkeeper == null && (p.isWicketkeeperCareer == 1 || p.role == 'WK')) {
            _tempWicketkeeper = p;
          }
        }
      }

      // Recompute impact player (the one drafted player that is not in the starting XI)
      final provider = Provider.of<GameProvider>(context, listen: false);
      final pool = provider.draftedPlayers;
      final remaining = pool.where((x) => !_tempStartingXI.any((s) => s.id == x.id)).toList();
      if (remaining.isNotEmpty) {
        _tempImpactPlayer = remaining.first;
      } else {
        _tempImpactPlayer = null;
      }
    });
  }

  Map<String, dynamic> _localValidation() {
    if (_tempStartingXI.length != 11) {
      return {'valid': false, 'reason': 'Lineup must contain exactly 11 players. Current count: ${_tempStartingXI.length}'};
    }
    if (_tempImpactPlayer == null) {
      return {'valid': false, 'reason': 'Please select an Impact Player.'};
    }
    if (_tempWicketkeeper == null || !_tempStartingXI.any((p) => p.id == _tempWicketkeeper!.id)) {
      return {'valid': false, 'reason': 'Please designate a wicketkeeper from the starting XI.'};
    }

    int wks = _tempStartingXI.where((p) => p.isWicketkeeperCareer == 1 || p.role == 'WK').length;
    int bowlers = _tempStartingXI.where((p) => p.role == 'BOWL' || p.role == 'AR').length;
    int spinners = _tempStartingXI.where((p) => p.bowlingStyle.toLowerCase().contains('spin') || p.bowlingStyle.toLowerCase().contains('break')).length;
    int pacers = _tempStartingXI.where((p) => p.bowlingStyle.toLowerCase().contains('fast') || p.bowlingStyle.toLowerCase().contains('medium')).length;

    if (wks < 1) {
      return {'valid': false, 'reason': 'Roster must contain at least 1 wicketkeeper (WK role or career keeper).'};
    }
    if (bowlers < 4) {
      return {'valid': false, 'reason': 'Roster must contain at least 4 bowling options (BOWL or AR). Currently: $bowlers'};
    }
    if (spinners < 1) {
      return {'valid': false, 'reason': 'Roster must contain at least 1 spin bowling option.'};
    }
    if (pacers < 1) {
      return {'valid': false, 'reason': 'Roster must contain at least 1 pace bowling option.'};
    }

    int foreigners = _tempStartingXI.where((p) => p.inferredNationality.toLowerCase() != 'india').length;
    if (foreigners > 4) {
      return {'valid': false, 'reason': 'Starting XI cannot contain more than 4 foreign players. Currently: $foreigners'};
    }

    return {'valid': true};
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<GameProvider>(context);
    final pool = provider.draftedPlayers;
    final size = MediaQuery.of(context).size;
    final isDesktop = size.width >= 900;

    final validation = _localValidation();
    final isValid = validation['valid'] as bool;

    // Strengths preview
    double sumBat = 0.0;
    double sumBowl = 0.0;
    double sumClutch = 0.0;
    if (_tempStartingXI.isNotEmpty) {
      for (var p in _tempStartingXI) {
        sumBat += p.battingRating;
        sumBowl += p.bowlingRating;
        sumClutch += p.clutchRating;
      }
      sumBat /= _tempStartingXI.length;
      sumBowl /= _tempStartingXI.length;
      sumClutch /= _tempStartingXI.length;
    }

    Widget ruleCheck(String label, bool met) {
      return Row(
        children: [
          Icon(
            met ? Icons.check_circle : Icons.error_outline,
            color: met ? const Color(0xFF10B981) : const Color(0xFFEF4444),
            size: 16,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: GoogleFonts.inter(fontSize: 12, color: met ? Colors.white70 : const Color(0xFFEF4444)),
            ),
          ),
        ],
      );
    }

    Widget checklistPanel() {
      int wks = _tempStartingXI.where((p) => p.isWicketkeeperCareer == 1 || p.role == 'WK').length;
      int bowlers = _tempStartingXI.where((p) => p.role == 'BOWL' || p.role == 'AR').length;
      int spinners = _tempStartingXI.where((p) => p.bowlingStyle.toLowerCase().contains('spin') || p.bowlingStyle.toLowerCase().contains('break')).length;
      int pacers = _tempStartingXI.where((p) => p.bowlingStyle.toLowerCase().contains('fast') || p.bowlingStyle.toLowerCase().contains('medium')).length;
      int foreigners = _tempStartingXI.where((p) => p.inferredNationality.toLowerCase() != 'india').length;

      return GlassPanel(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'LINEUP RULES CHECKLIST',
              style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: const Color(0xFF94A3B8), letterSpacing: 1.0),
            ),
            const SizedBox(height: 16),
            ruleCheck('Designate 11 Starting XI players (Currently: ${_tempStartingXI.length})', _tempStartingXI.length == 11),
            const SizedBox(height: 8),
            ruleCheck('Designate 1 Wicketkeeper from starting XI', _tempWicketkeeper != null && _tempStartingXI.any((x) => x.id == _tempWicketkeeper!.id)),
            const SizedBox(height: 8),
            ruleCheck('Designated/Career Wicketkeeper (Min: 1)', wks >= 1),
            const SizedBox(height: 8),
            ruleCheck('Bowlers / All-rounders (Min: 4)', bowlers >= 4),
            const SizedBox(height: 8),
            ruleCheck('At least 1 Spin bowler', spinners >= 1),
            const SizedBox(height: 8),
            ruleCheck('At least 1 Pace bowler', pacers >= 1),
            const SizedBox(height: 8),
            ruleCheck('Foreign players (Max: 4) (Currently: $foreigners)', foreigners <= 4),
            const Divider(color: Colors.white12, height: 32),
            Text(
              'EXPECTED SQUAD RATINGS',
              style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: const Color(0xFF94A3B8), letterSpacing: 1.0),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Batting Strength:', style: GoogleFonts.inter(color: Colors.white70, fontSize: 13)),
                Text(sumBat.toStringAsFixed(1), style: GoogleFonts.outfit(color: const Color(0xFF10B981), fontWeight: FontWeight.bold, fontSize: 15)),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Bowling Strength:', style: GoogleFonts.inter(color: Colors.white70, fontSize: 13)),
                Text(sumBowl.toStringAsFixed(1), style: GoogleFonts.outfit(color: const Color(0xFF3B82F6), fontWeight: FontWeight.bold, fontSize: 15)),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Clutch Rating:', style: GoogleFonts.inter(color: Colors.white70, fontSize: 13)),
                Text(sumClutch.toStringAsFixed(1), style: GoogleFonts.outfit(color: const Color(0xFFF59E0B), fontWeight: FontWeight.bold, fontSize: 15)),
              ],
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: isValid
                  ? () => provider.saveLineup(_tempStartingXI, _tempImpactPlayer!, _tempWicketkeeper!)
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF10B981),
                disabledBackgroundColor: const Color(0x1F1E293B),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                minimumSize: const Size.fromHeight(50),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.flash_on, size: 18),
                  const SizedBox(width: 8),
                  Text(
                    'Launch Season Simulation',
                    style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
            if (!isValid) ...[
              const SizedBox(height: 12),
              Text(
                validation['reason'] ?? '',
                style: GoogleFonts.inter(color: const Color(0xFFEF4444), fontSize: 11),
                textAlign: TextAlign.center,
              ),
            ]
          ],
        ),
      );
    }

    Widget selectorsList() {
      return GlassPanel(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'SELECT STARTING XI (SELECT EXACTLY 11)',
              style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: const Color(0xFF94A3B8), letterSpacing: 1.0),
            ),
            const SizedBox(height: 16),
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: pool.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, idx) {
                final p = pool[idx];
                final isStarting = _tempStartingXI.any((x) => x.id == p.id);
                final isImpact = _tempImpactPlayer?.id == p.id;
                final isWk = p.isWicketkeeperCareer == 1 || p.role == 'WK';
                final isDesignatedWK = _tempWicketkeeper?.id == p.id;

                return Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isStarting
                        ? const Color(0x0F10B981)
                        : isImpact
                            ? const Color(0x0FA855F7)
                            : const Color(0x1F0F172A),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isStarting
                          ? const Color(0x3310B981)
                          : isImpact
                              ? const Color(0x33A855F7)
                              : Colors.white.withOpacity(0.04),
                    ),
                  ),
                  child: Row(
                    children: [
                      // Starting XI Checkbox
                      Checkbox(
                        value: isStarting,
                        onChanged: (_) => _toggleStartingPlayer(p),
                        activeColor: const Color(0xFF10B981),
                      ),
                      const SizedBox(width: 8),
                      // Details
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  p.player,
                                  style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 14),
                                ),
                                const SizedBox(width: 8),
                                if (isImpact)
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: const Color(0x26A855F7),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      'IMPACT',
                                      style: GoogleFonts.outfit(color: const Color(0xFFA855F7), fontSize: 9, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${p.role} | ${p.team} | Rtg: ${p.overallRating.round()} | Cost: ${p.cost} Cr',
                              style: GoogleFonts.inter(color: const Color(0xFF64748B), fontSize: 11),
                            ),
                          ],
                        ),
                      ),
                      // WK Selector (Only if starting)
                      if (isStarting) ...[
                        TextButton.icon(
                          onPressed: () {
                            setState(() {
                              _tempWicketkeeper = p;
                            });
                          },
                          icon: Icon(
                            isDesignatedWK ? Icons.radio_button_checked : Icons.radio_button_unchecked,
                            color: isDesignatedWK ? const Color(0xFFFBBF24) : const Color(0xFF64748B),
                            size: 16,
                          ),
                          label: Text(
                            isDesignatedWK ? 'WK' : 'Set WK',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: isDesignatedWK ? const Color(0xFFFBBF24) : const Color(0xFF64748B),
                              fontWeight: isDesignatedWK ? FontWeight.bold : FontWeight.normal,
                            ),
                          ),
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                        ),
                      ],
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Lineup Selection',
                style: GoogleFonts.outfit(fontSize: 26, fontWeight: FontWeight.w800, color: Colors.white),
              ),
              const SizedBox(height: 4),
              Text(
                'Finalize your starting XI, wicketkeeper, and confirm roster rules.',
                style: GoogleFonts.inter(fontSize: 14, color: const Color(0xFF94A3B8)),
              ),
              const SizedBox(height: 24),
              if (isDesktop)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(flex: 3, child: selectorsList()),
                    const SizedBox(width: 24),
                    Expanded(flex: 2, child: checklistPanel()),
                  ],
                )
              else
                Column(
                  children: [
                    checklistPanel(),
                    const SizedBox(height: 24),
                    selectorsList(),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}
