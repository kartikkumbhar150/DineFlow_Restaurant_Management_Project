package com.project.spring.controller.tenant;

import com.project.spring.dto.KotItemDTO;
import com.project.spring.dto.MarkCompleteRequest;
import com.project.spring.service.tenant.KotStore;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import reactor.core.publisher.Flux;

import java.util.List;

@RestController
@RequestMapping("/api/v1/kot")
public class KotSseController {

    private final KotStore kotStore;

    public KotSseController(KotStore kotStore) {
        this.kotStore = kotStore;
    }

    @GetMapping(value = "/stream", produces = MediaType.TEXT_EVENT_STREAM_VALUE)
    public Flux<List<KotItemDTO>> streamKot() {
        return kotStore.streamKot();
    }

    @PostMapping("/mark-complete")
    public ResponseEntity<Void> markComplete(@RequestBody MarkCompleteRequest request) {
        kotStore.markCompletedByOrder(request.getOrderId());
        return ResponseEntity.ok().build();
    }

    @GetMapping("/pending")
    public List<KotItemDTO> getPending() {
        return kotStore.getAllPending();
    }

    @GetMapping("/completed")
    public List<KotItemDTO> getCompleted() {
        return kotStore.getAllCompleted();
    }
}
