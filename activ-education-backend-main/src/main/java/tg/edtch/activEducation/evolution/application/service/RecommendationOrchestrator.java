package tg.edtch.activEducation.evolution.application.service;

import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import tg.edtch.activEducation.evolution.engines.Engine;
import tg.edtch.activEducation.evolution.engines.ExplainabilityEngine;

import java.util.*;

@Service
@RequiredArgsConstructor
@Slf4j
public class RecommendationOrchestrator {

    private final StudentEvolutionService studentEvolutionService;
    private final ScoringConfigService scoringConfigService;
    private final ExplainabilityEngine explainabilityEngine;
    private final List<Engine<UUID, Engine.Output>> engines;

    public OrchestratedResult orchestrate(UUID studentId) {
        return orchestrate(studentId, null, null);
    }

    public OrchestratedResult orchestrate(UUID studentId, String countryCode, String configName) {
        log.info("RecommendationOrchestrator.orchestrate({})", studentId);

        Map<String, Engine.Output> engineResults = new LinkedHashMap<>();
        for (Engine<UUID, Engine.Output> engine : engines) {
            try {
                engineResults.put(engine.name(), engine.evaluate(studentId));
            } catch (Exception e) {
                log.warn("Engine {} failed: {}", engine.name(), e.getMessage());
                engineResults.put(engine.name(),
                        new Engine.Output(0.5, "Erreur: " + e.getMessage(), Map.of()));
            }
        }

        Map<String, Double> weights = scoringConfigService.getWeights(countryCode, configName);

        double weightedScore = 0;
        double totalWeight = 0;
        for (var entry : engineResults.entrySet()) {
            double w = weights.getOrDefault(entry.getKey(), 0.0);
            weightedScore += w * entry.getValue().score();
            totalWeight += w;
        }
        if (totalWeight > 0) {
            weightedScore /= totalWeight;
        }

        Engine.Output explain = explainabilityEngine.evaluate(engineResults);

        Map<String, Object> fullDetails = buildFullDetails(engineResults, weights);

        log.info("Orchestration complete student={} score={}", studentId, weightedScore);
        return new OrchestratedResult(studentId, weightedScore, explain, fullDetails);
    }

    private Map<String, Object> buildFullDetails(
            Map<String, Engine.Output> results, Map<String, Double> weights) {

        Map<String, Object> details = new LinkedHashMap<>();
        details.put("orchestratedAt", System.currentTimeMillis());
        List<Map<String, Object>> engineDetails = new ArrayList<>();
        for (var entry : results.entrySet()) {
            Map<String, Object> ed = new LinkedHashMap<>();
            ed.put("name", entry.getKey());
            ed.put("score", entry.getValue().score());
            ed.put("weight", weights.getOrDefault(entry.getKey(), 0.0));
            ed.put("explanation", entry.getValue().explanation());
            engineDetails.add(ed);
        }
        details.put("engines", engineDetails);
        details.put("weights", weights);
        details.put("explainability", Map.of(
                "summary", explainabilityEngine.evaluate(results).details().get("summary")));
        return details;
    }

    public record OrchestratedResult(
            UUID studentId,
            double overallScore,
            Engine.Output explainability,
            Map<String, Object> details) {
    }
}
