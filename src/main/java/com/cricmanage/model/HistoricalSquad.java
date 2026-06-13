package com.cricmanage.model;

import jakarta.persistence.*;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

@Entity
@Table(name = "historical_squads")
@Data
@NoArgsConstructor
@AllArgsConstructor
public class HistoricalSquad {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    private String team;
    private Integer season;
    
    @Column(name = "squad_size")
    private Integer squadSize;
    
    @Column(name = "batting_strength")
    private Double battingStrength;
    
    @Column(name = "bowling_strength")
    private Double bowlingStrength;
    
    @Column(name = "clutch_strength")
    private Double clutchStrength;
    
    @Column(name = "overall_strength")
    private Double overallStrength;
}
