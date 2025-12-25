package com.project.spring.service.tenant;

import java.util.ArrayList;
import java.util.HashSet;
import java.util.List;
import java.util.Set;

import org.springframework.cache.annotation.Cacheable;
import org.springframework.stereotype.Service;

import com.project.spring.dto.TableStatusResponse;
import com.project.spring.repo.tenant.OrderRepository;

import lombok.RequiredArgsConstructor;

@Service
@RequiredArgsConstructor
public class TableStatusService {

    private final OrderRepository orderRepository;
    private final BusinessService businessService;

    /**
     * Get status for all tables (Redis cached — short TTL suggested)
     */
    @Cacheable(value = "tableStatus", key = "'default'", sync = true)
    public List<TableStatusResponse> getAllTableStatus() {

        Long tableCount = businessService.getTableCount();
        if (tableCount == null || tableCount <= 0) return List.of();

        // convert once — avoid stream boxing/unboxing
        List<Long> occupiedTables = orderRepository.findAllOccupiedTableNumbers();
        Set<Long> occupiedSet = new HashSet<>(occupiedTables);

        List<TableStatusResponse> result = new ArrayList<>();
        for (long i = 1; i <= tableCount; i++) {
            result.add(new TableStatusResponse(i, occupiedSet.contains(i)));
        }

        return result;
    }

    /**
     * Single table status derived from cached list
     */
    public boolean isTableOccupiedFromCache(long tableNumber) {
        return getAllTableStatus()
                .stream()
                .anyMatch(t -> t.getTableNumber() == tableNumber && t.isOccupied());
    }
}
