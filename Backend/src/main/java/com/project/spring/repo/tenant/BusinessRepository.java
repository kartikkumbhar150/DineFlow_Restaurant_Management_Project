package com.project.spring.repo.tenant;

import com.project.spring.model.tenant.Business;


import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.stereotype.Repository;

@Repository
public interface BusinessRepository extends JpaRepository<Business, Long> {
    // No extra methods needed if you're only fetching by ID
    @Query("SELECT b.tableCount FROM Business b WHERE b.id = :id")
    Long findTableCountByBusinessId(Long id);


}
