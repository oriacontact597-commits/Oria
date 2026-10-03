package tg.edtch.activEducation.evolution.application.controller;

import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Sort;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.web.bind.annotation.*;
import tg.edtch.activEducation.evolution.application.dto.PromoteWeightsRequest;
import tg.edtch.activEducation.evolution.application.dto.ScoringConfigHistoryResponse;
import tg.edtch.activEducation.evolution.application.service.MlRegistry;

import java.util.Map;
import java.util.UUID;

/**
 * Endpoints admin du MlRegistry (P2.1 ORIA).
 * Permet de promouvoir de nouvelles pondérations, consulter l'historique, et rollback.
 * Réservé ADMIN et SUPER_ADMIN (défense en profondeur : URL dans SecurityConfig + @PreAuthorize).
 */
@RestController
@RequestMapping("/api/v1/admin/scoring-config")
@RequiredArgsConstructor
@Tag(name = "Admin : Scoring Config (MlRegistry)",
        description = "Versioning et rollback des pondérations de scoring")
public class AdminScoringConfigController {

    private final MlRegistry mlRegistry;

    /**
     * Promouvoir une nouvelle configuration de scoring.
     */
    @PostMapping("/promote")
    @PreAuthorize("hasAnyRole('ADMIN', 'SUPER_ADMIN')")
    @Operation(summary = "Promouvoir une nouvelle configuration de scoring")
    public ResponseEntity<ScoringConfigHistoryResponse> promote(
            @Valid @RequestBody PromoteWeightsRequest request,
            @AuthenticationPrincipal UserDetails user) {
        String userEmail = user != null ? user.getUsername() : "unknown";
        ScoringConfigHistoryResponse response = mlRegistry.promoteWeights(request, userEmail);
        return ResponseEntity.status(HttpStatus.CREATED).body(response);
    }

    /**
     * Consulter l'historique paginé pour un (pays, name).
     */
    @GetMapping("/history")
    @PreAuthorize("hasAnyRole('ADMIN', 'SUPER_ADMIN')")
    @Operation(summary = "Historique paginé des configurations de scoring")
    public ResponseEntity<Page<ScoringConfigHistoryResponse>> history(
            @RequestParam(required = false, defaultValue = "TG") String countryCode,
            @RequestParam(required = false, defaultValue = "default_v1") String configName,
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "20") int size) {
        return ResponseEntity.ok(mlRegistry.getHistory(countryCode, configName,
                PageRequest.of(page, size, Sort.by(Sort.Direction.DESC, "changedAt"))));
    }

    /**
     * Consulter la configuration active courante.
     */
    @GetMapping("/current")
    @PreAuthorize("hasAnyRole('ADMIN', 'SUPER_ADMIN')")
    @Operation(summary = "Configuration de scoring active courante")
    public ResponseEntity<ScoringConfigHistoryResponse> current(
            @RequestParam(required = false, defaultValue = "TG") String countryCode,
            @RequestParam(required = false, defaultValue = "default_v1") String configName) {
        ScoringConfigHistoryResponse current = mlRegistry.getCurrent(countryCode, configName);
        if (current == null) {
            return ResponseEntity.ok(null);
        }
        return ResponseEntity.ok(current);
    }

    /**
     * Rollback vers une configuration passée.
     */
    @PostMapping("/rollback")
    @PreAuthorize("hasAnyRole('ADMIN', 'SUPER_ADMIN')")
    @Operation(summary = "Rollback vers une configuration d'historique passée")
    public ResponseEntity<ScoringConfigHistoryResponse> rollback(
            @RequestBody Map<String, Object> body,
            @AuthenticationPrincipal UserDetails user) {
        UUID sourceTrackingId = UUID.fromString((String) body.get("historyTrackingId"));
        String comment = (String) body.get("comment");
        String userEmail = user != null ? user.getUsername() : "unknown";
        return ResponseEntity.status(HttpStatus.CREATED)
                .body(mlRegistry.rollbackTo(sourceTrackingId, userEmail, comment));
    }
}
