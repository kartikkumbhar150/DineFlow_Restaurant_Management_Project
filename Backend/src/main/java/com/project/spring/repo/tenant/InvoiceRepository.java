package com.project.spring.repo.tenant;

import com.project.spring.dto.DateRangeSummaryDTO;
import com.project.spring.dto.ItemReportDTO;
import com.project.spring.model.tenant.Invoice;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
public interface InvoiceRepository extends JpaRepository<Invoice, Long> {

    // Today sales (String date)
    @Query("SELECT COALESCE(SUM(i.totalAmount), 0) FROM Invoice i WHERE i.date = :today")
    double getTodaySales(@Param("today") String today);

    // Get last invoice number
    @Query("SELECT MAX(i.invoiceNumber) FROM Invoice i")
    Long findLastInvoiceNumber();

    // Invoices between dates (String comparison)
    @Query("SELECT i FROM Invoice i WHERE i.date BETWEEN :startDate AND :endDate")
    List<Invoice> findInvoicesBetweenDates(@Param("startDate") String startDate,
                                           @Param("endDate") String endDate);

    // Find invoice by number
    @Query("SELECT i FROM Invoice i WHERE i.invoiceNumber = :invoiceNumber")
    Optional<Invoice> findByInvoiceNumber(@Param("invoiceNumber") Long invoiceNumber);

    // Most selling items with Pageable (lets us fetch top N directly from DB)
    @Query("SELECT new com.project.spring.dto.ItemReportDTO(o.itemName, SUM(o.quantity)) " +
           "FROM OrderItem o GROUP BY o.itemName ORDER BY SUM(o.quantity) DESC")
    List<ItemReportDTO> getMostSellingItems(Pageable pageable);

    @Query("SELECT new com.project.spring.dto.ItemReportDTO(o.itemName, SUM(o.quantity)) " +
           "FROM OrderItem o GROUP BY o.itemName ORDER BY SUM(o.quantity) DESC")
    List<ItemReportDTO> getAllSellingItems(Pageable pageable);

    // Count invoices between dates
    @Query("SELECT COUNT(i) FROM Invoice i WHERE i.date BETWEEN :start AND :end")
    long countInvoicesBetweenDates(@Param("start") String start,
                                   @Param("end") String end);

    // Sales between dates
    @Query("SELECT COALESCE(SUM(i.totalAmount), 0) FROM Invoice i WHERE i.date BETWEEN :start AND :end")
    double getSalesBetweenDates(@Param("start") String start,
                                @Param("end") String end);


    @Query("""
    SELECT new com.project.spring.dto.DateRangeSummaryDTO(
        COALESCE(SUM(i.gstValue), 0)
    )
    FROM Invoice i
    WHERE i.date BETWEEN :start AND :end
""")
DateRangeSummaryDTO getGstSummaryBetweenDates(@Param("start") String start,
                                             @Param("end") String end);



    // Last 7 days sales including zeros for missing days
    @Query(value = """
        SELECT 
    d.day::date AS day,
    COALESCE(SUM(i.total_amount), 0) AS total_sales
FROM 
    generate_series(
        current_date - interval '6 days',
        current_date,
        interval '1 day'
    ) AS d(day)
LEFT JOIN 
    invoice i
ON 
    date_trunc('day', i.date::timestamp) = d.day
GROUP BY 
    d.day
ORDER BY 
    d.day

        """, nativeQuery = true)
    List<Object[]> getLast7DaysSalesWithZeros();


    @Query(value = """
    SELECT 
        CASE
            WHEN EXTRACT(HOUR FROM to_timestamp(i.time, 'HH12:MI AM')) BETWEEN 0 AND 3 
                THEN '12 AM - 04 AM'
            WHEN EXTRACT(HOUR FROM to_timestamp(i.time, 'HH12:MI AM')) BETWEEN 4 AND 7 
                THEN '04 AM - 08 AM'
            WHEN EXTRACT(HOUR FROM to_timestamp(i.time, 'HH12:MI AM')) BETWEEN 8 AND 11 
                THEN '08 AM - 12 PM'
            WHEN EXTRACT(HOUR FROM to_timestamp(i.time, 'HH12:MI AM')) BETWEEN 12 AND 15 
                THEN '12 PM - 04 PM'
            WHEN EXTRACT(HOUR FROM to_timestamp(i.time, 'HH12:MI AM')) BETWEEN 16 AND 19 
                THEN '04 PM - 08 PM'
            WHEN EXTRACT(HOUR FROM to_timestamp(i.time, 'HH12:MI AM')) BETWEEN 20 AND 23 
                THEN '08 PM - 12 AM'
        END AS time_slot,
        COALESCE(SUM(i.total_amount), 0) AS total_sales
    FROM invoice i
    WHERE i.date::date BETWEEN current_date - interval '6 days' AND current_date
    GROUP BY time_slot
    ORDER BY MIN(EXTRACT(HOUR FROM to_timestamp(i.time, 'HH12:MI AM')))
    """, nativeQuery = true)
List<Object[]> getLast7DaysSalesByTimeSlots();



}
