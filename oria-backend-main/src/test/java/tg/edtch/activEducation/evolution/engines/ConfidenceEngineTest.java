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
import tg.edtch.activEducation.evolution.domain.entite.BulletinHistory;
import tg.edtch.activEducation.evolution.domain.entite.InterviewResponseHistory;
import tg.edtch.activEducation.evolution.domain.repository.BulletinHistoryRepository;
import tg.edtch.activEducation.evolution.domain.repository.InterviewResponseHistoryRepository;
import tg.edtch.activEducation.portfolio.domain.entite.PortfolioCompetence;
import tg.edtch.activEducation.portfolio.repository.PortfolioCompetenceRepository;
import tg.edtch.activEducation.riasec.domain.entite.TestRIASECResultat;
import tg.edtch.activEducation.riasec.repository.TestRIASECResultatRepository;

import java.util.List;
import java.util.UUID;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
class ConfidenceEngineTest {

    @Mock
    private BulletinHistoryRepository bulletinRepository;
    @Mock
    private InterviewResponseHistoryRepository interviewRepository;
    @Mock
    private TestRIASECResultatRepository riasecRepository;
    @Mock
    private PortfolioCompetenceRepository portfolioRepository;
    @Mock
    private DefiReleveRepository defiReleveRepository;
    @Mock
    private BadgeDecerneRepository badgeDecerneRepository;
    @Mock
    private SimulationEntretienRepository entretienRepository;

    private ConfidenceEngine engine;

    @BeforeEach
    void setUp() {
        engine = new ConfidenceEngine(bulletinRepository, interviewRepository, riasecRepository,
                portfolioRepository, defiReleveRepository, badgeDecerneRepository, entretienRepository);
    }

    @Test
    void name_isConfidence() {
        assertEquals("confidence", engine.name());
    }

    @Test
    void evaluate_noData_returnsZero() {
        UUID sid = UUID.randomUUID();
        when(bulletinRepository.findByStudentIdOrderByAcademicYearDescTrimesterDesc(sid))
                .thenReturn(List.of());
        when(interviewRepository.findByStudentIdOrderByAskedAtDesc(sid)).thenReturn(List.of());
        when(riasecRepository.findByEleveTrackingIdOrderByDatePassationDesc(sid.toString()))
                .thenReturn(List.of());
        when(portfolioRepository.findByEleveTrackingIdOrderByCategorieAscNiveauEstimeDesc(sid.toString()))
                .thenReturn(List.of());
        when(defiReleveRepository.findByEleveTrackingId(sid.toString())).thenReturn(List.of());
        when(badgeDecerneRepository.countByEleveTrackingId(sid.toString())).thenReturn(0);
        when(entretienRepository.findByEleveTrackingIdOrderByCreatedAtDesc(sid.toString())).thenReturn(List.of());

        Engine.Output out = engine.evaluate(sid);
        assertEquals(0.0, out.score());
        assertEquals(0, out.details().get("totalDataPoints"));
    }

    @Test
    void evaluate_withData_computesConfidence() {
        UUID sid = UUID.randomUUID();
        var b1 = mock(BulletinHistory.class); var b2 = mock(BulletinHistory.class); var b3 = mock(BulletinHistory.class);
        var i1 = mock(InterviewResponseHistory.class); var i2 = mock(InterviewResponseHistory.class);
        var r1 = mock(TestRIASECResultat.class);
        var p1 = mock(PortfolioCompetence.class); var p2 = mock(PortfolioCompetence.class);
        var p3 = mock(PortfolioCompetence.class); var p4 = mock(PortfolioCompetence.class);
        var d1 = mock(DefiReleve.class);
        var e1 = mock(SimulationEntretien.class);

        when(bulletinRepository.findByStudentIdOrderByAcademicYearDescTrimesterDesc(sid))
                .thenReturn(List.of(b1, b2, b3));
        when(interviewRepository.findByStudentIdOrderByAskedAtDesc(sid))
                .thenReturn(List.of(i1, i2));
        when(riasecRepository.findByEleveTrackingIdOrderByDatePassationDesc(sid.toString()))
                .thenReturn(List.of(r1));
        when(portfolioRepository.findByEleveTrackingIdOrderByCategorieAscNiveauEstimeDesc(sid.toString()))
                .thenReturn(List.of(p1, p2, p3, p4));
        when(defiReleveRepository.findByEleveTrackingId(sid.toString()))
                .thenReturn(List.of(d1));
        when(badgeDecerneRepository.countByEleveTrackingId(sid.toString())).thenReturn(2);
        when(entretienRepository.findByEleveTrackingIdOrderByCreatedAtDesc(sid.toString()))
                .thenReturn(List.of(e1));

        Engine.Output out = engine.evaluate(sid);
        int expectedDataPoints = 3 + 2 + 1 + 4 + 1 + 2 + 1;
        assertEquals(expectedDataPoints, out.details().get("totalDataPoints"));
        assertEquals(Math.min(1.0, expectedDataPoints / 30.0), out.score(), 0.001);
    }

    @Test
    void evaluate_withRepositoryErrors_fallsBackGracefully() {
        UUID sid = UUID.randomUUID();
        when(bulletinRepository.findByStudentIdOrderByAcademicYearDescTrimesterDesc(sid))
                .thenThrow(new RuntimeException("DB error"));

        when(interviewRepository.findByStudentIdOrderByAskedAtDesc(sid)).thenReturn(List.of());
        when(riasecRepository.findByEleveTrackingIdOrderByDatePassationDesc(sid.toString())).thenReturn(List.of());
        when(portfolioRepository.findByEleveTrackingIdOrderByCategorieAscNiveauEstimeDesc(sid.toString())).thenReturn(List.of());
        when(defiReleveRepository.findByEleveTrackingId(sid.toString())).thenReturn(List.of());
        when(badgeDecerneRepository.countByEleveTrackingId(sid.toString())).thenReturn(0);
        when(entretienRepository.findByEleveTrackingIdOrderByCreatedAtDesc(sid.toString())).thenReturn(List.of());

        Engine.Output out = engine.evaluate(sid);
        assertEquals(0.0, out.score());
    }
}
