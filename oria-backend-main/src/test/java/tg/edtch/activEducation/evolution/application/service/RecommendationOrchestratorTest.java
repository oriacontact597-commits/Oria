package tg.edtch.activEducation.evolution.application.service;

import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import tg.edtch.activEducation.evolution.engines.Engine;
import tg.edtch.activEducation.evolution.engines.ExplainabilityEngine;

import java.util.List;
import java.util.Map;
import java.util.UUID;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
class RecommendationOrchestratorTest {

    @Mock
    private StudentEvolutionService studentEvolutionService;
    @Mock
    private ScoringConfigService scoringConfigService;
    @Mock
    private ExplainabilityEngine explainabilityEngine;
    @Mock
    private Engine<UUID, Engine.Output> mockEngine;

    private RecommendationOrchestrator orchestrator;

    @BeforeEach
    void setUp() {
        lenient().when(mockEngine.name()).thenReturn("test_engine");
        when(explainabilityEngine.evaluate(any())).thenReturn(
                new Engine.Output(0.8, "Test explain", Map.of("summary", "ok")));
        orchestrator = new RecommendationOrchestrator(
                studentEvolutionService, scoringConfigService,
                explainabilityEngine, List.of(mockEngine));
    }

    @Test
    void orchestrate_withSingleEngine_returnsResult() {
        UUID sid = UUID.randomUUID();
        Engine.Output engineOut = new Engine.Output(0.75, "Good", Map.of("key", "val"));
        when(mockEngine.evaluate(sid)).thenReturn(engineOut);
        when(scoringConfigService.getWeights(null, null))
                .thenReturn(Map.of("test_engine", 1.0));

        RecommendationOrchestrator.OrchestratedResult result = orchestrator.orchestrate(sid);

        assertEquals(sid, result.studentId());
        assertEquals(0.75, result.overallScore(), 0.001);
        assertNotNull(result.explainability());
    }

    @Test
    void orchestrate_withEngineFailure_usesFallback() {
        UUID sid = UUID.randomUUID();
        when(mockEngine.evaluate(sid)).thenThrow(new RuntimeException("fail"));
        when(scoringConfigService.getWeights(null, null))
                .thenReturn(Map.of("test_engine", 1.0));

        RecommendationOrchestrator.OrchestratedResult result = orchestrator.orchestrate(sid);

        assertEquals(sid, result.studentId());
        assertEquals(0.5, result.overallScore(), 0.001);
    }

    @Test
    void orchestrate_withCountryAndConfig_passesThem() {
        UUID sid = UUID.randomUUID();
        when(mockEngine.evaluate(sid)).thenReturn(new Engine.Output(0.8, "", Map.of()));
        when(scoringConfigService.getWeights("BJ", "v2"))
                .thenReturn(Map.of("test_engine", 1.0));

        RecommendationOrchestrator.OrchestratedResult result =
                orchestrator.orchestrate(sid, "BJ", "v2");

        assertEquals(0.8, result.overallScore(), 0.001);
    }

    @Test
    void orchestrate_multipleEngines_appliesWeights() {
        UUID sid = UUID.randomUUID();

        var engineA = mock(Engine.class);
        when(engineA.name()).thenReturn("engine_a");
        when(engineA.evaluate(sid)).thenReturn(new Engine.Output(0.5, "", Map.of()));

        var engineB = mock(Engine.class);
        when(engineB.name()).thenReturn("engine_b");
        when(engineB.evaluate(sid)).thenReturn(new Engine.Output(1.0, "", Map.of()));

        var orchestrator2 = new RecommendationOrchestrator(
                studentEvolutionService, scoringConfigService,
                explainabilityEngine, List.of(engineA, engineB));

        when(scoringConfigService.getWeights(null, null))
                .thenReturn(Map.of("engine_a", 0.5, "engine_b", 0.5));

        RecommendationOrchestrator.OrchestratedResult result = orchestrator2.orchestrate(sid);

        assertEquals(0.75, result.overallScore(), 0.001);
    }
}
