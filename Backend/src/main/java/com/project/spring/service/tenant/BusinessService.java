package com.project.spring.service.tenant;

import org.springframework.stereotype.Service;
import org.springframework.cache.annotation.CacheEvict;
import org.springframework.cache.annotation.Cacheable;
import lombok.RequiredArgsConstructor;

import com.project.spring.model.tenant.Business;
import com.project.spring.repo.tenant.BusinessRepository;

@Service
@RequiredArgsConstructor
public class BusinessService {

    private final BusinessRepository businessRepository;

    //  CACHE RAW INTEGER ONLY
    @Cacheable(value = "tableCount", key = "'default'")
    public Integer getTableCountCached() {
        return businessRepository.findTableCountByBusinessId(1L);
    }

    // PUBLIC SAFE METHOD
    public Long getTableCount() {
        Integer count = getTableCountCached();
        return count == null ? 0L : count.longValue();
    }

    // EVICT CACHE ON UPDATE
    @CacheEvict(value = "tableCount", key = "'default'")
    public Business updateBusiness(Business business) {
        return businessRepository.save(business);
    }
}
