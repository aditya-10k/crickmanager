package com.cricmanage.controller;

import com.cricmanage.model.GamePerformance;
import com.cricmanage.model.HistoricalSquad;
import com.cricmanage.repository.GamePerformanceRepository;
import com.cricmanage.repository.HistoricalSquadRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.security.Principal;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.Random;

@RestController
@RequestMapping("/api/game")
public class GameController {

    @Autowired
    private GamePerformanceRepository gamePerformanceRepository;

    @Autowired
    private HistoricalSquadRepository historicalSquadRepository;

    private final Random random = new Random();

    @GetMapping("/history/{username}")
    public List<GamePerformance> getUserHistory(@PathVariable String username) {
        return gamePerformanceRepository.findByUsernameOrderByTimestampDesc(username);
    }

    @PostMapping("/save-performance")
    public ResponseEntity<GamePerformance> savePerformance(@RequestBody GamePerformance performance, Principal principal) {
        // Enforce setting the username from the authenticated user principal
        performance.setUsername(principal.getName());
        GamePerformance saved = gamePerformanceRepository.save(performance);
        return ResponseEntity.ok(saved);
    }

    @GetMapping("/leaderboard")
    public List<Map<String, Object>> getLeaderboard() {
        List<GamePerformance> allPerf = gamePerformanceRepository.findAll();
        Map<String, Map<String, Object>> aggregated = new HashMap<>();

        for (GamePerformance p : allPerf) {
            String user = p.getUsername();
            if (user == null) continue;
            
            Map<String, Object> stats = aggregated.computeIfAbsent(user, k -> {
                Map<String, Object> map = new HashMap<>();
                map.put("username", user);
                map.put("campaigns", 0L);
                map.put("wins", 0L);
                map.put("losses", 0L);
                map.put("championships", 0L);
                return map;
            });
            stats.put("campaigns", (Long) stats.get("campaigns") + 1);
            stats.put("wins", (Long) stats.get("wins") + (p.getWins() != null ? p.getWins() : 0));
            stats.put("losses", (Long) stats.get("losses") + (p.getLosses() != null ? p.getLosses() : 0));
            if (p.getChampion() != null && p.getChampion()) {
                stats.put("championships", (Long) stats.get("championships") + 1);
            }
        }

        List<Map<String, Object>> list = new ArrayList<>(aggregated.values());
        for (Map<String, Object> stats : list) {
            long wins = (Long) stats.get("wins");
            long losses = (Long) stats.get("losses");
            long total = wins + losses;
            double winRatio = total > 0 ? (double) wins / total * 100.0 : 0.0;
            stats.put("winRatio", Math.round(winRatio * 10.0) / 10.0);
        }

        // Sort by championships desc, then winRatio desc, then campaigns desc
        list.sort((a, b) -> {
            int cmp = Long.compare((Long) b.get("championships"), (Long) a.get("championships"));
            if (cmp != 0) return cmp;
            cmp = Double.compare((Double) b.get("winRatio"), (Double) a.get("winRatio"));
            if (cmp != 0) return cmp;
            return Long.compare((Long) b.get("campaigns"), (Long) a.get("campaigns"));
        });

        return list;
    }

    @PostMapping("/simulate-match")
    public ResponseEntity<?> simulateMatch(@RequestBody Map<String, Object> request) {
        Double userBat = Double.parseDouble(request.get("userBattingStrength").toString());
        Double userBowl = Double.parseDouble(request.get("userBowlingStrength").toString());
        Double userClutch = Double.parseDouble(request.get("userClutchStrength").toString());
        
        String oppTeam = request.get("opponentTeam").toString();
        Integer oppSeason = Integer.parseInt(request.get("opponentSeason").toString());

        // Find opponent squad in database
        List<HistoricalSquad> squads = historicalSquadRepository.findBySeason(oppSeason);
        HistoricalSquad oppSquad = squads.stream()
                .filter(s -> s.getTeam().equalsIgnoreCase(oppTeam))
                .findFirst()
                .orElse(null);

        double oppBat = 75.0;
        double oppBowl = 75.0;
        double oppClutch = 75.0;

        if (oppSquad != null) {
            oppBat = oppSquad.getBattingStrength();
            oppBowl = oppSquad.getBowlingStrength();
            oppClutch = oppSquad.getClutchStrength();
        }

        // Expected Runs calculation
        double userExpectedRuns = 160.0 + (userBat - oppBowl) * 1.8 + (userClutch - 75.0) * 0.4;
        double oppExpectedRuns = 160.0 + (oppBat - userBowl) * 1.8 + (oppClutch - 75.0) * 0.4;

        // Apply normal distribution noise (sigma = 12)
        int userFinalScore = (int) Math.round(userExpectedRuns + random.nextGaussian() * 12.0);
        int oppFinalScore = (int) Math.round(oppExpectedRuns + random.nextGaussian() * 12.0);

        // Cap lower score bound at 50 runs (highly unlikely to score less in professional T20)
        userFinalScore = Math.max(50, userFinalScore);
        oppFinalScore = Math.max(50, oppFinalScore);

        // Wickets calculation
        double userExpectedWickets = 5.0 + (oppBowl - userBat) * 0.15 + random.nextGaussian() * 1.5;
        double oppExpectedWickets = 5.0 + (userBowl - oppBat) * 0.15 + random.nextGaussian() * 1.5;

        int userWickets = (int) Math.round(userExpectedWickets);
        int oppWickets = (int) Math.round(oppExpectedWickets);

        // Wickets bounds [0, 10]
        userWickets = Math.min(10, Math.max(0, userWickets));
        oppWickets = Math.min(10, Math.max(0, oppWickets));

        // If score equals, declare tie breaking using random (super over style)
        if (userFinalScore == oppFinalScore) {
            if (random.nextBoolean()) {
                userFinalScore += 1;
            } else {
                oppFinalScore += 1;
            }
        }

        String winner = userFinalScore > oppFinalScore ? "User" : "Opponent";

        Map<String, Object> result = new HashMap<>();
        result.put("userScore", userFinalScore);
        result.put("userWickets", userWickets);
        result.put("opponentScore", oppFinalScore);
        result.put("opponentWickets", oppWickets);
        result.put("winner", winner);
        result.put("opponentTeamName", oppTeam);

        return ResponseEntity.ok(result);
    }

