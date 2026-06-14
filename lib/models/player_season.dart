class PlayerSeason {
  final int id;
  final String player;
  final int season;
  final String team;
  final String role;
  final String inferredNationality;
  final String battingStyle;
  final String bowlingStyle;
  final int isWicketkeeperCareer;
  final int runsScored;
  final int wicketsTaken;
  final int ballsFaced;
  final int ballsBowled;
  final double battingRating;
  final double bowlingRating;
  final double ppBatRating;
  final double ppBowlRating;
  final double deathBatRating;
  final double deathBowlRating;
  final double clutchRating;
  final double overallRating;
  final double cost;

  PlayerSeason({
    required this.id,
    required this.player,
    required this.season,
    required this.team,
    required this.role,
    required this.inferredNationality,
    required this.battingStyle,
    required this.bowlingStyle,
    required this.isWicketkeeperCareer,
    required this.runsScored,
    required this.wicketsTaken,
    required this.ballsFaced,
    required this.ballsBowled,
    required this.battingRating,
    required this.bowlingRating,
    required this.ppBatRating,
    required this.ppBowlRating,
    required this.deathBatRating,
    required this.deathBowlRating,
    required this.clutchRating,
    required this.overallRating,
    required this.cost,
  });

  factory PlayerSeason.fromJson(Map<String, dynamic> json) {
    return PlayerSeason(
      id: json['id'] as int,
      player: json['player'] as String? ?? 'Unknown Player',
      season: json['season'] as int? ?? 0,
      team: json['team'] as String? ?? 'Unknown Team',
      role: json['role'] as String? ?? 'AR',
      inferredNationality: json['inferredNationality'] as String? ?? 'India',
      battingStyle: json['battingStyle'] as String? ?? 'Right-hand-bat',
      bowlingStyle: json['bowlingStyle'] as String? ?? 'unknown',
      isWicketkeeperCareer: json['isWicketkeeperCareer'] as int? ?? 0,
      runsScored: json['runsScored'] as int? ?? 0,
      wicketsTaken: json['wicketsTaken'] as int? ?? 0,
      ballsFaced: json['ballsFaced'] as int? ?? 0,
      ballsBowled: json['ballsBowled'] as int? ?? 0,
      battingRating: (json['battingRating'] as num?)?.toDouble() ?? 50.0,
      bowlingRating: (json['bowlingRating'] as num?)?.toDouble() ?? 50.0,
      ppBatRating: (json['ppBatRating'] as num?)?.toDouble() ?? 50.0,
      ppBowlRating: (json['ppBowlRating'] as num?)?.toDouble() ?? 50.0,
      deathBatRating: (json['deathBatRating'] as num?)?.toDouble() ?? 50.0,
      deathBowlRating: (json['deathBowlRating'] as num?)?.toDouble() ?? 50.0,
      clutchRating: (json['clutchRating'] as num?)?.toDouble() ?? 50.0,
      overallRating: (json['overallRating'] as num?)?.toDouble() ?? 50.0,
      cost: (json['cost'] as num?)?.toDouble() ?? 0.5,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'player': player,
      'season': season,
      'team': team,
      'role': role,
      'inferredNationality': inferredNationality,
      'battingStyle': battingStyle,
      'bowlingStyle': bowlingStyle,
      'isWicketkeeperCareer': isWicketkeeperCareer,
      'runsScored': runsScored,
      'wicketsTaken': wicketsTaken,
      'ballsFaced': ballsFaced,
      'ballsBowled': ballsBowled,
      'battingRating': battingRating,
      'bowlingRating': bowlingRating,
      'ppBatRating': ppBatRating,
      'ppBowlRating': ppBowlRating,
      'deathBatRating': deathBatRating,
      'deathBowlRating': deathBowlRating,
      'clutchRating': clutchRating,
      'overallRating': overallRating,
      'cost': cost,
    };
  }
}
