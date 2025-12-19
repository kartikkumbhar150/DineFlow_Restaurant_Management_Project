package com.project.spring.dto;

import lombok.Data;

@Data
public class TableStatusRequest {
    private long tableNumber;
    private boolean isOccupied;
}
