package com.cricmanage.config;

import com.cricmanage.model.HistoricalSquad;
import com.cricmanage.model.PlayerSeason;
import com.cricmanage.repository.HistoricalSquadRepository;
import com.cricmanage.repository.PlayerSeasonRepository;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.boot.CommandLineRunner;
import org.springframework.stereotype.Component;

import java.io.BufferedReader;
import java.io.File;
import java.io.FileReader;
import java.util.ArrayList;
import java.util.List;

@Component
public class DatabaseInitializer implements CommandLineRunner {

    private static final Logger logger = LoggerFactory.getLogger(DatabaseInitializer.class);

    @Autowired
    private PlayerSeasonRepository playerSeasonRepository;

    @Autowired
    private HistoricalSquadRepository historicalSquadRepository;

    @Value("${cricmanager.data.players-csv}")
    private String playersCsvPath;

    @Value("${cricmanager.data.squads-csv}")
    private String squadsCsvPath;

    @Override
    public void run(String... args) throws Exception {
        initializePlayers(false);
        initializeSquads(false);
    }

    public void forceReseed() {
        logger.info("Forced database re-seed requested. Deleting existing records...");
        long start = System.currentTimeMillis();
        playerSeasonRepository.deleteAllInBatch();
        historicalSquadRepository.deleteAllInBatch();
        logger.info("Deleted all records in " + (System.currentTimeMillis() - start) + " ms.");
        
        initializePlayers(true);
        initializeSquads(true);
    }

    private void initializePlayers(boolean force) {
        if (!force && playerSeasonRepository.count() > 0) {
            logger.info("Player season data already initialized in DB.");
            return;
        }

        File file = new File(playersCsvPath);
        if (!file.exists()) {
            file = new File("Output/player_season_values.csv");
            if (!file.exists()) {
                logger.error("Players CSV file not found at " + playersCsvPath + " or local fallback.");
                return;
            }
        }

        logger.info("Importing player season data from " + file.getAbsolutePath() + "...");
        long start = System.currentTimeMillis();
        List<PlayerSeason> list = new ArrayList<>();
        try (BufferedReader br = new BufferedReader(new FileReader(file))) {
            String line;
            br.readLine(); // skip header
            
            while ((line = br.readLine()) != null) {
                String[] parts = line.split(",", -1);
                if (parts.length < 21) continue;
                
                PlayerSeason ps = new PlayerSeason();
                ps.setPlayer(parts[0]);
                ps.setSeason(Integer.parseInt(parts[1]));
                ps.setTeam(parts[2]);
                ps.setRole(parts[3]);
                ps.setInferredNationality(parts[4]);
                ps.setBattingStyle(parts[5]);
                ps.setBowlingStyle(parts[6]);
                ps.setIsWicketkeeperCareer(Integer.parseInt(parts[7]));
                ps.setRunsScored(Integer.parseInt(parts[8]));
                ps.setWicketsTaken(Integer.parseInt(parts[9]));
                ps.setBallsFaced(Integer.parseInt(parts[10]));
                ps.setBallsBowled(Integer.parseInt(parts[11]));
                ps.setBattingRating(Double.parseDouble(parts[12]));
                ps.setBowlingRating(Double.parseDouble(parts[13]));
                ps.setPpBatRating(Double.parseDouble(parts[14]));
                ps.setPpBowlRating(Double.parseDouble(parts[15]));
                ps.setDeathBatRating(Double.parseDouble(parts[16]));
                ps.setDeathBowlRating(Double.parseDouble(parts[17]));
                ps.setClutchRating(Double.parseDouble(parts[18]));
                ps.setOverallRating(Double.parseDouble(parts[19]));
                ps.setCost(Double.parseDouble(parts[20]));
                
                list.add(ps);
            }
            playerSeasonRepository.saveAll(list);
            logger.info("Successfully imported " + list.size() + " player season cards into database in " + (System.currentTimeMillis() - start) + " ms.");
        } catch (Exception e) {
            logger.error("Error reading players CSV file: " + e.getMessage(), e);
        }
    }

    private void initializeSquads(boolean force) {
        if (!force && historicalSquadRepository.count() > 0) {
            logger.info("Historical squad data already initialized in DB.");
            return;
        }

        File file = new File(squadsCsvPath);
        if (!file.exists()) {
            file = new File("Output/historical_squad_values.csv");
            if (!file.exists()) {
                logger.error("Squads CSV file not found at " + squadsCsvPath + " or local fallback.");
                return;
            }
        }

        logger.info("Importing historical squad data from " + file.getAbsolutePath() + "...");
        long start = System.currentTimeMillis();
        List<HistoricalSquad> list = new ArrayList<>();
        try (BufferedReader br = new BufferedReader(new FileReader(file))) {
            String line;
            br.readLine(); // skip header
            
            while ((line = br.readLine()) != null) {
                String[] parts = line.split(",", -1);
                if (parts.length < 7) continue;
                
                HistoricalSquad hs = new HistoricalSquad();
                hs.setTeam(parts[0]);
                hs.setSeason(Integer.parseInt(parts[1]));
                hs.setSquadSize(Integer.parseInt(parts[2]));
                hs.setBattingStrength(Double.parseDouble(parts[3]));
                hs.setBowlingStrength(Double.parseDouble(parts[4]));
                hs.setClutchStrength(Double.parseDouble(parts[5]));
                hs.setOverallStrength(Double.parseDouble(parts[6]));
                
                list.add(hs);
            }
            historicalSquadRepository.saveAll(list);
            logger.info("Successfully imported " + list.size() + " historical squads into database in " + (System.currentTimeMillis() - start) + " ms.");
        } catch (Exception e) {
            logger.error("Error reading squads CSV file: " + e.getMessage(), e);
        }
    }
}
