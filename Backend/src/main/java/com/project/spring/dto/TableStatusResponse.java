package com.project.spring.dto;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@NoArgsConstructor   // 
@AllArgsConstructor
public class TableStatusResponse {
    
    private long tableNumber;
    private boolean isOccupied;
}
