package com.project.spring.service.master;

import com.project.spring.config.TenantContext;
import com.project.spring.dto.StaffDTO;
import com.project.spring.model.master.MasterBusiness;
import com.project.spring.model.master.StaffUser;
import com.project.spring.model.tenant.Staff;
import com.project.spring.repo.master.MasterBusinessRepository;
import com.project.spring.repo.master.StaffUserRepository;
import lombok.RequiredArgsConstructor;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.data.redis.core.RedisTemplate;
import org.springframework.security.authentication.AuthenticationManager;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.Authentication;
import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import java.time.Duration;

@Service
@RequiredArgsConstructor
@Transactional
public class StaffUserService {

    private final MasterBusinessRepository businessRepository;
    private final StaffUserRepository staffUserRepository;
    private final JWTService jwtService;
    private final AuthenticationManager authManager;
    private final BCryptPasswordEncoder encoder = new BCryptPasswordEncoder(12);
    
    private final RedisTemplate<String, Object> redisTemplate;

    public void blacklistToken(String token) {

    // Avoid null / blank values
    if (token == null || token.isBlank()) return;

    // 🔐 Store blacklist flag with expiry
    redisTemplate.opsForValue().set(
            "blacklist:" + token,
            "true",
            Duration.ofHours(12)   // ideally: match your JWT expiry time
    );
}

    /**
     * Save staff user to master DB with encoded password.
     * No token is generated here, only on login.
     */
    public void saveStaffToMaster(Staff staff, Long businessId) {
        String originalTenant = TenantContext.getCurrentTenant();
        try {
            TenantContext.clear(); // Switch to master DB

            MasterBusiness business = businessRepository.findById(businessId)
                    .orElseThrow(() -> new RuntimeException("Business not found"));

            StaffUser user = staffUserRepository.findByUserName(staff.getUserName())
                    .orElse(new StaffUser());

            user.setName(staff.getName());
            user.setUserName(staff.getUserName());
            user.setRole(staff.getRole());
            user.setPassword(encoder.encode(staff.getPassword())); // Always encode
            user.setDbName(business.getDbName());

            // 🚫 Do not set token here — tokens only on login

            staffUserRepository.saveAndFlush(user);
        } finally {
            restoreTenant(originalTenant);
        }
    }

    /**
     * Authenticate user and generate + persist new token.
     * Old token is overwritten so only one valid token exists per user.
     */
    public String verify(StaffUser user) {
        Authentication authentication = authManager.authenticate(
                new UsernamePasswordAuthenticationToken(
                        user.getUserName(),
                        user.getPassword()
                )
        );

        if (authentication.isAuthenticated()) {
            StaffUser dbUser = findByUserName(user.getUserName());
            if (dbUser != null) {
                // ✅ Generate new token
                String newToken = jwtService.generateToken(
                        dbUser.getUserName(),
                        dbUser.getRole(),
                        dbUser.getDbName()
                );

                // ✅ Save in DB (overwrite old token)
                dbUser.setToken(newToken);
                staffUserRepository.saveAndFlush(dbUser);

                return newToken;
            }
        }

        return "fail";
    }

    public StaffUser findByUserName(String username) {
        return staffUserRepository.findByUserName(username).orElse(null);
    }

    public boolean checkPassword(String rawPassword, String encodedPassword) {
        return encoder.matches(rawPassword, encodedPassword);
    }

    public void deleteStaffFromMaster(Long staffId) {
        String originalTenant = TenantContext.getCurrentTenant();
        try {
            TenantContext.clear();
            staffUserRepository.deleteById(staffId);
        } finally {
            restoreTenant(originalTenant);
        }
    }

    public StaffDTO getStaffByID(Long id) {
        String originalTenant = TenantContext.getCurrentTenant();
        try {
            TenantContext.clear();
            StaffUser staffUser = staffUserRepository.findById(id)
                    .orElseThrow(() -> new RuntimeException("Staff not found"));
            return mapToResponseDTO(staffUser);
        } finally {
            restoreTenant(originalTenant);
        }
    }

    private StaffDTO mapToResponseDTO(StaffUser staffUser) {
        StaffDTO dto = new StaffDTO();
        dto.setId(staffUser.getId());
        dto.setName(staffUser.getName());
        dto.setUserName(staffUser.getUserName());
        dto.setRole(staffUser.getRole());
        return dto;
    }

    private void restoreTenant(String tenant) {
        if (tenant != null) {
            TenantContext.setCurrentTenant(tenant);
        } else {
            TenantContext.clear();
        }
    }
    public void clearToken(String token) {
    staffUserRepository.clearTokenByToken(token);
}

}