    private static final double DIFFICULTY_MODIFIER = 5.0;

    private List<Map<String, String>> getFixturesForRound(int r, List<String> allTeams) {
        int numTeams = allTeams.size();
        List<String> list = new ArrayList<>(allTeams);
        List<Map<String, String>> fixtures = new ArrayList<>();

        for (int currentRound = 0; currentRound < r; currentRound++) {
            if (currentRound == r - 1) {
                for (int i = 0; i < numTeams / 2; i++) {
                    String home = list.get(i);
                    String away = list.get(numTeams - 1 - i);
                    if (r - 1 < numTeams - 1) {
                        if ((r - 1) % 2 == 0) {
                            Map<String, String> m = new HashMap<>();
                            m.put("home", home);
                            m.put("away", away);
                            fixtures.add(m);
                        } else {
                            Map<String, String> m = new HashMap<>();
                            m.put("home", away);
                            m.put("away", home);
                            fixtures.add(m);
                        }
                    } else {
                        if ((r - 1) % 2 == 0) {
                            Map<String, String> m = new HashMap<>();
                            m.put("home", away);
                            m.put("away", home);
                            fixtures.add(m);
                        } else {
                            Map<String, String> m = new HashMap<>();
                            m.put("home", home);
                            m.put("away", away);
                            fixtures.add(m);
                        }
                    }
                }
            }
            String temp = list.remove(list.size() - 1);
            list.add(1, temp);
        }
        return fixtures;
    }

    private Map<String, Object> simulateSingleMatch(String home, String away,
                                                    double batH, double bowlH, double clutchH,
                                                    double batA, double bowlA, double clutchA) {
        // Expected Runs calculation
        double expH = 160.0 + (batH - bowlA) * 1.8 + (clutchH - 75.0) * 0.4;
        double expA = 160.0 + (batA - bowlH) * 1.8 + (clutchA - 75.0) * 0.4;

        // Apply difficulty modifier if user is involved
        if (home.equals("Your Moneyball XI")) {
            expH -= DIFFICULTY_MODIFIER;
            expA += DIFFICULTY_MODIFIER;
        } else if (away.equals("Your Moneyball XI")) {
            expA -= DIFFICULTY_MODIFIER;
            expH += DIFFICULTY_MODIFIER;
        }

        // Apply normal distribution noise (sigma = 12)
        int scoreH = (int) Math.round(expH + random.nextGaussian() * 12.0);
        int scoreA = (int) Math.round(expA + random.nextGaussian() * 12.0);

        // Cap lower score bound at 50 runs
        scoreH = Math.max(50, scoreH);
        scoreA = Math.max(50, scoreA);

        // Wickets calculation
        double wicketsExpH = 5.0 + (bowlA - batH) * 0.15 + random.nextGaussian() * 1.5;
        double wicketsExpA = 5.0 + (bowlH - batA) * 0.15 + random.nextGaussian() * 1.5;

        int wicketsH = (int) Math.round(wicketsExpH);
        int wicketsA = (int) Math.round(wicketsExpA);

        // Wickets bounds [0, 10]
        wicketsH = Math.min(10, Math.max(0, wicketsH));
        wicketsA = Math.min(10, Math.max(0, wicketsA));

        // Tie breaker
        if (scoreH == scoreA) {
            if (random.nextBoolean()) {
                scoreH += 1;
            } else {
                scoreA += 1;
            }
        }

        String winner = scoreH > scoreA ? home : away;

        Map<String, Object> res = new HashMap<>();
        res.put("homeTeam", home);
        res.put("awayTeam", away);
        res.put("homeScore", scoreH);
        res.put("homeWickets", wicketsH);
        res.put("awayScore", scoreA);
        res.put("awayWickets", wicketsA);
        res.put("winner", winner);

        return res;
    }

