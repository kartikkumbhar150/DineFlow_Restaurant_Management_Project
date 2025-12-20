package com.project.spring.service.tenant;

import com.project.spring.dto.DailySalesDTO;
import com.project.spring.dto.DateRangeSummaryDTO;
import com.project.spring.dto.InventoryDTO;
import com.project.spring.dto.DateRangeExpenseDTO;
import com.project.spring.dto.ItemReportDTO;
import com.project.spring.model.tenant.Inventory;
import com.project.spring.repo.tenant.InvoiceRepository;
import com.project.spring.repo.tenant.InventoryRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.PageRequest;
import org.springframework.stereotype.Service;

import java.time.LocalDate;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

@Service
@RequiredArgsConstructor
public class ReportService {

    private final InvoiceRepository invoiceRepository;
    private final InventoryRepository inventoryRepository;


    
    public DateRangeSummaryDTO buildSummary(LocalDate start, LocalDate end) {

    String startStr = start.toString();
    String endStr = end.toString();

    // Sales (WITHOUT GST)
    double totalSales = invoiceRepository.getSalesBetweenDates(startStr, endStr);

    // Invoice count
    long count = invoiceRepository.countInvoicesBetweenDates(startStr, endStr);

    // GST (SEPARATE)
    DateRangeSummaryDTO gstDto =
            invoiceRepository.getGstSummaryBetweenDates(startStr, endStr);

    double totalGst = gstDto != null ? gstDto.getTotalGst() : 0;

    // Top items
    List<ItemReportDTO> topItems =
            invoiceRepository.getMostSellingItems(PageRequest.of(0, 12000));

    // Final DTO
    DateRangeSummaryDTO dto = new DateRangeSummaryDTO();
    dto.setStartDate(start);
    dto.setEndDate(end);

    dto.setTotalSales(totalSales);              // WITHOUT GST
    dto.setInvoiceCount(count);
    dto.setAverageInvoiceValue(
            count > 0 ? totalSales / count : 0
    );

    dto.setTotalGst(totalGst);                  
    dto.setTotalInvoiceValue(totalSales + totalGst); 

    dto.setMostSellingItems(topItems);

    return dto;
}

    public DateRangeExpenseDTO expenseSummary(LocalDate start, LocalDate end){
    String startStr = start.toString();  // "2025-09-01"
    String endStr = end.toString();      // "2025-09-22"

    double qs = inventoryRepository.getTotalExpenseBetweenDates(startStr, endStr);

    DateRangeExpenseDTO dto = new DateRangeExpenseDTO();
    dto.setExpense(qs);
    return dto;
}
    public List<InventoryDTO> buildInventory(LocalDate start, LocalDate end) {

    String startStr = start.toString(); // yyyy-MM-dd
    String endStr = end.toString();

    List<Inventory> inventoryList =
            inventoryRepository.findInventoryBetweenDates(startStr, endStr);

    List<InventoryDTO> dtoList = new ArrayList<>();

    for (Inventory inv : inventoryList) {
        InventoryDTO dto = new InventoryDTO(
                inv.getId(),
                inv.getItemName(),
                inv.getQuantity(),
                inv.getUnit(),
                inv.getPrice(),
                inv.getDate(),
                inv.getTime()
        );
        dtoList.add(dto);
    }

    return dtoList;
}





    public List<DailySalesDTO> getLast7DaysSales() {
        List<Object[]> results = invoiceRepository.getLast7DaysSalesWithZeros();
        List<DailySalesDTO> salesList = new ArrayList<>();

        for (Object[] row : results) {
            LocalDate date = ((java.sql.Date) row[0]).toLocalDate();
            double total = ((Number) row[1]).doubleValue();
            salesList.add(new DailySalesDTO(date, total));
        }

        return salesList;
    }
    public List<Map<String, Object>> getLast7DaysSalesByTimeSlots() {
    List<Object[]> rows = invoiceRepository.getLast7DaysSalesByTimeSlots();
    Map<String, Double> salesMap = new HashMap<>();

    // Store actual results from DB in a map
    for (Object[] row : rows) {
        String slot = (String) row[0];
        double sales = ((Number) row[1]).doubleValue();
        salesMap.put(slot, sales);
    }

    // Define all 6 expected time slots in order
    List<String> allSlots = Arrays.asList(
        "12 AM - 04 AM",
        "04 AM - 08 AM",
        "08 AM - 12 PM",
        "12 PM - 04 PM",
        "04 PM - 08 PM",
        "08 PM - 12 AM"
    );

    // Build final result list (fill 0.0 if missing)
    List<Map<String, Object>> result = new ArrayList<>();
    for (String slot : allSlots) {
        Map<String, Object> map = new HashMap<>();
        map.put("timeSlot", slot);
        map.put("totalSales", salesMap.getOrDefault(slot, 0.0));
        result.add(map);
    }

    return result;
}


}
