package com.cricmanage.model;

import jakarta.persistence.*;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

@Entity
@Table(name = "player_seasons")
@Data
@NoArgsConstructor
@AllArgsConstructor
public class PlayerSeason {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    private String player;
    private Integer season;
    private String team;
    private String role;
    
    @Column(name = "inferred_nationality")
    private String inferredNationality;
    
    @Column(name = "batting_style")
    private String battingStyle;
    
    @Column(name = "bowling_style")
    private String bowlingStyle;
    
    @Column(name = "is_wicketkeeper_career")
    private Integer isWicketkeeperCareer;
    
    @Column(name = "runs_scored")
    private Integer runsScored;
    
    @Column(name = "wickets_taken")
    private Integer wicketsTaken;
    
    @Column(name = "balls_faced")
    private Integer ballsFaced;
    
    @Column(name = "balls_bowled")
    private Integer ballsBowled;
    
    @Column(name = "batting_rating")
    private Double battingRating;
    
    @Column(name = "bowling_rating")
    private Double bowlingRating;
    
    @Column(name = "pp_bat_rating")
    private Double ppBatRating;
    
    @Column(name = "pp_bowl_rating")
    private Double ppBowlRating;
    
    @Column(name = "death_bat_rating")
    private Double deathBatRating;
    
    @Column(name = "death_bowl_rating")
    private Double deathBowlRating;
    
    @Column(name = "clutch_rating")
    private Double clutchRating;
    
    @Column(name = "overall_rating")
    private Double overallRating;
    
    private Double cost;
}
