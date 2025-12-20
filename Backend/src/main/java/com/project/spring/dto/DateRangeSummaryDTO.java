package com.project.spring.dto;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;
import java.time.LocalDate;
import java.util.List;

@Data
@NoArgsConstructor
@AllArgsConstructor
public class DateRangeSummaryDTO {

    private LocalDate startDate;
    private LocalDate endDate;
    private double totalSales;
    private long invoiceCount;
    private double averageInvoiceValue;
    private double totalGst;
    private double totalInvoiceValue;

    private List<ItemReportDTO> mostSellingItems;

    // REQUIRED for JPQL projection
    public DateRangeSummaryDTO(double totalGst) {
        this.totalGst = totalGst;
    }
}
