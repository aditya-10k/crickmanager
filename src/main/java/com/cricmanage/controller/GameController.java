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
}
