package com.cricmanage.model;

import jakarta.persistence.*;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;
import java.time.LocalDateTime;

@Entity
@Table(name = "game_performances")
@Data
@NoArgsConstructor
@AllArgsConstructor
public class GamePerformance {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    private String username;
    
    @Column(name = "season_beaten")
    private Integer seasonBeaten;
    
    private Integer wins;
    private Integer losses;
    
    @Column(name = "final_position")
    private Integer finalPosition;
    
    private Boolean champion;
    private String mvp;
    
    @Column(name = "biggest_bargain")
    private String biggestBargain;
    
    @Column(name = "worst_pick")
    private String worstPick;
    
    private LocalDateTime timestamp = LocalDateTime.now();
}
