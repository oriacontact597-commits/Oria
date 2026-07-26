package tg.edtch.activEducation.evolution.engines;

import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageImpl;
import tg.edtch.activEducation.bibliotheque.domain.entite.FicheMetier;
import tg.edtch.activEducation.bibliotheque.repository.FicheMetierRepository;
import tg.edtch.activEducation.riasec.domain.entite.TestRIASECResultat;
import tg.edtch.activEducation.riasec.repository.TestRIASECResultatRepository;

import java.util.List;
import java.util.UUID;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
class CareerMatchingEngineTest {

    @Mock
    private FicheMetierRepository metierRepository;
    @Mock
    private TestRIASECResultatRepository riasecRepository;

    private CareerMatchingEngine engine;

    @BeforeEach
    void setUp() {
        engine = new CareerMatchingEngine(metierRepository, riasecRepository);
    }

    @Test
    void name_isCareer() {
        assertEquals("career", engine.name());
    }

    @Test
    void evaluate_noRiasec_returnsScore5() {
        UUID sid = UUID.randomUUID();
        var metier = new FicheMetier();
        metier.setTitre("Ingénieur");
        metier.setSecteur("Technologie");
        Page<FicheMetier> page = new PageImpl<>(List.of(metier));

        when(riasecRepository.findByEleveTrackingIdOrderByDatePassationDesc(sid.toString()))
                .thenReturn(List.of());
        when(metierRepository.findAllByEstPublieTrue(any())).thenReturn(page);

        Engine.Output out = engine.evaluate(sid);
        assertEquals(0.5, out.score());
        assertFalse((Boolean) out.details().get("hasRIASEC"));
    }

    @Test
    void evaluate_withRiasecAndMetiers_returnsMatches() {
        UUID sid = UUID.randomUUID();
        var test = mock(TestRIASECResultat.class);
        when(test.getScoreRealiste()).thenReturn(25);
        when(test.getScoreInvestigateur()).thenReturn(20);
        when(test.getScoreArtistique()).thenReturn(10);
        when(test.getScoreSocial()).thenReturn(15);
        when(test.getScoreEntreprenant()).thenReturn(12);
        when(test.getScoreConventionnel()).thenReturn(8);

        var metier = new FicheMetier();
        metier.setTitre("Développeur");
        metier.setSecteur("Informatique");
        Page<FicheMetier> page = new PageImpl<>(List.of(metier));

        when(riasecRepository.findByEleveTrackingIdOrderByDatePassationDesc(sid.toString()))
                .thenReturn(List.of(test));
        when(metierRepository.findAllByEstPublieTrue(any())).thenReturn(page);

        Engine.Output out = engine.evaluate(sid);
        assertTrue(out.score() > 0.3);
        assertTrue((Integer) out.details().get("totalMatching") >= 0);
    }

    @Test
    void evaluate_noMetiers_returnsScore5() {
        UUID sid = UUID.randomUUID();
        when(metierRepository.findAllByEstPublieTrue(any())).thenReturn(Page.empty());

        Engine.Output out = engine.evaluate(sid);
        assertEquals(0.5, out.score());
        assertEquals(0, out.details().get("matchingMetiersCount"));
    }
}
