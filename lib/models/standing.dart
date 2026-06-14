class Standing {
  final String team;
  int played;
  int wins;
  int losses;
  int points;

  Standing({
    required this.team,
    this.played = 0,
    this.wins = 0,
    this.losses = 0,
    this.points = 0,
  });

  factory Standing.fromJson(Map<String, dynamic> json) {
    return Standing(
      team: json['team'] as String? ?? '',
      played: json['played'] as int? ?? 0,
      wins: json['wins'] as int? ?? 0,
      losses: json['losses'] as int? ?? 0,
      points: json['points'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'team': team,
      'played': played,
      'wins': wins,
      'losses': losses,
      'points': points,
    };
  }
}
