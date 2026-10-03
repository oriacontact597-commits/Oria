package tg.edtch.activEducation.evolution.engines;

import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import tg.edtch.activEducation.portfolio.domain.entite.PortfolioCompetence;
import tg.edtch.activEducation.portfolio.repository.PortfolioCompetenceRepository;

import java.util.List;
import java.util.UUID;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
class SkillsEngineTest {

    @Mock
    private PortfolioCompetenceRepository portfolioRepository;

    private SkillsEngine engine;

    @BeforeEach
    void setUp() {
        engine = new SkillsEngine(portfolioRepository);
    }

    @Test
    void name_isSkills() {
        assertEquals("skills", engine.name());
    }

    @Test
    void evaluate_noSkills_returnsNeutral() {
        UUID sid = UUID.randomUUID();
        when(portfolioRepository.findByEleveTrackingIdOrderByCategorieAscNiveauEstimeDesc(sid.toString()))
                .thenReturn(List.of());

        Engine.Output out = engine.evaluate(sid);
        assertEquals(0.5, out.score());
        assertEquals(0, out.details().get("skillsCount"));
    }

    @Test
    void evaluate_withSkills_computesScore() {
        UUID sid = UUID.randomUUID();
        var c1 = competence("Technique", 4);
        var c2 = competence("Technique", 3);
        var c3 = competence("Relationnel", 5);
        var c4 = competence("Relationnel", 2);
        when(portfolioRepository.findByEleveTrackingIdOrderByCategorieAscNiveauEstimeDesc(sid.toString()))
                .thenReturn(List.of(c1, c2, c3, c4));

        Engine.Output out = engine.evaluate(sid);
        double avgLevel = (4.0 + 3 + 5 + 2) / 4;
        double expected = 0.3 + 0.7 * (avgLevel / 5.0) * Math.min(1.0, 4.0 / 10.0);
        assertEquals(expected, out.score(), 0.001);
        assertEquals(4, out.details().get("skillsCount"));
    }

    @Test
    void evaluate_withNoCategory_usesAutre() {
        UUID sid = UUID.randomUUID();
        var c1 = competence(null, 3);
        when(portfolioRepository.findByEleveTrackingIdOrderByCategorieAscNiveauEstimeDesc(sid.toString()))
                .thenReturn(List.of(c1));

        Engine.Output out = engine.evaluate(sid);
        assertEquals(1, out.details().get("skillsCount"));
    }

    private static PortfolioCompetence competence(String categorie, int niveau) {
        var c = mock(PortfolioCompetence.class);
        when(c.getCategorie()).thenReturn(categorie);
        when(c.getNiveauEstime()).thenReturn(niveau);
        return c;
    }
}
