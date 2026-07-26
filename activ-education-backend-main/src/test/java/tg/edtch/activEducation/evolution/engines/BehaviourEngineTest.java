package tg.edtch.activEducation.evolution.engines;

import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import tg.edtch.activEducation.badge.repository.BadgeDecerneRepository;
import tg.edtch.activEducation.defis.domain.entite.DefiReleve;
import tg.edtch.activEducation.defis.repository.DefiReleveRepository;
import tg.edtch.activEducation.entretien.domain.entite.SimulationEntretien;
import tg.edtch.activEducation.entretien.repository.SimulationEntretienRepository;

import java.util.List;
import java.util.UUID;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
class BehaviourEngineTest {

    @Mock
    private DefiReleveRepository defiReleveRepository;
    @Mock
    private BadgeDecerneRepository badgeDecerneRepository;
    @Mock
    private SimulationEntretienRepository entretienRepository;

    private BehaviourEngine engine;

    @BeforeEach
    void setUp() {
        engine = new BehaviourEngine(defiReleveRepository, badgeDecerneRepository, entretienRepository);
    }

    @Test
    void name_isBehaviour() {
        assertEquals("behaviour", engine.name());
    }

    @Test
    void evaluate_noActivity_returnsLowScore() {
        UUID sid = UUID.randomUUID();
        when(defiReleveRepository.findByEleveTrackingId(sid.toString())).thenReturn(List.of());
        when(badgeDecerneRepository.countByEleveTrackingId(sid.toString())).thenReturn(0);
        when(entretienRepository.findByEleveTrackingIdOrderByCreatedAtDesc(sid.toString())).thenReturn(List.of());

        Engine.Output out = engine.evaluate(sid);
        assertEquals(0.0, out.score());
        assertEquals(0, out.details().get("totalActions"));
    }

    @Test
    void evaluate_withActivity_computesScore() {
        UUID sid = UUID.randomUUID();
        when(defiReleveRepository.findByEleveTrackingId(sid.toString()))
                .thenReturn(List.of(mock(DefiReleve.class), mock(DefiReleve.class)));
        when(badgeDecerneRepository.countByEleveTrackingId(sid.toString())).thenReturn(5);
        when(entretienRepository.findByEleveTrackingIdOrderByCreatedAtDesc(sid.toString()))
                .thenReturn(List.of(mock(SimulationEntretien.class)));

        Engine.Output out = engine.evaluate(sid);
        assertEquals(8, out.details().get("totalActions"));
        assertEquals(8.0 / 50, out.score(), 0.001);
    }

    @Test
    void evaluate_repositoryException_returnsZeroForThatMetric() {
        UUID sid = UUID.randomUUID();
        when(defiReleveRepository.findByEleveTrackingId(sid.toString())).thenThrow(new RuntimeException("DB down"));
        when(badgeDecerneRepository.countByEleveTrackingId(sid.toString())).thenReturn(0);
        when(entretienRepository.findByEleveTrackingIdOrderByCreatedAtDesc(sid.toString())).thenReturn(List.of());

        Engine.Output out = engine.evaluate(sid);
        assertEquals(0.0, out.score());
    }
}