    @PostMapping("/simulate-group-stage")
    public ResponseEntity<?> simulateGroupStage(@RequestBody Map<String, Object> request) {
        Integer season = Integer.parseInt(request.get("season").toString());
        String replacedTeam = request.get("replacedTeam").toString();
        List<String> opponents = (List<String>) request.get("opponents");
        List<Map<String, Object>> startingXI = (List<Map<String, Object>>) request.get("startingXI");

        // 1. Compute User strengths
        List<Double> batRatings = new ArrayList<>();
        List<Double> bowlRatings = new ArrayList<>();
        double totalClutch = 0.0;

        for (Map<String, Object> player : startingXI) {
            double bat = Double.parseDouble(player.get("battingRating").toString());
            double bowl = Double.parseDouble(player.get("bowlingRating").toString());
            double clutch = Double.parseDouble(player.get("clutchRating").toString());

            batRatings.add(bat);
            bowlRatings.add(bowl);
            totalClutch += clutch;
        }

        batRatings.sort(java.util.Collections.reverseOrder());
        double userBat = 0.0;
        for (int i = 0; i < Math.min(7, batRatings.size()); i++) {
            userBat += batRatings.get(i);
        }
        userBat = userBat / Math.max(1, Math.min(7, batRatings.size()));

        bowlRatings.sort(java.util.Collections.reverseOrder());
        double userBowl = 0.0;
        for (int i = 0; i < Math.min(5, bowlRatings.size()); i++) {
            userBowl += bowlRatings.get(i);
        }
        userBowl = userBowl / Math.max(1, Math.min(5, bowlRatings.size()));

        double userClutch = totalClutch / Math.max(1, startingXI.size());

        // 2. Fetch opponent strengths from DB
        List<HistoricalSquad> squads = historicalSquadRepository.findBySeason(season);
        Map<String, HistoricalSquad> squadMap = new HashMap<>();
        for (HistoricalSquad s : squads) {
            squadMap.put(s.getTeam().toLowerCase(), s);
        }

        // 3. Set up schedule
        String userTeamName = "Your Moneyball XI";
        List<String> allTeams = new ArrayList<>();
        allTeams.add(userTeamName);
        allTeams.addAll(opponents);

        int numTeams = allTeams.size();
        int totalRounds = (numTeams - 1) * 2;

        List<Map<String, Object>> fixtures = new ArrayList<>();
        Map<String, Map<String, Object>> standingsMap = new HashMap<>();

        for (String team : allTeams) {
            Map<String, Object> st = new HashMap<>();
            st.put("team", team);
            st.put("played", 0);
            st.put("wins", 0);
            st.put("losses", 0);
            st.put("points", 0);
            standingsMap.put(team, st);
        }

        // 4. Simulate rounds
        for (int r = 1; r <= totalRounds; r++) {
            List<Map<String, String>> roundFixtures = getFixturesForRound(r, allTeams);
            for (Map<String, String> f : roundFixtures) {
                String home = f.get("home");
                String away = f.get("away");

                double batH = 75.0, bowlH = 75.0, clutchH = 75.0;
                double batA = 75.0, bowlA = 75.0, clutchA = 75.0;

                if (home.equals(userTeamName)) {
                    batH = userBat;
                    bowlH = userBowl;
                    clutchH = userClutch;
                } else {
                    HistoricalSquad hs = squadMap.get(home.toLowerCase());
                    if (hs != null) {
                        batH = hs.getBattingStrength();
                        bowlH = hs.getBowlingStrength();
                        clutchH = hs.getClutchStrength();
                    }
                }

                if (away.equals(userTeamName)) {
                    batA = userBat;
                    bowlA = userBowl;
                    clutchA = userClutch;
                } else {
                    HistoricalSquad hs = squadMap.get(away.toLowerCase());
                    if (hs != null) {
                        batA = hs.getBattingStrength();
                        bowlA = hs.getBowlingStrength();
                        clutchA = hs.getClutchStrength();
                    }
                }

                Map<String, Object> result = simulateSingleMatch(home, away, batH, bowlH, clutchH, batA, bowlA, clutchA);
                result.put("round", r);
                fixtures.add(result);

                // Update standings
                Map<String, Object> stHome = standingsMap.get(home);
                Map<String, Object> stAway = standingsMap.get(away);

                stHome.put("played", (Integer) stHome.get("played") + 1);
                stAway.put("played", (Integer) stAway.get("played") + 1);

                String winner = result.get("winner").toString();
                if (winner.equals(home)) {
                    stHome.put("wins", (Integer) stHome.get("wins") + 1);
                    stHome.put("points", (Integer) stHome.get("points") + 2);
                    stAway.put("losses", (Integer) stAway.get("losses") + 1);
                } else {
                    stAway.put("wins", (Integer) stAway.get("wins") + 1);
                    stAway.put("points", (Integer) stAway.get("points") + 2);
                    stHome.put("losses", (Integer) stHome.get("losses") + 1);
                }
            }
        }

        // 5. Sort Standings (points desc, wins desc, team asc)
        List<Map<String, Object>> standingsList = new ArrayList<>(standingsMap.values());
        standingsList.sort((a, b) -> {
            int ptsCmp = Integer.compare((Integer) b.get("points"), (Integer) a.get("points"));
            if (ptsCmp != 0) return ptsCmp;
            int winsCmp = Integer.compare((Integer) b.get("wins"), (Integer) a.get("wins"));
            if (winsCmp != 0) return winsCmp;
            return ((String) a.get("team")).compareTo((String) b.get("team"));
        });

        Map<String, Object> response = new HashMap<>();
        response.put("fixtures", fixtures);
        response.put("standings", standingsList);

        return ResponseEntity.ok(response);
    }

