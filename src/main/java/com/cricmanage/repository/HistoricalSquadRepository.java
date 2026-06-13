package com.cricmanage.repository;

import com.cricmanage.model.HistoricalSquad;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;
import java.util.List;

@Repository
public interface HistoricalSquadRepository extends JpaRepository<HistoricalSquad, Long> {
    List<HistoricalSquad> findBySeason(Integer season);
}
