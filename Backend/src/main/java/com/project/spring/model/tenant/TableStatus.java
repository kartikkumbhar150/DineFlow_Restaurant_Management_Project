package com.project.spring.model.tenant;

import jakarta.persistence.*;
import lombok.*;

@Data
@NoArgsConstructor
@AllArgsConstructor
@Entity
@Table(name = "table_status")
public class TableStatus {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "table_number", unique = true, nullable = false)
    private long tableNumber;

    @Column(name = "is_occupied")
    private boolean isOccupied;
}
