import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../models/player_season.dart';
import '../models/historical_squad.dart';
import '../models/game_performance.dart';
import '../models/standing.dart';
import '../models/sim_match_result.dart';

class GameProvider extends ChangeNotifier {
  // Base URLs
  String getBaseUrl() {
    if (kIsWeb) {
      // Production: Flutter web on Firebase → backend on HuggingFace Spaces
      const hfBackend = 'https://adityx10-crickmanager.hf.space';
      return hfBackend;
    } else {
      return 'http://10.0.2.2:8080'; // Android emulator localhost address
    }
  }

  // State Variables
  String? _token;
  String? _username;
  bool _isLoading = false;
  String _gameState = 'login'; // 'login', 'menu', 'draft', 'lineup', 'sim', 'complete'
  String? _error; // surface errors to the UI

  // Metadata Lists
  List<int> _seasons = [];
  List<HistoricalSquad> _allSquads = [];
  List<GamePerformance> _history = [];
  List<Map<String, dynamic>> _leaderboard = [];

  // Active Game State
  int? _selectedSeason;
  List<HistoricalSquad> _opponents = [];
  HistoricalSquad? _replacedTeam;
  int _draftRound = 1;
  double _budget = 100.0;
  bool _skipUsed = false;
  List<PlayerSeason> _draftedPlayers = [];
  List<String> _draftedSquadKeys = []; // "team-season"

  // Current Draft Pool
  HistoricalSquad? _currentDraftSquad;
  List<PlayerSeason> _currentDraftPlayers = [];

  // Lineup Selection
  List<PlayerSeason> _startingXI = [];
  PlayerSeason? _impactPlayer;
  PlayerSeason? _wicketkeeper;

  // Simulation State
  int _simRound = 1;
  List<Standing> _standings = [];
  List<SimMatchResult> _leagueMatches = [];
  List<String> _playoffTeams = []; // Top 4
  String _playoffStage = 'none'; // 'none', 'q1', 'elim', 'q2', 'final', 'complete'
  SimMatchResult? _playoffQ1;
  SimMatchResult? _playoffElim;
  SimMatchResult? _playoffQ2;
  SimMatchResult? _playoffFinal;

  // Post-Season Awards
  PlayerSeason? _mvpPlayer;
  PlayerSeason? _bargainPlayer;
  PlayerSeason? _worstPlayer;

  // Getters
  String? get token => _token;
  String? get username => _username;
  bool get isLoading => _isLoading;
  String get gameState => _gameState;
  String? get error => _error;
  List<int> get seasons => _seasons;
  List<HistoricalSquad> get allSquads => _allSquads;
  List<GamePerformance> get history => _history;
  List<Map<String, dynamic>> get leaderboard => _leaderboard;

  int? get selectedSeason => _selectedSeason;
  List<HistoricalSquad> get opponents => _opponents;
  HistoricalSquad? get replacedTeam => _replacedTeam;
  int get draftRound => _draftRound;
  double get budget => _budget;
  bool get skipUsed => _skipUsed;
  List<PlayerSeason> get draftedPlayers => _draftedPlayers;
  List<String> get draftedSquadKeys => _draftedSquadKeys;

  HistoricalSquad? get currentDraftSquad => _currentDraftSquad;
  List<PlayerSeason> get currentDraftPlayers => _currentDraftPlayers;

  List<PlayerSeason> get startingXI => _startingXI;
  PlayerSeason? get impactPlayer => _impactPlayer;
  PlayerSeason? get wicketkeeper => _wicketkeeper;

  int get simRound => _simRound;
  List<Standing> get standings => _standings;
  List<SimMatchResult> get leagueMatches => _leagueMatches;
  List<String> get playoffTeams => _playoffTeams;
  String get playoffStage => _playoffStage;
  SimMatchResult? get playoffQ1 => _playoffQ1;
  SimMatchResult? get playoffElim => _playoffElim;
  SimMatchResult? get playoffQ2 => _playoffQ2;
  SimMatchResult? get playoffFinal => _playoffFinal;

