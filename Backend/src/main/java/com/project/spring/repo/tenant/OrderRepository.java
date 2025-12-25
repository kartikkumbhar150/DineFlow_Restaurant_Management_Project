package com.project.spring.repo.tenant;

import com.project.spring.model.tenant.Order;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.util.List;
import java.util.Optional;

public interface OrderRepository extends JpaRepository<Order, Long> {

    /**
     * Fetch active order for a table INCLUDING items + product details.
     * Uses fetch joins so only ONE query hits DB.
     */
    @Query("""
        SELECT o 
        FROM Order o
        LEFT JOIN FETCH o.items i
        LEFT JOIN FETCH i.product
        WHERE o.tableNumber = :tableNumber
          AND o.isCompleted = false
    """)
    Optional<Order> findByIdWithItems(@Param("tableNumber") Long tableNumber);

    /**
     * Fast lookup — uses existing index on tableNumber.
     */
    Optional<Order> findFirstByTableNumberAndIsCompletedFalse(Long tableNumber);

    /**
     * Used when generating invoice — fetches order + items eagerly.
     */
    @Query("""
        SELECT o
        FROM Order o
        JOIN FETCH o.items
        WHERE o.tableNumber = :tableNumber
          AND o.isCompleted = false
    """)
    Optional<Order> findIncompleteOrderWithItems(@Param("tableNumber") Long tableNumber);

    /**
     * Prevent duplicate open orders per table.
     */
    boolean existsByTableNumberAndIsCompletedFalse(Long tableNumber);

    /**
     * All tables that ever had orders.
     */
    @Query("SELECT DISTINCT o.tableNumber FROM Order o")
    List<Long> findAllDistinctTableNumbers();

    /**
     * Only tables currently occupied (open orders).
     * Using Long — avoids DB implicit casts.
     */
    @Query("SELECT DISTINCT o.tableNumber FROM Order o WHERE o.isCompleted = false")
    List<Long> findAllOccupiedTableNumbers();
}
