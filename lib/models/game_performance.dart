class GamePerformance {
  final int? id;
  final String? username;
  final int seasonBeaten;
  final int wins;
  final int losses;
  final int finalPosition;
  final bool champion;
  final String mvp;
  final String biggestBargain;
  final String worstPick;
  final String? timestamp;

  GamePerformance({
    this.id,
    this.username,
    required this.seasonBeaten,
    required this.wins,
    required this.losses,
    required this.finalPosition,
    required this.champion,
    required this.mvp,
    required this.biggestBargain,
    required this.worstPick,
    this.timestamp,
  });

  factory GamePerformance.fromJson(Map<String, dynamic> json) {
    return GamePerformance(
      id: json['id'] as int?,
      username: json['username'] as String?,
      seasonBeaten: json['seasonBeaten'] as int? ?? json['season_beaten'] as int? ?? 0,
      wins: json['wins'] as int? ?? 0,
      losses: json['losses'] as int? ?? 0,
      finalPosition: json['finalPosition'] as int? ?? json['final_position'] as int? ?? 0,
      champion: json['champion'] as bool? ?? false,
      mvp: json['mvp'] as String? ?? 'None',
      biggestBargain: json['biggestBargain'] as String? ?? json['biggest_bargain'] as String? ?? 'None',
      worstPick: json['worstPick'] as String? ?? json['worst_pick'] as String? ?? 'None',
      timestamp: json['timestamp'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'seasonBeaten': seasonBeaten,
      'wins': wins,
      'losses': losses,
      'finalPosition': finalPosition,
      'champion': champion,
      'mvp': mvp,
      'biggestBargain': biggestBargain,
      'worstPick': worstPick,
    };
  }
}