  PlayerSeason? get mvpPlayer => _mvpPlayer;
  PlayerSeason? get bargainPlayer => _bargainPlayer;
  PlayerSeason? get worstPlayer => _worstPlayer;

  final Random _random = Random();

  GameProvider() {
    _loadAuthToken();
  }

  // Load Saved Auth Token
  Future<void> _loadAuthToken() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('cric_jwt');
    _username = prefs.getString('cric_username');
    if (_token != null && _username != null) {
      _gameState = 'menu';
      _fetchInitialData();
    } else {
      _gameState = 'login';
    }
    notifyListeners();
  }

  Map<String, String> _getHeaders() {
    return {
      'Content-Type': 'application/json',
      if (_token != null) 'Authorization': 'Bearer $_token',
    };
  }

  // Fetch initial reference lists
  Future<void> _fetchInitialData() async {
    _isLoading = true;
    notifyListeners();

    try {
      final baseUrl = getBaseUrl();
      // Fetch seasons
      final seasonsRes = await http.get(Uri.parse('$baseUrl/api/players/seasons'), headers: _getHeaders());
      if (seasonsRes.statusCode == 200) {
        final List<dynamic> data = json.decode(seasonsRes.body);
        _seasons = data.map((x) => x as int).toList();
      }

      // Fetch all squads
      final squadsRes = await http.get(Uri.parse('$baseUrl/api/players/squads'), headers: _getHeaders());
      if (squadsRes.statusCode == 200) {
        final List<dynamic> data = json.decode(squadsRes.body);
        _allSquads = data.map((x) => HistoricalSquad.fromJson(x)).toList();
      }

      if (_username != null) {
        await fetchUserHistory();
        await fetchLeaderboard();
      }
    } catch (e) {
      print('Error fetching initial data: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchUserHistory() async {
    if (_username == null) return;
    try {
      final baseUrl = getBaseUrl();
      final historyRes = await http.get(Uri.parse('$baseUrl/api/game/history/$_username'), headers: _getHeaders());
      if (historyRes.statusCode == 200) {
        final List<dynamic> data = json.decode(historyRes.body);
        _history = data.map((x) => GamePerformance.fromJson(x)).toList();
      }
    } catch (e) {
      print('Error fetching history: $e');
    }
  }

  Future<void> fetchLeaderboard() async {
    try {
      final baseUrl = getBaseUrl();
      final leaderboardRes = await http.get(Uri.parse('$baseUrl/api/game/leaderboard'), headers: _getHeaders());
      if (leaderboardRes.statusCode == 200) {
        final List<dynamic> data = json.decode(leaderboardRes.body);
        _leaderboard = data.map((x) => x as Map<String, dynamic>).toList();
      }
    } catch (e) {
      print('Error fetching leaderboard: $e');
    }
  }

  // Auth Functions
  Future<String?> login(String username, String password) async {
    _isLoading = true;
    notifyListeners();

    try {
      final baseUrl = getBaseUrl();
      final res = await http.post(
        Uri.parse('$baseUrl/api/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'username': username, 'password': password}),
      );

      final Map<String, dynamic> data = json.decode(res.body);
      if (res.statusCode == 200) {
        _token = data['token'];
        _username = data['username'];
        _gameState = 'menu';

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('cric_jwt', _token!);
        await prefs.setString('cric_username', _username!);

        await _fetchInitialData();
        return null;
      } else {
        return data['error'] ?? 'Login failed.';
      }
    } catch (e) {
      return 'Server unavailable: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<String?> register(String username, String password) async {
    _isLoading = true;
    notifyListeners();

    try {
      final baseUrl = getBaseUrl();
      final res = await http.post(
        Uri.parse('$baseUrl/api/auth/register'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'username': username, 'password': password}),
      );

      final Map<String, dynamic> data = json.decode(res.body);
      if (res.statusCode == 200) {
        return null; // Success, user can log in now
      } else {
        return data['error'] ?? 'Registration failed.';
      }
    } catch (e) {
      return 'Server unavailable: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    _token = null;
    _username = null;
    _gameState = 'login';
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('cric_jwt');
    await prefs.remove('cric_username');
    notifyListeners();
  }

  // Start Campaign: Random Season Chosen
  Future<void> startNewGame() async {
    // If seasons not loaded yet, try fetching them now
    if (_seasons.isEmpty) {
      _isLoading = true;
      _error = null;
      notifyListeners();
      try {
        final baseUrl = getBaseUrl();
        final seasonsRes = await http.get(
          Uri.parse('$baseUrl/api/players/seasons'),
          headers: _getHeaders(),
        );
        if (seasonsRes.statusCode == 200) {
          final List<dynamic> data = json.decode(seasonsRes.body);
          _seasons = data.map((x) => x as int).toList();
        }
        final squadsRes = await http.get(
          Uri.parse('$baseUrl/api/players/squads'),
          headers: _getHeaders(),
        );
        if (squadsRes.statusCode == 200) {
          final List<dynamic> data = json.decode(squadsRes.body);
          _allSquads = data.map((x) => HistoricalSquad.fromJson(x)).toList();
        }
      } catch (e) {
        _error = 'Could not reach server. Please try again.';
        _isLoading = false;
        notifyListeners();
        return;
      }
      if (_seasons.isEmpty) {
        _error = 'No IPL seasons found in database. Check backend.';
        _isLoading = false;
        notifyListeners();
        return;
      }
    }

    _isLoading = true;
    _error = null;
    _gameState = 'draft';
    _draftRound = 1;
    _draftedPlayers = [];
    _budget = 100.0;
    _draftedSquadKeys = [];
    _skipUsed = false;
    _playoffStage = 'none';
    _startingXI = [];
    _impactPlayer = null;
    _wicketkeeper = null;
    notifyListeners();

    final randSeason = _seasons[_random.nextInt(_seasons.length)];
    _selectedSeason = randSeason;

    try {
      final baseUrl = getBaseUrl();
      final res = await http.get(Uri.parse('$baseUrl/api/players/squads/by-season/$randSeason'), headers: _getHeaders());
      if (res.statusCode == 200) {
        final List<dynamic> data = json.decode(res.body);
        final squads = data.map((x) => HistoricalSquad.fromJson(x)).toList();

        // CSK-vs-CSK self pairing bug fix:
        // We have N squads in this season. We randomly select 1 squad to replace with our user team.
        // This keeps the total league team count even (e.g. 7 opponents + 1 user team = 8 total).
        if (squads.isNotEmpty) {
          final replacedIdx = _random.nextInt(squads.length);
          _replacedTeam = squads[replacedIdx];
          _opponents = squads.where((s) => s.id != _replacedTeam!.id).toList();
          print('User replaces ${_replacedTeam!.team} for Season $randSeason');
        } else {
          _opponents = [];
          _replacedTeam = null;
        }
      }
    } catch (e) {
      print('Error loading opponents: $e');
    }

    generateNextDraftSquad();
  }

  void generateNextDraftSquad() async {
    final available = _allSquads.where((s) {
      final key = '${s.team}-${s.season}';
      return !_draftedSquadKeys.contains(key) && s.squadSize >= 11;
    }).toList();

    if (available.isEmpty) {
      _gameState = 'menu';
      notifyListeners();
      return;
    }

    final squad = available[_random.nextInt(available.length)];
    _currentDraftSquad = squad;
    _currentDraftPlayers = [];
    _isLoading = true;
    notifyListeners();

    try {
      final baseUrl = getBaseUrl();
      final res = await http.get(Uri.parse('$baseUrl/api/players/squad/${squad.team}/${squad.season}'), headers: _getHeaders());
      if (res.statusCode == 200) {
        final List<dynamic> data = json.decode(res.body);
        final players = data.map((x) => PlayerSeason.fromJson(x)).toList();
        players.sort((a, b) => b.overallRating.compareTo(a.overallRating));

        // Filter out players who are already drafted (by name, case-insensitive, excluding local reserves)
        final draftedNames = _draftedPlayers
            .where((x) => !x.player.startsWith('Local Reserve'))
            .map((x) => x.player.toLowerCase())
            .toSet();
        final filteredPlayers = players.where((p) => !draftedNames.contains(p.player.toLowerCase())).toList();

        // Inject Local Reserves to prevent bankruptcy/draft lock
        final idOffset = squad.id;
        final reserves = [
          PlayerSeason(
            id: -100 - idOffset,
            player: 'Local Reserve (BAT)',
            season: squad.season,
            team: squad.team,
            role: 'BAT',
            inferredNationality: 'India',
            battingStyle: 'Right-hand-bat',
            bowlingStyle: 'unknown',
            isWicketkeeperCareer: 0,
            runsScored: 0, wicketsTaken: 0, ballsFaced: 0, ballsBowled: 0,
            battingRating: 60.0, bowlingRating: 50.0,
            ppBatRating: 60.0, ppBowlRating: 50.0,
            deathBatRating: 60.0, deathBowlRating: 50.0,
            clutchRating: 60.0, overallRating: 60.0,
            cost: 0.5,
          ),
          PlayerSeason(
            id: -200 - idOffset,
            player: 'Local Reserve (BOWL)',
            season: squad.season,
            team: squad.team,
            role: 'BOWL',
            inferredNationality: 'India',
            battingStyle: 'Right-hand-bat',
            bowlingStyle: 'Right-arm-fast-medium',
            isWicketkeeperCareer: 0,
            runsScored: 0, wicketsTaken: 0, ballsFaced: 0, ballsBowled: 0,
            battingRating: 50.0, bowlingRating: 60.0,
            ppBatRating: 50.0, ppBowlRating: 60.0,
            deathBatRating: 50.0, deathBowlRating: 60.0,
            clutchRating: 60.0, overallRating: 60.0,
            cost: 0.5,
          ),
          PlayerSeason(
            id: -300 - idOffset,
            player: 'Local Reserve (AR)',
            season: squad.season,
            team: squad.team,
            role: 'AR',
            inferredNationality: 'India',
            battingStyle: 'Right-hand-bat',
            bowlingStyle: 'Right-arm-offbreak',
            isWicketkeeperCareer: 0,
            runsScored: 0, wicketsTaken: 0, ballsFaced: 0, ballsBowled: 0,
            battingRating: 58.0, bowlingRating: 58.0,
            ppBatRating: 58.0, ppBowlRating: 58.0,
            deathBatRating: 58.0, deathBowlRating: 58.0,
            clutchRating: 60.0, overallRating: 60.0,
            cost: 0.5,
          ),
          PlayerSeason(
            id: -400 - idOffset,
            player: 'Local Reserve (WK)',
            season: squad.season,
            team: squad.team,
            role: 'WK',
            inferredNationality: 'India',
            battingStyle: 'Right-hand-bat',
            bowlingStyle: 'unknown',
            isWicketkeeperCareer: 1,
            runsScored: 0, wicketsTaken: 0, ballsFaced: 0, ballsBowled: 0,
            battingRating: 59.0, bowlingRating: 40.0,
            ppBatRating: 59.0, ppBowlRating: 40.0,
            deathBatRating: 59.0, deathBowlRating: 40.0,
            clutchRating: 60.0, overallRating: 60.0,
            cost: 0.5,
          ),
        ];

        _currentDraftPlayers = [...filteredPlayers, ...reserves];
      }
    } catch (e) {
      print('Error fetching squad players: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void draftPlayer(PlayerSeason p) {
    if (p.cost > _budget) return;

    final isForeigner = p.inferredNationality.toLowerCase() != 'india';
    final foreignersCount = _draftedPlayers.where((x) => x.inferredNationality.toLowerCase() != 'india').length;
    if (isForeigner && foreignersCount >= 5) return;

    _budget = double.parse((_budget - p.cost).toStringAsFixed(1));
    _draftedPlayers.add(p);
    _draftedSquadKeys.add('${p.team}-${p.season}');

    if (_draftRound == 12) {
      // Auto-fill Lineup selection to make it easier for user
      _startingXI = _draftedPlayers.take(11).toList();
      _impactPlayer = _draftedPlayers[11];
      
      // Auto-select wicketkeeper if available
      final keepers = _draftedPlayers.where((x) => x.isWicketkeeperCareer == 1 || x.role == 'WK').toList();
      if (keepers.isNotEmpty) {
        _wicketkeeper = keepers[0];
      } else {
        _wicketkeeper = _startingXI[0]; // fallback
      }

      _gameState = 'lineup';
    } else {
      _draftRound++;
      generateNextDraftSquad();
    }
    notifyListeners();
  }

  bool get canSkip {
    if (_skipUsed) return false; // One-time use only
    final available = _allSquads.where((s) {
      final key = '${s.team}-${s.season}';
      return !_draftedSquadKeys.contains(key) && s.squadSize >= 11;
    }).toList();
    return available.length > (12 - _draftRound + 1);
  }

  void skipCurrentSquad() {
    if (_currentDraftSquad == null || !canSkip) return;
    _skipUsed = true; // Mark as used — cannot skip again this campaign
    _draftedSquadKeys.add('${_currentDraftSquad!.team}-${_currentDraftSquad!.season}');
    generateNextDraftSquad();
  }

  // Roster Validations
  Map<String, dynamic> checkLineupValidity() {
    if (_startingXI.length != 11) {
      return {'valid': false, 'reason': 'Starting XI must contain exactly 11 players.'};
    }
    if (_impactPlayer == null) {
      return {'valid': false, 'reason': 'Please select an Impact Player.'};
    }
    if (_wicketkeeper == null || !_startingXI.any((p) => p.id == _wicketkeeper!.id)) {
      return {'valid': false, 'reason': 'Starting XI must contain a designated wicketkeeper.'};
    }

    // Role checks
    int wks = _startingXI.where((p) => p.isWicketkeeperCareer == 1 || p.role == 'WK').length;
    int bowlers = _startingXI.where((p) => p.role == 'BOWL' || p.role == 'AR').length;
    int spinners = _startingXI.where((p) => p.bowlingStyle.toLowerCase().contains('spin') || p.bowlingStyle.toLowerCase().contains('break')).length;
    int pacers = _startingXI.where((p) => p.bowlingStyle.toLowerCase().contains('fast') || p.bowlingStyle.toLowerCase().contains('medium')).length;

    if (wks < 1) {
      return {'valid': false, 'reason': 'Roster must contain at least 1 wicketkeeper (designated or career WK).'};
    }
    if (bowlers < 4) {
      return {'valid': false, 'reason': 'Roster must contain at least 4 bowling options (BOWL or AR).'};
    }
    if (spinners < 1) {
      return {'valid': false, 'reason': 'Roster must contain at least 1 spin bowling option.'};
    }
    if (pacers < 1) {
      return {'valid': false, 'reason': 'Roster must contain at least 1 pace bowling option.'};
    }

    // Foreigner cap check (max 4)
    int foreigners = _startingXI.where((p) => p.inferredNationality.toLowerCase() != 'india').length;
    if (foreigners > 4) {
      return {'valid': false, 'reason': 'Starting XI cannot contain more than 4 foreign players. Currently: $foreigners'};
    }

    return {'valid': true};
  }

  void saveLineup(List<PlayerSeason> start, PlayerSeason impact, PlayerSeason wk) {
    _startingXI = start;
    _impactPlayer = impact;
    _wicketkeeper = wk;
    initializeSimulation();
  }

  // Generate double round robin schedule (zeroed out initially)
  void initializeSimulation() {
    if (_selectedSeason == null || _opponents.isEmpty) return;

    _gameState = 'sim';
    _simRound = 1;
    _leagueMatches = [];
    _playoffStage = 'none';

    // Standings initialization
    const userTeamName = 'Your Moneyball XI';
    final teams = _opponents.map((o) => o.team).toList();

    _standings = [userTeamName, ...teams].map((t) => Standing(team: t)).toList();
    notifyListeners();
  }

  List<Map<String, String>> getFixturesForRound(int r) {
    const userTeamName = 'Your Moneyball XI';
    final teams = _opponents.map((o) => o.team).toList();
    final allTeams = [userTeamName, ...teams];
    final numTeams = allTeams.length;
    final list = List<String>.from(allTeams);
    final fixtures = <Map<String, String>>[];

    // Standard circular robin scheduler
    for (int currentRound = 0; currentRound < r; currentRound++) {
      if (currentRound == r - 1) {
        for (int i = 0; i < numTeams / 2; i++) {
          final home = list[i];
          final away = list[numTeams - 1 - i];
          if (r - 1 < numTeams - 1) {
            if ((r - 1) % 2 == 0) {
              fixtures.add({'home': home, 'away': away});
            } else {
              fixtures.add({'home': away, 'away': home});
            }
          } else {
            if ((r - 1) % 2 == 0) {
              fixtures.add({'home': away, 'away': home});
            } else {
              fixtures.add({'home': home, 'away': away});
            }
          }
        }
      }
      final temp = list.removeLast();
      list.insert(1, temp);
    }
    return fixtures;
  }

  // Simulate group stage on backend in a single request
  Future<String?> simulateGroupStage() async {
    if (_selectedSeason == null || _opponents.isEmpty || _startingXI.isEmpty) {
      return 'Campaign not properly initialized.';
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final baseUrl = getBaseUrl();
      final body = {
        'season': _selectedSeason,
        'replacedTeam': _replacedTeam?.team ?? '',
        'opponents': _opponents.map((o) => o.team).toList(),
        'startingXI': _startingXI.map((p) => {
          'id': p.id,
          'player': p.player,
          'battingRating': p.battingRating,
          'bowlingRating': p.bowlingRating,
          'clutchRating': p.clutchRating,
        }).toList(),
      };

      final res = await http.post(
        Uri.parse('$baseUrl/api/game/simulate-group-stage'),
        headers: _getHeaders(),
        body: json.encode(body),
      );

      if (res.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(res.body);
        final List<dynamic> fixturesJson = data['fixtures'];
        final List<dynamic> standingsJson = data['standings'];

        _leagueMatches = fixturesJson.map((x) => SimMatchResult.fromJson(x)).toList();
        _standings = standingsJson.map((x) => Standing.fromJson(x)).toList();

        // Set up playoff parameters
        _playoffTeams = _standings.take(4).map((s) => s.team).toList();
        _playoffStage = 'q1';
        _simRound = 15; // League round completed
        return null;
      } else if (res.statusCode == 403 || res.statusCode == 401) {
        logout();
        return 'Session expired. Please log in again.';
      } else {
        return 'Server returned error: ${res.statusCode}';
      }
    } catch (e) {
      return 'Error connecting to server: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Simulate single playoff match on backend
  Future<SimMatchResult?> simulatePlayoffMatch(String teamA, String teamB, int stageNum) async {
    final baseUrl = getBaseUrl();
    final body = {
      'teamA': teamA,
      'teamB': teamB,
      'stage': stageNum,
      'season': _selectedSeason,
      'startingXI': _startingXI.map((p) => {
        'id': p.id,
        'player': p.player,
        'battingRating': p.battingRating,
        'bowlingRating': p.bowlingRating,
        'clutchRating': p.clutchRating,
      }).toList(),
    };

    final res = await http.post(
      Uri.parse('$baseUrl/api/game/simulate-playoff-match'),
      headers: _getHeaders(),
      body: json.encode(body),
    );

    if (res.statusCode == 200) {
      return SimMatchResult.fromJson(json.decode(res.body));
    } else if (res.statusCode == 403 || res.statusCode == 401) {
      logout();
      throw Exception('Session expired. Please log in again.');
    } else {
      throw Exception('Failed to simulate match: server returned ${res.statusCode}');
    }
  }

  // Orchestrate playoff stage simulation sequentially on backend
  Future<String?> handlePlayoffs() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      if (_playoffStage == 'q1') {
        final res = await simulatePlayoffMatch(_playoffTeams[0], _playoffTeams[1], 101);
        if (res != null) {
          _playoffQ1 = res;
          _playoffStage = 'elim';
        }
      } else if (_playoffStage == 'elim') {
        final res = await simulatePlayoffMatch(_playoffTeams[2], _playoffTeams[3], 102);
        if (res != null) {
          _playoffElim = res;
          _playoffStage = 'q2';
        }
      } else if (_playoffStage == 'q2') {
        final loserQ1 = _playoffQ1!.winner == _playoffTeams[0] ? _playoffTeams[1] : _playoffTeams[0];
        final winnerElim = _playoffElim!.winner;
        final res = await simulatePlayoffMatch(loserQ1, winnerElim, 103);
        if (res != null) {
          _playoffQ2 = res;
          _playoffStage = 'final';
        }
      } else if (_playoffStage == 'final') {
        final winnerQ1 = _playoffQ1!.winner;
        final winnerQ2 = _playoffQ2!.winner;
        final res = await simulatePlayoffMatch(winnerQ1, winnerQ2, 104);
        if (res != null) {
          _playoffFinal = res;
          _playoffStage = 'complete';

          calculatePostSeasonAwards();
          _gameState = 'complete';
        }
      }
      return null;
    } catch (e) {
      return e.toString().replaceFirst('Exception: ', '');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void calculatePostSeasonAwards() {
    if (_draftedPlayers.isEmpty) return;

    // MVP: Highest Rating
    final ratings = List<PlayerSeason>.from(_draftedPlayers);
    ratings.sort((a, b) => b.overallRating.compareTo(a.overallRating));
    _mvpPlayer = ratings.first;

    // Bargain: Highest Rating / Cost
    final bargains = List<PlayerSeason>.from(_draftedPlayers);
    bargains.sort((a, b) => (b.overallRating / b.cost).compareTo(a.overallRating / a.cost));
    _bargainPlayer = bargains.first;
  }

  Future<String?> saveSeasonPerformance() async {
    if (_selectedSeason == null) return 'No season active';

    _isLoading = true;
    notifyListeners();

    final userRecord = _standings.firstWhere((s) => s.team == 'Your Moneyball XI',
        orElse: () => Standing(team: 'Your Moneyball XI'));
    final wins = userRecord.wins;
    final losses = userRecord.losses;
    
    _standings.sort((a, b) => b.points.compareTo(a.points) != 0
        ? b.points.compareTo(a.points)
        : b.wins.compareTo(a.wins));
    final finalPos = _standings.indexWhere((s) => s.team == 'Your Moneyball XI') + 1;
    final champion = _playoffFinal != null && _playoffFinal!.winner == 'Your Moneyball XI';

    final payload = {
      'seasonBeaten': _selectedSeason,
      'wins': wins,
      'losses': losses,
      'finalPosition': finalPos,
      'champion': champion,
      'mvp': _mvpPlayer != null ? '${_mvpPlayer!.player} (${_mvpPlayer!.season})' : 'None',
      'biggestBargain': _bargainPlayer != null ? '${_bargainPlayer!.player} (${_bargainPlayer!.season})' : 'None',
      'worstPick': 'None',
    };

    try {
      final baseUrl = getBaseUrl();
      final res = await http.post(
        Uri.parse('$baseUrl/api/game/save-performance'),
        headers: _getHeaders(),
        body: json.encode(payload),
      );

      if (res.statusCode == 200) {
        await _fetchInitialData();
        _gameState = 'menu';
        notifyListeners();
        return null;
      } else if (res.statusCode == 403 || res.statusCode == 401) {
        logout();
        return 'Session expired. Please log in again.';
      } else {
        return 'Server returned error: ${res.statusCode}';
      }
    } catch (e) {
      return 'Error connecting to server: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void restartToMenu() {
    _gameState = 'menu';
    notifyListeners();
  }
}
