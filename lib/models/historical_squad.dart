class HistoricalSquad {
  final int id;
  final String team;
  final int season;
  final int squadSize;
  final double battingStrength;
  final double bowlingStrength;
  final double clutchStrength;
  final double overallStrength;

  HistoricalSquad({
    required this.id,
    required this.team,
    required this.season,
    required this.squadSize,
    required this.battingStrength,
    required this.bowlingStrength,
    required this.clutchStrength,
    required this.overallStrength,
  });

  factory HistoricalSquad.fromJson(Map<String, dynamic> json) {
    return HistoricalSquad(
      id: json['id'] as int? ?? 0,
      team: json['team'] as String? ?? 'Unknown Team',
      season: json['season'] as int? ?? 0,
      squadSize: json['squadSize'] as int? ?? 0,
      battingStrength: (json['battingStrength'] as num?)?.toDouble() ?? 75.0,
      bowlingStrength: (json['bowlingStrength'] as num?)?.toDouble() ?? 75.0,
      clutchStrength: (json['clutchStrength'] as num?)?.toDouble() ?? 75.0,
      overallStrength: (json['overallStrength'] as num?)?.toDouble() ?? 75.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'team': team,
      'season': season,
      'squadSize': squadSize,
      'battingStrength': battingStrength,
      'bowlingStrength': bowlingStrength,
      'clutchStrength': clutchStrength,
      'overallStrength': overallStrength,
    };
  }
}
