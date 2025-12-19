package com.project.spring.repo.tenant;

import com.project.spring.model.tenant.Order;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.util.List;
import java.util.Optional;

public interface OrderRepository extends JpaRepository<Order, Long> {

    @Query("SELECT DISTINCT o FROM Order o " +
           "LEFT JOIN FETCH o.items i " +
           "LEFT JOIN FETCH i.product " +
           "WHERE o.tableNumber = :tableNumber AND o.isCompleted = false")
    Optional<Order> findByIdWithItems(@Param("tableNumber") Long tableNumber);

    // Find the latest incomplete order for a table
    Optional<Order> findFirstByTableNumberAndIsCompletedFalse(Long tableNumber);

    //  For invoice generation
    @Query("SELECT o FROM Order o JOIN FETCH o.items WHERE o.tableNumber = :tableNumber AND o.isCompleted = false")
    Optional<Order> findIncompleteOrderWithItems(@Param("tableNumber") Long tableNumber);

    //  For table check before creating new order
    boolean existsByTableNumberAndIsCompletedFalse(Long tableNumber);

    // Get all table numbers (distinct)
    @Query("SELECT DISTINCT o.tableNumber FROM Order o")
    List<Long> findAllDistinctTableNumbers();

    // Get all table numbers where order is not completed
    @Query("SELECT DISTINCT o.tableNumber FROM Order o WHERE o.isCompleted = false")
    List<Integer> findAllOccupiedTableNumbers();

}
