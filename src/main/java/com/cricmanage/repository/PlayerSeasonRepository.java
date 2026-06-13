package com.cricmanage.repository;

import com.cricmanage.model.PlayerSeason;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;
import java.util.List;

@Repository
public interface PlayerSeasonRepository extends JpaRepository<PlayerSeason, Long> {
    List<PlayerSeason> findByTeamAndSeason(String team, Integer season);
    List<PlayerSeason> findBySeason(Integer season);
}
