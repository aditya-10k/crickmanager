class SimMatchResult {
  final int round;
  final String homeTeam;
  final String awayTeam;
  final int homeScore;
  final int homeWickets;
  final int awayScore;
  final int awayWickets;
  final String winner;

  SimMatchResult({
    required this.round,
    required this.homeTeam,
    required this.awayTeam,
    required this.homeScore,
    required this.homeWickets,
    required this.awayScore,
    required this.awayWickets,
    required this.winner,
  });

  factory SimMatchResult.fromJson(Map<String, dynamic> json) {
    return SimMatchResult(
      round: json['round'] as int? ?? 0,
      homeTeam: json['homeTeam'] as String? ?? json['home_team'] as String? ?? 'Home',
      awayTeam: json['awayTeam'] as String? ?? json['away_team'] as String? ?? 'Away',
      homeScore: json['homeScore'] as int? ?? json['home_score'] as int? ?? 0,
      homeWickets: json['homeWickets'] as int? ?? json['home_wickets'] as int? ?? 0,
      awayScore: json['awayScore'] as int? ?? json['away_score'] as int? ?? 0,
      awayWickets: json['awayWickets'] as int? ?? json['away_wickets'] as int? ?? 0,
      winner: json['winner'] as String? ?? 'Draw',
    );
  }
}
