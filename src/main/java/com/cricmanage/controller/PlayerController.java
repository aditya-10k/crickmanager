package com.cricmanage.controller;

import com.cricmanage.model.HistoricalSquad;
import com.cricmanage.model.PlayerSeason;
import com.cricmanage.repository.HistoricalSquadRepository;
import com.cricmanage.repository.PlayerSeasonRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.stream.Collectors;

@RestController
@RequestMapping("/api/players")
public class PlayerController {

    @Autowired
    private PlayerSeasonRepository playerSeasonRepository;

    @Autowired
    private HistoricalSquadRepository historicalSquadRepository;

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
