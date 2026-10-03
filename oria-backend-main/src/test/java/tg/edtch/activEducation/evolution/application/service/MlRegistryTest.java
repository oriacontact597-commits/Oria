package tg.edtch.activEducation.evolution.application.service;

import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.ArgumentCaptor;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageImpl;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Pageable;
import tg.edtch.activEducation.evolution.application.dto.PromoteWeightsRequest;
import tg.edtch.activEducation.evolution.application.dto.ScoringConfigHistoryResponse;
import tg.edtch.activEducation.evolution.domain.entite.ScoringConfig;
import tg.edtch.activEducation.evolution.domain.entite.ScoringConfigHistory;
import tg.edtch.activEducation.evolution.domain.repository.ScoringConfigHistoryRepository;
import tg.edtch.activEducation.evolution.domain.repository.ScoringConfigRepository;

import java.util.List;
import java.util.Map;
import java.util.NoSuchElementException;
import java.util.Optional;
import java.util.UUID;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
class MlRegistryTest {

    @Mock
    private ScoringConfigRepository configRepository;

    @Mock
    private ScoringConfigHistoryRepository historyRepository;

    private MlRegistry mlRegistry;

    @org.junit.jupiter.api.BeforeEach
    void setUp() {
        mlRegistry = new MlRegistry(configRepository, historyRepository);
    }

    // ─────────────────────────────────────────────────────────────────────────
    // PROMOTE
    // ─────────────────────────────────────────────────────────────────────────

    @Test
    void promoteWeights_createsNewActiveConfig_andHistoryEntry() {
        PromoteWeightsRequest req = PromoteWeightsRequest.builder()
                .countryCode("TG")
                .configName("default_v1")
                .weights(Map.of("academic", 0.5, "interest", 0.3, "riasec", 0.2))
                .comment("Test promote")
                .build();

        when(configRepository.findByCountryCodeAndConfigNameAndIsActiveTrue("TG", "default_v1"))
                .thenReturn(Optional.empty());
        when(configRepository.save(any(ScoringConfig.class)))
                .thenAnswer(inv -> inv.getArgument(0));
        when(historyRepository.findByCountryCodeAndConfigNameAndIsCurrentTrue("TG", "default_v1"))
                .thenReturn(Optional.empty());
        when(historyRepository.save(any(ScoringConfigHistory.class)))
                .thenAnswer(inv -> inv.getArgument(0));

        ScoringConfigHistoryResponse resp = mlRegistry.promoteWeights(req, "admin@activeducation.tg");

        assertNotNull(resp);
        assertEquals("TG", resp.getCountryCode());
        assertEquals("default_v1", resp.getConfigName());
        assertEquals(ScoringConfigHistory.ActionType.PROMOTE, resp.getAction());
        assertTrue(resp.getIsCurrent());
        assertEquals("admin@activeducation.tg", resp.getChangedBy());
        assertEquals("Test promote", resp.getComment());
        assertEquals(0.5, resp.getWeights().get("academic"));

        // Vérifie que 2 saves ont eu lieu : 1 ScoringConfig + 1 History
        verify(configRepository, times(1)).save(any(ScoringConfig.class));
        verify(historyRepository, times(1)).save(any(ScoringConfigHistory.class));
    }

    @Test
    void promoteWeights_rejectsInvalidWeightsSum() {
        // Somme = 1.5, devrait être rejetée
        PromoteWeightsRequest req = PromoteWeightsRequest.builder()
                .countryCode("TG")
                .configName("default_v1")
                .weights(Map.of("academic", 1.0, "interest", 0.5))
                .build();

        IllegalArgumentException ex = assertThrows(IllegalArgumentException.class,
                () -> mlRegistry.promoteWeights(req, "admin@activeducation.tg"));
        assertTrue(ex.getMessage().contains("somme des weights"));

        // Aucun save ne doit avoir eu lieu
        verify(configRepository, never()).save(any());
        verify(historyRepository, never()).save(any());
    }

    @Test
    void promoteWeights_rejectsNegativeWeight() {
        PromoteWeightsRequest req = PromoteWeightsRequest.builder()
                .countryCode("TG")
                .configName("default_v1")
                .weights(Map.of("academic", -0.1, "interest", 1.1))
                .build();

        IllegalArgumentException ex = assertThrows(IllegalArgumentException.class,
                () -> mlRegistry.promoteWeights(req, "admin@activeducation.tg"));
        assertTrue(ex.getMessage().contains("'academic'"));

        verify(configRepository, never()).save(any());
    }

    // ─────────────────────────────────────────────────────────────────────────
    // ROLLBACK
    // ─────────────────────────────────────────────────────────────────────────

