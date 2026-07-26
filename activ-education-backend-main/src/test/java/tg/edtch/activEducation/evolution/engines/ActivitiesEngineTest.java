package tg.edtch.activEducation.evolution.engines;

import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import tg.edtch.activEducation.defis.domain.entite.DefiReleve;
import tg.edtch.activEducation.defis.repository.DefiReleveRepository;

import java.util.List;
import java.util.UUID;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
class ActivitiesEngineTest {

    @Mock
    private DefiReleveRepository defiReleveRepository;

    private ActivitiesEngine engine;

    @BeforeEach
    void setUp() {
        engine = new ActivitiesEngine(defiReleveRepository);
    }

    @Test
    void name_isActivities() {
        assertEquals("activities", engine.name());
    }

    @Test
    void evaluate_noActivities_returnsNeutral() {
        UUID sid = UUID.randomUUID();
        when(defiReleveRepository.findByEleveTrackingId(sid.toString())).thenReturn(List.of());

        Engine.Output out = engine.evaluate(sid);
        assertEquals(0.5, out.score());
        assertEquals("Aucune activité extra-scolaire recensée.", out.explanation());
    }

    @Test
    void evaluate_withCompletedActivities_returnsScore() {
        UUID sid = UUID.randomUUID();
        var completed = mock(DefiReleve.class);
        when(completed.getStatut()).thenReturn("TERMINE");
        var inProgress = mock(DefiReleve.class);
        when(inProgress.getStatut()).thenReturn("EN_COURS");

        when(defiReleveRepository.findByEleveTrackingId(sid.toString()))
                .thenReturn(List.of(completed, completed, completed, inProgress));

        Engine.Output out = engine.evaluate(sid);
        assertEquals(4, out.details().get("activitiesCount"));
        assertEquals(3L, out.details().get("completedCount"));
        assertEquals(1L, out.details().get("inProgressCount"));
    }

    @Test
    void evaluate_manyActivities_clampsTo1() {
        UUID sid = UUID.randomUUID();
        var completed = mock(DefiReleve.class);
        when(completed.getStatut()).thenReturn("TERMINE");

        when(defiReleveRepository.findByEleveTrackingId(sid.toString()))
                .thenReturn(List.of(completed, completed, completed, completed, completed,
                        completed, completed, completed, completed, completed));

        Engine.Output out = engine.evaluate(sid);
        assertEquals(1.0, out.score(), 0.001);
    }
}
