package com.project.spring.service.tenant;

import com.project.spring.dto.KotItemDTO;
import com.project.spring.model.tenant.Order;
import com.project.spring.model.tenant.OrderItem;
import org.springframework.stereotype.Service;
import reactor.core.publisher.Flux;
import reactor.core.publisher.Sinks;

import java.util.List;
import java.util.concurrent.CopyOnWriteArrayList;
import java.util.stream.Collectors;

@Service
public class KotStore {

    private final List<KotItemDTO> kotQueue = new CopyOnWriteArrayList<>();
    private final Sinks.Many<List<KotItemDTO>> kotSink = Sinks.many().replay().latest();

   
    //Remove all pending KOT entries for a specific TABLE
    public void removeByTable(Long tableNumber) {
        kotQueue.removeIf(k -> k.getTableNumber().equals(tableNumber) && !k.isCompleted());
        emitUpdatedKot();
    }

    //Add order items to KOT queue and emit
    public void addOrder(Order order) {

    // remove previous pending items of this table
    kotQueue.removeIf(k -> k.getTableNumber().equals(order.getTableNumber()) && !k.isCompleted());

    for (OrderItem item : order.getItems()) {
        KotItemDTO kot = new KotItemDTO();
        kot.setOrderId(item.getId());
        kot.setItemName(item.getItemName());
        kot.setQuantity(item.getQuantity());
        kot.setTableNumber(order.getTableNumber());
        kot.setCompleted(false);

        kotQueue.add(kot);
    }

    emitUpdatedKot();   // now emits only current ones for that table
}


    //Mark all KOT items for the given TABLE as completed
    public void markCompletedByOrder(Long orderId ) {
        for (KotItemDTO item : kotQueue) {
            if (item.getOrderId().equals(orderId) && !item.isCompleted()) {
                item.setCompleted(true);
            }
        }
        emitUpdatedKot();
    }

    // Stream to SSE clients
    public Flux<List<KotItemDTO>> streamKot() {
        return kotSink.asFlux();
    }

    public List<KotItemDTO> getAllPending() {
        return kotQueue.stream()
                .filter(k -> !k.isCompleted())
                .collect(Collectors.toList());
    }

    public List<KotItemDTO> getAllCompleted() {
        return kotQueue.stream()
                .filter(KotItemDTO::isCompleted)
                .collect(Collectors.toList());
    }

    // Emit updated list to SSE subscribers
    private void emitUpdatedKot() {
        kotSink.tryEmitNext(getAllPending());
    }
}
