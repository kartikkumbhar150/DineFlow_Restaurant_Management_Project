package com.project.spring.service.tenant;

import com.project.spring.config.TenantContext;
import com.project.spring.dto.InventoryDTO;
import com.project.spring.model.tenant.Inventory;
import com.project.spring.repo.tenant.InventoryRepository;

import lombok.RequiredArgsConstructor;

import org.springframework.cache.annotation.CacheEvict;
import org.springframework.cache.annotation.Cacheable;
import org.springframework.stereotype.Service;

import java.time.LocalDate;
import java.time.LocalTime;
import java.time.format.DateTimeFormatter;
import java.util.List;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
public class InventoryService {

    private final InventoryRepository inventoryRepository;

    private static final DateTimeFormatter TIME_FORMAT =
            DateTimeFormatter.ofPattern("hh:mm a");

    private static final String INVENTORY_CACHE = "inventory";

    /* ============================================================
       ================= CREATE (single) ==========================
       ============================================================ */

    @CacheEvict(value = INVENTORY_CACHE, allEntries = true)
    public Inventory createInventory(InventoryDTO inventoryDTO) {

        Inventory inventory = new Inventory();
        inventory.setItemName(inventoryDTO.getItemName());
        inventory.setQuantity(inventoryDTO.getQuantity());
        inventory.setUnit(inventoryDTO.getUnit());
        inventory.setPrice(inventoryDTO.getPrice());
        inventory.setDate(LocalDate.now().toString());
        inventory.setTime(LocalTime.now().format(TIME_FORMAT));

        return inventoryRepository.save(inventory);
    }

    /* ============================================================
       ================= BULK CREATE ==============================
       ============================================================ */

    @CacheEvict(value = INVENTORY_CACHE, allEntries = true)
    public List<Inventory> createInventory(List<InventoryDTO> inventoryDTOList) {

        List<Inventory> inventoryList = inventoryDTOList.stream()
                .map(dto -> {
                    Inventory inventory = new Inventory();
                    inventory.setItemName(dto.getItemName());
                    inventory.setQuantity(dto.getQuantity());
                    inventory.setUnit(dto.getUnit());
                    inventory.setPrice(dto.getPrice());
                    inventory.setDate(LocalDate.now().toString());
                    inventory.setTime(LocalTime.now().format(TIME_FORMAT));
                    return inventory;
                })
                .collect(Collectors.toList());

        return inventoryRepository.saveAll(inventoryList);
    }

    /* ============================================================
       ================= READ (TENANT CACHED) =====================
       ============================================================ */

    @Cacheable(
        value = INVENTORY_CACHE,
        key = "T(com.project.spring.config.TenantContext).getCurrentTenant()"
    )
    public List<Inventory> getAllInventory() {

        System.out.println(
                "Fetching inventory from DATABASE | tenant = "
                        + TenantContext.getCurrentTenant()
        );

        return inventoryRepository.findAll();
    }

    /* ============================================================
       ================= MANUAL CLEAR =============================
       ============================================================ */

    @CacheEvict(value = INVENTORY_CACHE, allEntries = true)
    public void clearInventoryCache() {
        // manually clears tenant-based inventory cache
    }
}
