package tg.edtch.activEducation.evolution.engines;

import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import tg.edtch.activEducation.evolution.domain.entite.InterviewResponseHistory;
import tg.edtch.activEducation.evolution.domain.repository.InterviewResponseHistoryRepository;
import tg.edtch.activEducation.shared.ai.domain.entite.ProfilOrientation;
import tg.edtch.activEducation.shared.ai.repository.ProfilOrientationRepository;

import java.util.List;
import java.util.Map;
import java.util.Optional;
import java.util.UUID;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
class InterestEngineTest {

    @Mock
    private InterviewResponseHistoryRepository interviewRepository;
    @Mock
    private ProfilOrientationRepository profilOrientationRepository;

    private InterestEngine engine;

    @BeforeEach
    void setUp() {
        engine = new InterestEngine(interviewRepository, profilOrientationRepository);
    }

    @Test
    void name_isInterest() {
        assertEquals("interest", engine.name());
    }

    @Test
    void evaluate_noInterviewsOrProfil_returnsNeutral() {
        UUID sid = UUID.randomUUID();
        when(interviewRepository.findByStudentIdOrderByAskedAtDesc(sid)).thenReturn(List.of());
        when(profilOrientationRepository.findByUserId(sid.toString())).thenReturn(Optional.empty());

        Engine.Output out = engine.evaluate(sid);
        assertEquals(0.5, out.score());
        assertTrue(out.explanation().contains("Aucun intérêt"));
    }

    @Test
    void evaluate_withInterviewInterests_returnsScore() {
        UUID sid = UUID.randomUUID();
        var iv = InterviewResponseHistory.builder()
                .questionId("passion_top_1")
                .response(Map.of("value", "informatique"))
                .build();
        when(interviewRepository.findByStudentIdOrderByAskedAtDesc(sid))
                .thenReturn(List.of(iv));
        when(profilOrientationRepository.findByUserId(sid.toString())).thenReturn(Optional.empty());

        Engine.Output out = engine.evaluate(sid);
        assertTrue(out.score() > 0.3);
        assertEquals("informatique", ((List<?>) out.details().get("top3")).get(0));
        assertEquals(1, out.details().get("totalMentions"));
    }

    @Test
    void evaluate_withProfilOrientation_addsDomains() {
        UUID sid = UUID.randomUUID();
        when(interviewRepository.findByStudentIdOrderByAskedAtDesc(sid)).thenReturn(List.of());
        var profil = mock(ProfilOrientation.class);
        when(profil.getDomainesInteret()).thenReturn("santé, éducation");
        when(profil.getPremiereAmbition()).thenReturn("médecin");
        when(profilOrientationRepository.findByUserId(sid.toString())).thenReturn(Optional.of(profil));

        Engine.Output out = engine.evaluate(sid);
        assertTrue(out.score() > 0.3);
        assertEquals(3, out.details().get("totalMentions"));
    }
}
