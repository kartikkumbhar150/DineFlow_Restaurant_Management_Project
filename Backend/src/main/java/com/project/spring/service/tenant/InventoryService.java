package com.project.spring.service.tenant;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.cache.CacheManager;
import org.springframework.cache.annotation.CacheEvict;
import org.springframework.cache.annotation.Cacheable;
import org.springframework.scheduling.annotation.Async;
import org.springframework.stereotype.Service;

import com.project.spring.dto.InventoryDTO;
import com.project.spring.model.tenant.Inventory;
import com.project.spring.repo.tenant.InventoryRepository;

import java.time.LocalDate;
import java.time.LocalTime;
import java.time.format.DateTimeFormatter;
import java.util.List;
import java.util.stream.Collectors;

@Service
public class InventoryService {

    @Autowired
    private InventoryRepository inventoryRepository;

    @Autowired
    private CacheManager cacheManager;

    private static final DateTimeFormatter TIME_FORMAT =
            DateTimeFormatter.ofPattern("hh:mm a");

    private static final String INVENTORY_CACHE = "inventory";

    // ================= CREATE (single) =================
    public Inventory createInventory(InventoryDTO inventoryDTO) {

        Inventory inventory = new Inventory();
        inventory.setItemName(inventoryDTO.getItemName());
        inventory.setQuantity(inventoryDTO.getQuantity());
        inventory.setUnit(inventoryDTO.getUnit());
        inventory.setPrice(inventoryDTO.getPrice());

        inventory.setDate(LocalDate.now().toString());
        inventory.setTime(LocalTime.now().format(TIME_FORMAT));

        Inventory saved = inventoryRepository.save(inventory);

        // refresh cache immediately (async)
        refreshInventoryCacheAsync();

        return saved;
    }

    // ================= BULK CREATE =================
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
                }).collect(Collectors.toList());

        List<Inventory> saved = inventoryRepository.saveAll(inventoryList);

        refreshInventoryCacheAsync();

        return saved;
    }

    // ================= READ (CACHED) =================
    @Cacheable(value = INVENTORY_CACHE, key = "'all'")
    public List<Inventory> getAllInventory() {
        System.out.println("Fetching inventory from DATABASE");
        return inventoryRepository.findAll();
    }

    // ================= MANUAL CLEAR (optional) =================
    @CacheEvict(value = INVENTORY_CACHE, key = "'all'")
    public void clearInventoryCache() {
        // clears cache if needed
    }

    // ================= BACKGROUND REFRESH =================
    @Async
    public void refreshInventoryCacheAsync() {

        List<Inventory> list = inventoryRepository.findAll();

        var cache = cacheManager.getCache(INVENTORY_CACHE);
        if (cache != null) {
            cache.put("all", list);
        }
    }
}
