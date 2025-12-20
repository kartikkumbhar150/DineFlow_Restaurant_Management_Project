package com.project.spring.repo.tenant;
import com.project.spring.model.tenant.Inventory;

import java.time.LocalDate;
import java.util.List;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

@Repository
public interface InventoryRepository extends JpaRepository<Inventory, Long> {

    @Query("SELECT COALESCE(SUM(i.price), 0) FROM Inventory i WHERE i.date BETWEEN :start AND :end")
    double getTotalExpenseBetweenDates(@Param("start") String start,
                                       @Param("end") String end);

    @Query("""
    SELECT i FROM Inventory i
    WHERE i.date BETWEEN :start AND :end
    ORDER BY i.date ASC
""")
List<Inventory> findInventoryBetweenDates(
        @Param("start") String start,
        @Param("end") String end
);

}
