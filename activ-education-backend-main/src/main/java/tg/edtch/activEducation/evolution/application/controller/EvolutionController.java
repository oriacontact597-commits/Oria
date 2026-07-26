package tg.edtch.activEducation.evolution.application.controller;

import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;
import tg.edtch.activEducation.evolution.application.service.RecommendationOrchestrator;
import tg.edtch.activEducation.evolution.application.service.ScoringConfigService;
import tg.edtch.activEducation.evolution.application.service.StudentEvolutionService;
import tg.edtch.activEducation.evolution.domain.entite.StudentEvolutionProfile;
import tg.edtch.activEducation.evolution.engines.Engine;
import tg.edtch.activEducation.evolution.engines.EventEngine;

import java.util.Map;
import java.util.UUID;

@RestController
@RequestMapping("/api/v1/evolution")
@RequiredArgsConstructor
public class EvolutionController {

    private final StudentEvolutionService service;
    private final RecommendationOrchestrator orchestrator;
    private final ScoringConfigService scoringConfigService;
    private final EventEngine eventEngine;

    @PostMapping("/{studentId}/compute")
    @PreAuthorize("hasAnyRole('ELEVE', 'PARENT', 'CONSEILLER', 'ADMIN', 'SUPER_ADMIN')")
    public ResponseEntity<StudentEvolutionProfile> compute(@PathVariable UUID studentId) {
        return ResponseEntity.ok(service.compute(studentId));
    }

    @GetMapping("/{studentId}")
    @PreAuthorize("hasAnyRole('ELEVE', 'PARENT', 'CONSEILLER', 'ADMIN', 'SUPER_ADMIN')")
    public ResponseEntity<StudentEvolutionProfile> get(@PathVariable UUID studentId) {
        return ResponseEntity.ok(service.get(studentId));
    }

    @PostMapping("/{studentId}/orchestrate")
    @PreAuthorize("hasAnyRole('ELEVE', 'PARENT', 'CONSEILLER', 'ADMIN', 'SUPER_ADMIN')")
    public ResponseEntity<RecommendationOrchestrator.OrchestratedResult> orchestrate(
            @PathVariable UUID studentId,
            @RequestParam(required = false) String country,
            @RequestParam(required = false) String config) {
        return ResponseEntity.ok(orchestrator.orchestrate(studentId, country, config));
    }

    @GetMapping("/configs")
    @PreAuthorize("hasAnyRole('ADMIN', 'SUPER_ADMIN')")
    public ResponseEntity<Map<String, Double>> getDefaultConfig() {
        return ResponseEntity.ok(scoringConfigService.getDefaultWeights());
    }

    @GetMapping("/{studentId}/events")
    @PreAuthorize("hasAnyRole('ELEVE', 'PARENT', 'CONSEILLER', 'ADMIN', 'SUPER_ADMIN')")
    public ResponseEntity<Engine.Output> getEvents(@PathVariable UUID studentId) {
        return ResponseEntity.ok(eventEngine.evaluate(studentId));
    }

    @GetMapping("/_health")
    public ResponseEntity<Map<String, String>> health() {
        return ResponseEntity.ok(Map.of(
                "status", "ok",
                "module", "evolution",
                "phase", "3"));
    }
}
