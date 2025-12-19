package com.project.spring.service.tenant;

import java.util.ArrayList;
import java.util.HashSet;
import java.util.List;
import java.util.Set;

import org.springframework.stereotype.Service;

import com.project.spring.dto.TableStatusResponse;
import com.project.spring.repo.tenant.BusinessRepository;
import com.project.spring.repo.tenant.OrderRepository;
import com.project.spring.service.tenant.BusinessService;

import lombok.RequiredArgsConstructor;

@Service
@RequiredArgsConstructor
public class TableStatusService {

    private final OrderRepository orderRepository;
    private final BusinessRepository businessRepository;
    private final BusinessService businessService;

    /**
     * Check if a table is currently occupied
     */
    public boolean isTableOccupied(Long tableNumber) {
        return orderRepository.existsByTableNumberAndIsCompletedFalse(tableNumber);
    }

    /**
     * Get status for all tables
     */
    public List<TableStatusResponse> getAllTableStatus() {

    Long tableCount = businessService.getTableCount();
    if (tableCount == null || tableCount <= 0) {
        return List.of();
    }

    List<Long> occupiedTables = orderRepository.findAllOccupiedTableNumbers();
    Set<Long> occupiedSet = new HashSet<>(occupiedTables);

    List<TableStatusResponse> tableStatusList = new ArrayList<>();

    for (long i = 1; i <= tableCount; i++) {
        tableStatusList.add(
            new TableStatusResponse(i, occupiedSet.contains(i))
        );
    }

    return tableStatusList;
}

}
