package com.project.spring.controller.tenant;

import com.project.spring.dto.ApiResponse;
import com.project.spring.dto.StaffDTO;
import com.project.spring.service.tenant.StaffService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/v1/staff")
@RequiredArgsConstructor
public class StaffUserController {

    private final StaffService staffService;

    @PostMapping
    public ResponseEntity<ApiResponse<StaffDTO>> createStaff(@RequestBody StaffDTO dto) {
        try {
            StaffDTO createdStaff = staffService.createStaff(dto);
            return ResponseEntity.ok(new ApiResponse<>("success", "Staff created successfully", createdStaff));
        } catch (Exception e) {
            return ResponseEntity.badRequest().body(new ApiResponse<>("failure", e.getMessage(), null));
        }
    }

    @GetMapping
    public ResponseEntity<ApiResponse<List<StaffDTO>>> getAllStaff() {
        try {
            List<StaffDTO> staffList = staffService.getAllStaff();
            return ResponseEntity.ok(new ApiResponse<>("success", "Fetched all staff", staffList));
        } catch (Exception e) {
            return ResponseEntity.badRequest().body(new ApiResponse<>("failure", e.getMessage(), null));
        }
    }

    @GetMapping("/{id}")
    public ResponseEntity<ApiResponse<StaffDTO>> getStaffById(@PathVariable Long id) {
        try {
            StaffDTO staff = staffService.getStaffById(id);
            return ResponseEntity.ok(new ApiResponse<>("success", "Staff found", staff));
        } catch (RuntimeException e) {
            return ResponseEntity.status(404).body(new ApiResponse<>("failure", e.getMessage(), null));
        }
    }


    @DeleteMapping("/{id}")
    public ResponseEntity<ApiResponse<Void>> deleteStaff(@PathVariable Long id) {
        try {
            staffService.deleteStaff(id);
            return ResponseEntity.ok(new ApiResponse<>("success", "Staff deleted successfully", null));
        } catch (Exception e) {
            return ResponseEntity.badRequest().body(new ApiResponse<>("failure", e.getMessage(), null));
        }
    }
}
