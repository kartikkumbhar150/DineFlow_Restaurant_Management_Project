package com.project.spring.controller.tenant;

import com.project.spring.dto.ApiResponse;
import com.project.spring.dto.TableStatusResponse;
import com.project.spring.service.tenant.TableStatusService;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/v1/table-status")
public class TableStatusController {

    @Autowired
    private TableStatusService tableStatusService;

    /**
     * GET single table status (Redis-backed)
     */
    @GetMapping("/{tableNumber}")
    public ResponseEntity<TableStatusResponse> getTableStatus(@PathVariable long tableNumber) {

        boolean occupied = tableStatusService.isTableOccupiedFromCache(tableNumber);
        return ResponseEntity.ok(new TableStatusResponse(tableNumber, occupied));
    }

    /**
     * GET all table statuses (Redis-backed)
     */
    @GetMapping
    public ResponseEntity<ApiResponse<List<TableStatusResponse>>> getAllTableStatus() {

        List<TableStatusResponse> tableStatus = tableStatusService.getAllTableStatus();
        return ResponseEntity.ok(
                new ApiResponse<>("success", "Fetched all table-status", tableStatus)
        );
    }
}
