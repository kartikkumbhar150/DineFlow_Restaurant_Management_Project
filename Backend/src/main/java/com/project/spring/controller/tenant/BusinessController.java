package com.project.spring.controller.tenant;

import com.project.spring.dto.ApiResponse;
import com.project.spring.dto.BusinessDTO;
import com.project.spring.dto.DashboardDetailsDTO;
import com.project.spring.model.tenant.Business;
import com.project.spring.repo.tenant.TenantBusinessRepository;
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

    private static final Long DEFAULT_BUSINESS_ID = 1L;

    @Autowired
    private TenantBusinessRepository businessRepository;

    @Autowired
    private CloudinaryService cloudinaryService;

    @Autowired
    private BusinessService businessService;


    @GetMapping("/dashboard/showMe")

public ResponseEntity<ApiResponse<DashboardDetailsDTO>> getDashboardDetails() {
    try {
        Authentication authentication = SecurityContextHolder.getContext().getAuthentication();

        String username = authentication.getName();
        String role = authentication.getAuthorities()
                .stream()
                .map(GrantedAuthority::getAuthority)
                .map(r -> r.replace("ROLE_", ""))
                .findFirst()
                .orElse("USER");

        // Fetch business (may be null)
        Business business = businessRepository.findById(DEFAULT_BUSINESS_ID).orElse(null);

        // If business not found → return empty values
        String businessName = (business != null) ? business.getName() : "";
        String logoUrl = (business != null) ? business.getLogoUrl() : "";

        DashboardDetailsDTO dto = new DashboardDetailsDTO(username, role, businessName, logoUrl);

        return ResponseEntity.ok(
                new ApiResponse<>("success", "Dashboard details fetched successfully", dto)
        );

    } catch (Exception e) {
        return ResponseEntity.status(500).body(
                new ApiResponse<>("failure", "Error fetching dashboard details: " + e.getMessage(), null)
        );
    }
}


    // === Update default business logo ===
    @PutMapping(value = "/logo", consumes = {"multipart/form-data"})
    public ResponseEntity<ApiResponse<BusinessDTO>> updateBusinessLogo(
            @RequestParam("file") MultipartFile file) {
        try {
            return businessRepository.findById(DEFAULT_BUSINESS_ID).<ResponseEntity<ApiResponse<BusinessDTO>>>map(existing -> {
                try {
                    String logoUrl = cloudinaryService.uploadFile(file);
                    existing.setLogoUrl(logoUrl);
                    Business saved = businessService.updateBusiness(existing);

                    return ResponseEntity.ok(
                            new ApiResponse<>("success", "Business logo updated successfully", mapToDTO(saved))
                    );
                } catch (IOException e) {
                    return ResponseEntity.status(500).body(
                            new ApiResponse<>("failure", "Error uploading logo: " + e.getMessage(), null));
                }
            }).orElse(ResponseEntity.status(404).body(
                    new ApiResponse<>("failure", "Default business not found", null)));
        } catch (Exception e) {
            return ResponseEntity.status(500).body(
                    new ApiResponse<>("failure", "Error updating logo: " + e.getMessage(), null));
        }
    }

    // === Get default business ===
    @GetMapping
    public ResponseEntity<ApiResponse<BusinessDTO>> getBusiness() {
        try {
            return businessRepository.findById(DEFAULT_BUSINESS_ID)
                    .map(business -> ResponseEntity.ok(
                            new ApiResponse<>("success", "Business found", mapToDTO(business))))
                    .orElse(ResponseEntity.status(404).body(
                            new ApiResponse<>("failure", "Business not found", null)));
        } catch (Exception e) {
            return ResponseEntity.status(500).body(
                    new ApiResponse<>("failure", "Error fetching business: " + e.getMessage(), null));
        }
    }
    // === Upload a logo file only (without updating business DB) ===
