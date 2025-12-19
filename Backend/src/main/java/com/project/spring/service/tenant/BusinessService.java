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

    @Cacheable(value = "tableCount", key = "'default'")
    public Long getTableCount() {
        return businessRepository.findTableCountByBusinessId(1L);
    }
     @CacheEvict(value = "tableCount", key = "'default'")
    public Business updateBusiness(Business business) {
        return businessRepository.save(business);
    }
}
