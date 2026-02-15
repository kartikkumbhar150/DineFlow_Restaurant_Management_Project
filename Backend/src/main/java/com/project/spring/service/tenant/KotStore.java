package com.project.spring.service.tenant;

import com.project.spring.config.TenantContext;
import com.project.spring.dto.KotItemDTO;
import com.project.spring.model.tenant.Order;
import com.project.spring.model.tenant.OrderItem;
import org.springframework.stereotype.Service;
import reactor.core.publisher.Flux;
import reactor.core.publisher.Sinks;

import java.util.*;
import java.util.concurrent.ConcurrentHashMap;
import java.util.concurrent.CopyOnWriteArrayList;
import java.util.stream.Collectors;

@Service
public class KotStore {

    // tenant → kot list
    private final Map<String, List<KotItemDTO>> kotQueues = new ConcurrentHashMap<>();

    // tenant → sink
    private final Map<String, Sinks.Many<List<KotItemDTO>>> kotSinks = new ConcurrentHashMap<>();

    /* ============================================================
       ================= INTERNAL HELPERS =========================
       ============================================================ */

    private String getTenant() {
        return TenantContext.getCurrentTenant();
    }

    private List<KotItemDTO> getTenantQueue() {
        return kotQueues.computeIfAbsent(getTenant(),
                t -> new CopyOnWriteArrayList<>());
    }

    private Sinks.Many<List<KotItemDTO>> getTenantSink() {
        return kotSinks.computeIfAbsent(getTenant(),
                t -> Sinks.many().replay().latest());
    }

    /* ============================================================
       ================= REMOVE BY TABLE ==========================
       ============================================================ */

    public void removeByTable(Long tableNumber) {

        List<KotItemDTO> queue = getTenantQueue();

        queue.removeIf(k ->
                k.getTableNumber().equals(tableNumber)
                        && !k.isCompleted());

        emitUpdatedKot();
    }

    /* ============================================================
       ================= ADD ORDER ================================
       ============================================================ */

    public void addOrder(Order order) {

        List<KotItemDTO> queue = getTenantQueue();

        // remove previous pending items for same table
        queue.removeIf(k ->
                k.getTableNumber().equals(order.getTableNumber())
                        && !k.isCompleted());

        for (OrderItem item : order.getItems()) {

            KotItemDTO kot = new KotItemDTO();
            kot.setOrderId(item.getOrder().getId());
            kot.setItemName(item.getItemName());
            kot.setQuantity(item.getQuantity());
            kot.setTableNumber(order.getTableNumber());
            kot.setCompleted(false);

            queue.add(kot);
        }

        emitUpdatedKot();
    }

    /* ============================================================
       ================= MARK COMPLETED ===========================
       ============================================================ */

    public void markCompletedByOrder(Long orderId) {

        List<KotItemDTO> queue = getTenantQueue();

        for (KotItemDTO item : queue) {
            if (item.getOrderId().equals(orderId)
                    && !item.isCompleted()) {
                item.setCompleted(true);
            }
        }

        emitUpdatedKot();
    }

    /* ============================================================
       ================= SSE STREAM ===============================
       ============================================================ */

    public Flux<List<KotItemDTO>> streamKot() {
        return getTenantSink().asFlux();
    }

    /* ============================================================
       ================= GETTERS ==================================
       ============================================================ */

    public List<KotItemDTO> getAllPending() {
        return getTenantQueue().stream()
                .filter(k -> !k.isCompleted())
                .collect(Collectors.toList());
    }

    public List<KotItemDTO> getAllCompleted() {
        return getTenantQueue().stream()
                .filter(KotItemDTO::isCompleted)
                .collect(Collectors.toList());
    }

    /* ============================================================
       ================= EMIT =====================================
       ============================================================ */

    private void emitUpdatedKot() {
        getTenantSink().tryEmitNext(getAllPending());
    }
}