@PostMapping(value = "/logo", consumes = {"multipart/form-data"})
public ResponseEntity<ApiResponse<String>> uploadBusinessLogo(
        @RequestParam("file") MultipartFile file) {
    try {
        String logoUrl = cloudinaryService.uploadFile(file);
        return ResponseEntity.ok(
                new ApiResponse<>("success", "Logo uploaded successfully", logoUrl)
        );
    } catch (IOException e) {
        return ResponseEntity.status(500).body(
                new ApiResponse<>("failure", "Error uploading logo: " + e.getMessage(), null)
        );
    }
}   
    @PostMapping
@PreAuthorize("hasAnyRole('ADMIN', 'STAFF', 'CHEF')")
public ResponseEntity<ApiResponse<BusinessDTO>> addBusiness(@RequestBody Business newBusiness) {
    try {
        // If default business already exists → update it
        return businessRepository.findById(DEFAULT_BUSINESS_ID).map(existing -> {
            existing.setName(newBusiness.getName());
            existing.setGstNumber(newBusiness.getGstNumber());
            existing.setAddress(newBusiness.getAddress());
            existing.setLogoUrl(newBusiness.getLogoUrl());
            existing.setFssaiNo(newBusiness.getFssaiNo());
            existing.setLicenceNo(newBusiness.getLicenceNo());
            existing.setGstType(newBusiness.getGstType());
            existing.setPhoneNo(newBusiness.getPhoneNo());
            existing.setEmail(newBusiness.getEmail());
            existing.setTableCount(newBusiness.getTableCount());

            Business saved = businessService.updateBusiness(existing);
;
            return ResponseEntity.ok(
                    new ApiResponse<>("success", "Business updated successfully", mapToDTO(saved))
            );
        }).orElseGet(() -> {
            // If no default business exists → create a new one
            newBusiness.setId(DEFAULT_BUSINESS_ID); // ensure ID = default business ID
            Business saved = businessRepository.save(newBusiness);
            return ResponseEntity.ok(
                    new ApiResponse<>("success", "Business created successfully", mapToDTO(saved))
            );
        });
    } catch (Exception e) {
        return ResponseEntity.status(500).body(
                new ApiResponse<>("failure", "Error adding/updating business: " + e.getMessage(), null)
        );
    }
}


    // === Update default business ===
    @PutMapping
    public ResponseEntity<ApiResponse<BusinessDTO>> updateBusiness(@RequestBody Business updatedBusiness) {
        try {
            return businessRepository.findById(DEFAULT_BUSINESS_ID).map(existing -> {
                existing.setName(updatedBusiness.getName());
                existing.setGstNumber(updatedBusiness.getGstNumber());
                existing.setAddress(updatedBusiness.getAddress());
                existing.setLogoUrl(updatedBusiness.getLogoUrl());
                existing.setFssaiNo(updatedBusiness.getFssaiNo());
                existing.setLicenceNo(updatedBusiness.getLicenceNo());
                existing.setGstType(updatedBusiness.getGstType());
                existing.setPhoneNo(updatedBusiness.getPhoneNo());
                existing.setEmail(updatedBusiness.getEmail());
                existing.setTableCount(updatedBusiness.getTableCount());

                Business saved = businessService.updateBusiness(existing);
;
                return ResponseEntity.ok(
                        new ApiResponse<>("success", "Business updated successfully", mapToDTO(saved)));
            }).orElse(ResponseEntity.status(404).body(
                    new ApiResponse<>("failure", "Business not found", null)));
        } catch (Exception e) {
            return ResponseEntity.status(500).body(
                    new ApiResponse<>("failure", "Error updating business: " + e.getMessage(), null));
        }
    }

    // Mapper
    private BusinessDTO mapToDTO(Business business) {
        BusinessDTO dto = new BusinessDTO();
        dto.setId(business.getId());
        dto.setName(business.getName());
        dto.setGstNumber(business.getGstNumber());
        dto.setAddress(business.getAddress());
        dto.setLogoUrl(business.getLogoUrl());
        dto.setFssaiNo(business.getFssaiNo());
        dto.setLicenceNo(business.getLicenceNo());
        dto.setGstType(business.getGstType());
        dto.setPhoneNo(business.getPhoneNo());
        dto.setEmail(business.getEmail());
        dto.setTableCount(business.getTableCount());
        return dto;
    }
}
