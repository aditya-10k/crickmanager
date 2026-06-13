package com.cricmanage.controller;

import com.cricmanage.model.HistoricalSquad;
import com.cricmanage.model.PlayerSeason;
import com.cricmanage.repository.HistoricalSquadRepository;
import com.cricmanage.repository.PlayerSeasonRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import com.cricmanage.config.DatabaseInitializer;

import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.stream.Collectors;

@RestController
@RequestMapping("/api/players")
public class PlayerController {

    @Autowired
    private PlayerSeasonRepository playerSeasonRepository;

    @Autowired
    private HistoricalSquadRepository historicalSquadRepository;

    @Autowired
    private DatabaseInitializer databaseInitializer;

    @PostMapping("/reseed")
    public ResponseEntity<Map<String, Object>> reseed() {
        Map<String, Object> response = new HashMap<>();
        try {
            databaseInitializer.forceReseed();
            response.put("status", "success");
            response.put("message", "Database successfully re-seeded from CSVs.");
            response.put("playersCount", playerSeasonRepository.count());
            response.put("squadsCount", historicalSquadRepository.count());
            return ResponseEntity.ok(response);
        } catch (Exception e) {
            response.put("status", "error");
            response.put("message", e.getMessage());
            return ResponseEntity.status(500).body(response);
        }
    }

    @GetMapping("/seasons")
    public List<Integer> getSeasons() {
        return historicalSquadRepository.findAll().stream()
                .map(HistoricalSquad::getSeason)
                .distinct()
                .sorted()
                .collect(Collectors.toList());
    }

    @GetMapping("/squads")
    public List<HistoricalSquad> getSquads() {
        return historicalSquadRepository.findAll();
    }

    @GetMapping("/squads/by-season/{season}")
    public List<HistoricalSquad> getSquadsBySeason(@PathVariable Integer season) {
        return historicalSquadRepository.findBySeason(season);
    }

    @GetMapping("/squad/{team}/{season}")
    public List<PlayerSeason> getSquadPlayers(@PathVariable String team, @PathVariable Integer season) {
        return playerSeasonRepository.findByTeamAndSeason(team, season);
    }
}
