package com.project.spring.repo.master;

import com.project.spring.model.master.StaffUser;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.Optional;

@Repository
public interface StaffUserRepository extends JpaRepository<StaffUser, Long> {
    @Query("SELECT u FROM StaffUser u WHERE u.userName = :userName")
    Optional<StaffUser> findByUserName(@Param("userName") String userName);

    Optional<StaffUser> findBydbName(String dbName);

    @Modifying
    @Query("UPDATE StaffUser u SET u.token = null WHERE u.token = :token")
    void clearTokenByToken(String token);

}
