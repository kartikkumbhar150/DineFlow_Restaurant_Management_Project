package com.project.spring.controller.tenant;

import com.project.spring.dto.ApiResponse;
import com.project.spring.dto.BusinessDTO;
import com.project.spring.dto.DashboardDetailsDTO;
import com.project.spring.model.tenant.Business;
import com.project.spring.service.tenant.BusinessService;
import com.project.spring.service.tenant.CloudinaryService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.GrantedAuthority;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;

import java.io.IOException;

@RestController
@RequestMapping("/api/v1/business")
public class BusinessController {

    @Autowired
    private BusinessService businessService;

    @Autowired
    private CloudinaryService cloudinaryService;

    // ================= DASHBOARD =================
    @GetMapping("/dashboard/showMe")
    public ResponseEntity<ApiResponse<DashboardDetailsDTO>> getDashboardDetails() {

        Authentication auth = SecurityContextHolder.getContext().getAuthentication();

        String username = auth.getName();
        String role = auth.getAuthorities()
                .stream()
                .map(GrantedAuthority::getAuthority)
                .map(r -> r.replace("ROLE_", ""))
                .findFirst()
                .orElse("USER");

        DashboardDetailsDTO dto =
                businessService.getDashboardDetails(username, role);

        return ResponseEntity.ok(
                new ApiResponse<>("success", "Dashboard details fetched successfully", dto)
        );
    }

    // ================= GET BUSINESS =================
    @GetMapping
    public ResponseEntity<ApiResponse<BusinessDTO>> getBusiness() {

        BusinessDTO business = businessService.getBusiness();

        if (business == null) {
            return ResponseEntity.status(404)
                    .body(new ApiResponse<>("failure", "Business not found", null));
        }

        return ResponseEntity.ok(
                new ApiResponse<>("success", "Business found", business)
        );
    }

    // ================= CREATE / UPDATE =================
    @PostMapping
    @PreAuthorize("hasAnyRole('ADMIN', 'STAFF', 'CHEF')")
    public ResponseEntity<ApiResponse<BusinessDTO>> saveBusiness(
            @RequestBody Business newBusiness) {

        Business saved = businessService.saveOrUpdateBusiness(newBusiness);

        return ResponseEntity.ok(
                new ApiResponse<>("success", "Business saved successfully",
                        businessService.toDTO(saved))
        );
    }

    // ================= UPDATE =================
    @PutMapping
    @PreAuthorize("hasAnyRole('ADMIN', 'STAFF')")
    public ResponseEntity<ApiResponse<BusinessDTO>> updateBusiness(
            @RequestBody Business updatedBusiness) {

        Business saved = businessService.saveOrUpdateBusiness(updatedBusiness);

        return ResponseEntity.ok(
                new ApiResponse<>("success", "Business updated successfully",
                        businessService.toDTO(saved))
        );
    }

    // ================= UPDATE LOGO =================
    @PutMapping(value = "/logo", consumes = "multipart/form-data")
    @PreAuthorize("hasRole('ADMIN')")
    public ResponseEntity<ApiResponse<BusinessDTO>> updateLogo(
            @RequestParam("file") MultipartFile file) throws IOException {

        String logoUrl = cloudinaryService.uploadFile(file);
        BusinessDTO updatedBusiness = businessService.updateLogo(logoUrl);

        return ResponseEntity.ok(
            new ApiResponse<>(
                    "success",
                    "Business logo updated successfully",
                    updatedBusiness
            )
    );
    }
}
