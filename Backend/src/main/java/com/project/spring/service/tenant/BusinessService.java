package com.project.spring.service.tenant;

import com.project.spring.config.TenantContext;
import com.project.spring.dto.BusinessDTO;
import com.project.spring.dto.DashboardDetailsDTO;
import com.project.spring.model.tenant.Business;
import com.project.spring.repo.tenant.BusinessRepository;
import com.project.spring.repo.tenant.TenantBusinessRepository;

import lombok.RequiredArgsConstructor;

import org.springframework.cache.annotation.Cacheable;
import org.springframework.cache.annotation.CacheEvict;
import org.springframework.stereotype.Service;

@Service
@RequiredArgsConstructor
public class BusinessService {

    private static final Long DEFAULT_BUSINESS_ID = 1L;

    private static final String BUSINESS_CACHE = "business";
    private static final String TABLE_COUNT_CACHE = "tableCount";

    private final TenantBusinessRepository tenantBusinessRepository;
    private final BusinessRepository businessRepository;

    /* ============================================================
       ================= DASHBOARD ================================
       ============================================================ */

    public DashboardDetailsDTO getDashboardDetails(String username, String role) {

        Business business =
                tenantBusinessRepository.findById(DEFAULT_BUSINESS_ID)
                        .orElse(null);

        String businessName = business != null ? business.getName() : "";
        String logoUrl = business != null ? business.getLogoUrl() : "";

        return new DashboardDetailsDTO(username, role, businessName, logoUrl);
    }

    /* ============================================================
       ================= GET BUSINESS (CACHED) ====================
       ============================================================ */

    @Cacheable(
            value = BUSINESS_CACHE,
            key = "T(com.project.spring.config.TenantContext).getCurrentTenant()"
    )
    public BusinessDTO getBusiness() {

        System.out.println(
                "Fetching BUSINESS from DATABASE | tenant = "
                        + TenantContext.getCurrentTenant()
        );

        return tenantBusinessRepository
                .findById(DEFAULT_BUSINESS_ID)
                .map(this::toDTO)
                .orElse(null);
    }

    /* ============================================================
       ================= SAVE / UPDATE ============================
       ============================================================ */

    @CacheEvict(value = {BUSINESS_CACHE, TABLE_COUNT_CACHE}, allEntries = true)
    public Business saveOrUpdateBusiness(Business newBusiness) {

        return tenantBusinessRepository.findById(DEFAULT_BUSINESS_ID)
                .map(existing -> {
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
                    return tenantBusinessRepository.save(existing);
                })
                .orElseGet(() -> {
                    newBusiness.setId(DEFAULT_BUSINESS_ID);
                    return tenantBusinessRepository.save(newBusiness);
                });
    }

    /* ============================================================
       ================= UPDATE LOGO ==============================
       ============================================================ */

    @CacheEvict(value = BUSINESS_CACHE, allEntries = true)
    public BusinessDTO updateLogo(String logoUrl) {

        Business business = tenantBusinessRepository
                .findById(DEFAULT_BUSINESS_ID)
                .orElseThrow(() ->
                        new IllegalStateException("Business not found"));

        business.setLogoUrl(logoUrl);

        Business saved = tenantBusinessRepository.save(business);

        return toDTO(saved);
    }

    /* ============================================================
       ================= TABLE COUNT (CACHED) =====================
       ============================================================ */

    @Cacheable(
            value = TABLE_COUNT_CACHE,
            key = "T(com.project.spring.config.TenantContext).getCurrentTenant()"
    )
    public Integer getTableCountCached() {

        System.out.println(
                "Fetching TABLE COUNT from DATABASE | tenant = "
                        + TenantContext.getCurrentTenant()
        );

        return businessRepository
                .findTableCountByBusinessId(DEFAULT_BUSINESS_ID);
    }

    public Long getTableCount() {
        Integer count = getTableCountCached();
        return count == null ? 0L : count.longValue();
    }

    /* ============================================================
       ================= DTO MAPPER ===============================
       ============================================================ */

    public BusinessDTO toDTO(Business business) {

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