    @PostMapping("/simulate-playoff-match")
    public ResponseEntity<?> simulatePlayoffMatch(@RequestBody Map<String, Object> request) {
        String teamA = request.get("teamA").toString();
        String teamB = request.get("teamB").toString();
        int stage = Integer.parseInt(request.get("stage").toString());
        int season = Integer.parseInt(request.get("season").toString());
        List<Map<String, Object>> startingXI = (List<Map<String, Object>>) request.get("startingXI");

        // Compute User strengths from startingXI if startingXI is provided
        double userBat = 75.0, userBowl = 75.0, userClutch = 75.0;
        if (startingXI != null && !startingXI.isEmpty()) {
            List<Double> batRatings = new ArrayList<>();
            List<Double> bowlRatings = new ArrayList<>();
            double totalClutch = 0.0;

            for (Map<String, Object> player : startingXI) {
                double bat = Double.parseDouble(player.get("battingRating").toString());
                double bowl = Double.parseDouble(player.get("bowlingRating").toString());
                double clutch = Double.parseDouble(player.get("clutchRating").toString());

                batRatings.add(bat);
                bowlRatings.add(bowl);
                totalClutch += clutch;
            }

            batRatings.sort(java.util.Collections.reverseOrder());
            userBat = 0.0;
            for (int i = 0; i < Math.min(7, batRatings.size()); i++) {
                userBat += batRatings.get(i);
            }
            userBat = userBat / Math.max(1, Math.min(7, batRatings.size()));

            bowlRatings.sort(java.util.Collections.reverseOrder());
            userBowl = 0.0;
            for (int i = 0; i < Math.min(5, bowlRatings.size()); i++) {
                userBowl += bowlRatings.get(i);
            }
            userBowl = userBowl / Math.max(1, Math.min(5, bowlRatings.size()));

            userClutch = totalClutch / Math.max(1, startingXI.size());
        }

        double batA = 75.0, bowlA = 75.0, clutchA = 75.0;
        double batB = 75.0, bowlB = 75.0, clutchB = 75.0;

        String userTeamName = "Your Moneyball XI";

        // Find squad strengths
        if (teamA.equals(userTeamName)) {
            batA = userBat;
            bowlA = userBowl;
            clutchA = userClutch;
        } else {
            HistoricalSquad hs = historicalSquadRepository.findBySeason(season).stream()
                    .filter(s -> s.getTeam().equalsIgnoreCase(teamA))
                    .findFirst().orElse(null);
            if (hs != null) {
                batA = hs.getBattingStrength();
                bowlA = hs.getBowlingStrength();
                clutchA = hs.getClutchStrength();
            }
        }

        if (teamB.equals(userTeamName)) {
            batB = userBat;
            bowlB = userBowl;
            clutchB = userClutch;
        } else {
            HistoricalSquad hs = historicalSquadRepository.findBySeason(season).stream()
                    .filter(s -> s.getTeam().equalsIgnoreCase(teamB))
                    .findFirst().orElse(null);
            if (hs != null) {
                batB = hs.getBattingStrength();
                bowlB = hs.getBowlingStrength();
                clutchB = hs.getClutchStrength();
            }
        }

        Map<String, Object> result = simulateSingleMatch(teamA, teamB, batA, bowlA, clutchA, batB, bowlB, clutchB);
        result.put("round", stage);

        return ResponseEntity.ok(result);
    }
}

