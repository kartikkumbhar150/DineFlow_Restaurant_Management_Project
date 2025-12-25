package com.project.spring.service.tenant;

import com.project.spring.config.TenantContext;
import com.project.spring.dto.StaffDTO;
import com.project.spring.model.tenant.Staff;
import com.project.spring.repo.tenant.StaffRepository;
import com.project.spring.service.master.StaffUserService;
import com.project.spring.repo.master.MasterBusinessRepository;
import com.project.spring.model.master.MasterBusiness;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import java.util.List;
import java.util.stream.Collectors;

@Service
public class StaffService {

    @Autowired
    private StaffRepository staffRepository;

    @Autowired
    private StaffUserService staffUserService;

    @Autowired
    private MasterBusinessRepository businessRepository;


    private String getCurrentTenantId() {
        String tenantId = TenantContext.getCurrentTenant();
        if (tenantId == null) throw new IllegalStateException("Tenant ID not set in context");
        return tenantId;
    }

    private Long getCurrentBusinessId() {
        String dbName = getCurrentTenantId();
        MasterBusiness business = businessRepository.findByDbName(dbName)
                .orElseThrow(() -> new RuntimeException("Business not found for DB: " + dbName));
        return business.getId();
    }

    // CREATE — tenant + master
    public StaffDTO createStaff(StaffDTO dto) {

        Staff staff = new Staff();
        staff.setName(dto.getName());
        staff.setUserName(dto.getUserName());
        staff.setRole(dto.getRole());
        staff.setPassword(dto.getPassword());

        Staff saved = staffRepository.saveAndFlush(staff);

        Long businessId = getCurrentBusinessId();

        // save user in MASTER DB (password is encoded there)
        staffUserService.saveStaffToMaster(saved, businessId);

        return mapToResponseDTO(saved);
    }

    public List<StaffDTO> getAllStaff() {
        return staffRepository.findAll()
                .stream()
                .map(this::mapToResponseDTO)
                .collect(Collectors.toList());
    }

    // DELETE — tenant + master
    public void deleteStaff(Long id) {

        Staff staff = staffRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("Staff not found"));

        String userName = staff.getUserName();

        // delete tenant record
        staffRepository.deleteById(id);

        // lookup master user by username
        var masterUser = staffUserService.findByUserName(userName);

        if (masterUser != null) {
            // delete from master DB using its real ID
            staffUserService.deleteStaffFromMaster(masterUser.getId());
        }
    }

    public StaffDTO getStaffById(Long id) {
        Staff staff = staffRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("Staff not found"));
        return mapToResponseDTO(staff);
    }

    private StaffDTO mapToResponseDTO(Staff staff) {
        StaffDTO dto = new StaffDTO();
        dto.setId(staff.getId());
        dto.setName(staff.getName());
        dto.setUserName(staff.getUserName());
        dto.setRole(staff.getRole());
        return dto;
    }
}
