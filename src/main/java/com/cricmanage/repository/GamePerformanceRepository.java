package com.cricmanage.repository;

import com.cricmanage.model.GamePerformance;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;
import java.util.List;

@Repository
public interface GamePerformanceRepository extends JpaRepository<GamePerformance, Long> {
    List<GamePerformance> findByUsernameOrderByTimestampDesc(String username);
}
