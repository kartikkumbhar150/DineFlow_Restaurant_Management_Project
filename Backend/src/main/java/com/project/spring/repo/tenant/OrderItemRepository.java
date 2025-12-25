package com.project.spring.repo.tenant;

import com.project.spring.dto.ItemReportDTO;
import com.project.spring.model.tenant.OrderItem;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;

import java.util.List;

public interface OrderItemRepository extends JpaRepository<OrderItem, Long> {

    @Query("""
        SELECT new com.project.spring.dto.ItemReportDTO(
            o.itemName,
            SUM(o.quantity)
        )
        FROM OrderItem o
        GROUP BY o.itemName
        ORDER BY SUM(o.quantity) DESC
    """)
    List<ItemReportDTO> getMostSellingItems();
}