    @Test
    void rollbackTo_copiesWeightsFromHistory_andCreatesRollbackEntry() {
        UUID sourceId = UUID.randomUUID();
        Map<String, Double> originalWeights = Map.of("academic", 0.4, "interest", 0.4, "riasec", 0.2);

        ScoringConfigHistory source = ScoringConfigHistory.builder()
                .trackingId(sourceId)
                .countryCode("TG")
                .configName("default_v1")
                .weights(originalWeights)
                .action(ScoringConfigHistory.ActionType.PROMOTE)
                .changedBy("alice@activeducation.tg")
                .isCurrent(false) // Source n'est plus l'actuelle
                .build();

        when(historyRepository.findByTrackingId(sourceId)).thenReturn(Optional.of(source));
        when(configRepository.findByCountryCodeAndConfigNameAndIsActiveTrue("TG", "default_v1"))
                .thenReturn(Optional.empty());
        when(configRepository.save(any(ScoringConfig.class))).thenAnswer(inv -> inv.getArgument(0));
        when(historyRepository.findByCountryCodeAndConfigNameAndIsCurrentTrue("TG", "default_v1"))
                .thenReturn(Optional.empty());
        when(historyRepository.save(any(ScoringConfigHistory.class))).thenAnswer(inv -> inv.getArgument(0));

        ScoringConfigHistoryResponse resp = mlRegistry.rollbackTo(sourceId, "admin@activeducation.tg", "Régression");

        assertNotNull(resp);
        assertEquals(ScoringConfigHistory.ActionType.ROLLBACK, resp.getAction());
        assertEquals(sourceId, resp.getRolledBackFrom());
        assertTrue(resp.getIsCurrent());
        assertEquals(originalWeights, resp.getWeights());
        assertEquals("Régression", resp.getComment());

        // Vérifie que la ScoringConfig restaurée contient les bons weights
        ArgumentCaptor<ScoringConfig> configCaptor = ArgumentCaptor.forClass(ScoringConfig.class);
        verify(configRepository).save(configCaptor.capture());
        assertEquals(originalWeights, configCaptor.getValue().getWeights());
        assertTrue(configCaptor.getValue().getIsActive());
    }

    @Test
    void rollbackTo_throwsWhenSourceNotFound() {
        UUID unknown = UUID.randomUUID();
        when(historyRepository.findByTrackingId(unknown)).thenReturn(Optional.empty());

        assertThrows(NoSuchElementException.class,
                () -> mlRegistry.rollbackTo(unknown, "admin@activeducation.tg", null));
    }

    @Test
    void rollbackTo_rejectsRollbackToRollback() {
        UUID rollbackId = UUID.randomUUID();
        ScoringConfigHistory rollbackEntry = ScoringConfigHistory.builder()
                .trackingId(rollbackId)
                .countryCode("TG")
                .configName("default_v1")
                .weights(Map.of("academic", 1.0))
                .action(ScoringConfigHistory.ActionType.ROLLBACK)
                .build();

        when(historyRepository.findByTrackingId(rollbackId)).thenReturn(Optional.of(rollbackEntry));

        IllegalArgumentException ex = assertThrows(IllegalArgumentException.class,
                () -> mlRegistry.rollbackTo(rollbackId, "admin@activeducation.tg", null));
        assertTrue(ex.getMessage().contains("ROLLBACK"));
    }

    // ─────────────────────────────────────────────────────────────────────────
    // QUERIES
    // ─────────────────────────────────────────────────────────────────────────

    @Test
    void getHistory_returnsAllVersionsDesc() {
        Pageable pageable = PageRequest.of(0, 20);
        ScoringConfigHistory h1 = ScoringConfigHistory.builder()
                .trackingId(UUID.randomUUID())
                .countryCode("TG").configName("default_v1")
                .weights(Map.of("academic", 0.4))
                .action(ScoringConfigHistory.ActionType.PROMOTE)
                .isCurrent(true)
                .build();
        ScoringConfigHistory h2 = ScoringConfigHistory.builder()
                .trackingId(UUID.randomUUID())
                .countryCode("TG").configName("default_v1")
                .weights(Map.of("academic", 0.5))
                .action(ScoringConfigHistory.ActionType.PROMOTE)
                .isCurrent(false)
                .build();
        Page<ScoringConfigHistory> page = new PageImpl<>(List.of(h1, h2), pageable, 2);

        when(historyRepository.findByCountryCodeAndConfigNameOrderByChangedAtDesc("TG", "default_v1", pageable))
                .thenReturn(page);

        Page<ScoringConfigHistoryResponse> result = mlRegistry.getHistory("TG", "default_v1", pageable);

        assertEquals(2, result.getTotalElements());
        assertEquals(0.4, result.getContent().get(0).getWeights().get("academic"));
        assertEquals(0.5, result.getContent().get(1).getWeights().get("academic"));
    }

    @Test
    void getCurrent_returnsNullWhenNoActive() {
        when(historyRepository.findByCountryCodeAndConfigNameAndIsCurrentTrue("TG", "default_v1"))
                .thenReturn(Optional.empty());

        ScoringConfigHistoryResponse result = mlRegistry.getCurrent("TG", "default_v1");
        assertNull(result);
    }
}
