package tg.edtch.activEducation.evolution.engines;

import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import tg.edtch.activEducation.riasec.domain.entite.TestRIASECResultat;
import tg.edtch.activEducation.riasec.repository.TestRIASECResultatRepository;

import java.time.LocalDateTime;
import java.util.List;
import java.util.UUID;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
class RIASECEngineTest {

    @Mock
    private TestRIASECResultatRepository riasecRepository;

    private RIASECEngine engine;

    @BeforeEach
    void setUp() {
        engine = new RIASECEngine(riasecRepository);
    }

    @Test
    void name_isRiasec() {
        assertEquals("riasec", engine.name());
    }

    @Test
    void evaluate_noTests_returnsNeutral() {
        UUID sid = UUID.randomUUID();
        when(riasecRepository.findByEleveTrackingIdOrderByDatePassationDesc(sid.toString()))
                .thenReturn(List.of());

        Engine.Output out = engine.evaluate(sid);
        assertEquals(0.5, out.score());
        assertEquals(0, out.details().get("testsCount"));
    }

    @Test
    void evaluate_withLatestTest_computesAverage() {
        UUID sid = UUID.randomUUID();
        var test = mock(TestRIASECResultat.class);
        when(test.getScoreRealiste()).thenReturn(20);
        when(test.getScoreInvestigateur()).thenReturn(15);
        when(test.getScoreArtistique()).thenReturn(25);
        when(test.getScoreSocial()).thenReturn(10);
        when(test.getScoreEntreprenant()).thenReturn(18);
        when(test.getScoreConventionnel()).thenReturn(12);
        when(test.getCodeProfil()).thenReturn("RIA");
        when(test.getDatePassation()).thenReturn(LocalDateTime.now());

        when(riasecRepository.findByEleveTrackingIdOrderByDatePassationDesc(sid.toString()))
                .thenReturn(List.of(test));

        Engine.Output out = engine.evaluate(sid);
        double expected = (20.0/30 + 15.0/30 + 25.0/30 + 10.0/30 + 18.0/30 + 12.0/30) / 6.0;
        assertEquals(expected, out.score(), 0.001);
        assertEquals("RIA", out.details().get("profileCode"));
    }

    @Test
    void evaluate_withNullScores_handlesGracefully() {
        UUID sid = UUID.randomUUID();
        var test = mock(TestRIASECResultat.class);
        when(test.getScoreRealiste()).thenReturn(null);
        when(test.getScoreInvestigateur()).thenReturn(null);
        when(test.getScoreArtistique()).thenReturn(null);
        when(test.getScoreSocial()).thenReturn(null);
        when(test.getScoreEntreprenant()).thenReturn(null);
        when(test.getScoreConventionnel()).thenReturn(null);
        when(test.getCodeProfil()).thenReturn("------");
        when(test.getDatePassation()).thenReturn(LocalDateTime.now());

        when(riasecRepository.findByEleveTrackingIdOrderByDatePassationDesc(sid.toString()))
                .thenReturn(List.of(test));

        Engine.Output out = engine.evaluate(sid);
        assertEquals(0.0, out.score(), 0.001);
    }
}
