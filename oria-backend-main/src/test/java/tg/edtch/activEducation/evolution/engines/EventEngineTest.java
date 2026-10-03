package tg.edtch.activEducation.evolution.engines;

import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import tg.edtch.activEducation.evolution.domain.entite.BulletinHistory;
import tg.edtch.activEducation.evolution.domain.entite.InterviewResponseHistory;
import tg.edtch.activEducation.evolution.domain.repository.BulletinHistoryRepository;
import tg.edtch.activEducation.evolution.domain.repository.InterviewResponseHistoryRepository;

import java.lang.reflect.Field;
import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.*;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
class EventEngineTest {

    @Mock private BulletinHistoryRepository bulletinRepository;
    @Mock private InterviewResponseHistoryRepository interviewRepository;
    @InjectMocks private EventEngine engine;

    @Test
    @DisplayName("name() retourne 'event'")
    void nameIsEvent() {
        assertThat(engine.name()).isEqualTo("event");
    }

    @Test
    @DisplayName("Aucun bulletin, aucun interview → INACTIVITE LOW détecté (pas d'interaction)")
    void emptyDataOnlyInactivite() {
        when(bulletinRepository.findByStudentIdOrderByAcademicYearDescTrimesterDesc(any(UUID.class)))
                .thenReturn(List.of());
        when(interviewRepository.findByStudentIdOrderByAskedAtDesc(any(UUID.class)))
                .thenReturn(List.of());

        Engine.Output out = engine.evaluate(UUID.randomUUID());

        List<Map<String, Object>> events = (List<Map<String, Object>>) out.details().get("events");
        assertThat(events).isNotEmpty();
        assertThat(events).anyMatch(e -> "INACTIVITE".equals(e.get("type")));
        assertThat(out.score()).isBetween(0.0, 1.0);
    }

    @Test
    @DisplayName("Inactivité > 14j → événement INACTIVITE détecté")
    void inactiviteDetected() throws Exception {
        when(bulletinRepository.findByStudentIdOrderByAcademicYearDescTrimesterDesc(any(UUID.class)))
                .thenReturn(List.of(makeBulletin("Math", 12.0, "2024-2025", 1)));
        when(interviewRepository.findByStudentIdOrderByAskedAtDesc(any(UUID.class)))
                .thenReturn(List.of(makeInterview(LocalDateTime.now().minusDays(30))));

        Engine.Output out = engine.evaluate(UUID.randomUUID());

        List<Map<String, Object>> events = (List<Map<String, Object>>) out.details().get("events");
        assertThat(events).anyMatch(e -> "INACTIVITE".equals(e.get("type")));
    }

    @Test
    @DisplayName("Interview récente (< 14j) + bulletin récent → pas d'inactivité")
    void noInactiviteSiRecent() throws Exception {
        when(bulletinRepository.findByStudentIdOrderByAcademicYearDescTrimesterDesc(any(UUID.class)))
                .thenReturn(List.of(makeBulletin("Math", 12.0, "2024-2025", 1)));
        when(interviewRepository.findByStudentIdOrderByAskedAtDesc(any(UUID.class)))
                .thenReturn(List.of(makeInterview(LocalDateTime.now().minusDays(2))));

        Engine.Output out = engine.evaluate(UUID.randomUUID());

        List<Map<String, Object>> events = (List<Map<String, Object>>) out.details().get("events");
        assertThat(events).noneMatch(e -> "INACTIVITE".equals(e.get("type")));
    }

    @Test
    @DisplayName("Progression moyenne +2pts sur 2 trimestres → événement PROGRESSION")
    void progressionDetected() throws Exception {
        when(bulletinRepository.findByStudentIdOrderByAcademicYearDescTrimesterDesc(any(UUID.class)))
                .thenReturn(List.of(
                        makeBulletin("Math", 13.0, "2024-2025", 2),
                        makeBulletin("Math", 10.0, "2024-2025", 1),
                        makeBulletin("Français", 12.0, "2024-2025", 2),
                        makeBulletin("Français", 10.0, "2024-2025", 1)));
        when(interviewRepository.findByStudentIdOrderByAskedAtDesc(any(UUID.class)))
                .thenReturn(List.of(makeInterview(LocalDateTime.now().minusDays(1))));

        Engine.Output out = engine.evaluate(UUID.randomUUID());

        List<Map<String, Object>> events = (List<Map<String, Object>>) out.details().get("events");
        assertThat(events).anyMatch(e -> "PROGRESSION".equals(e.get("type")));
    }

    @Test
    @DisplayName("Régression moyenne -2pts sur 2 trimestres → événement REGRESSION")
    void regressionDetected() throws Exception {
        when(bulletinRepository.findByStudentIdOrderByAcademicYearDescTrimesterDesc(any(UUID.class)))
                .thenReturn(List.of(
                        makeBulletin("Math", 11.0, "2024-2025", 2),
                        makeBulletin("Math", 14.0, "2024-2025", 1),
                        makeBulletin("Français", 12.0, "2024-2025", 2),
                        makeBulletin("Français", 14.0, "2024-2025", 1)));
        when(interviewRepository.findByStudentIdOrderByAskedAtDesc(any(UUID.class)))
                .thenReturn(List.of(makeInterview(LocalDateTime.now().minusDays(1))));

        Engine.Output out = engine.evaluate(UUID.randomUUID());

        List<Map<String, Object>> events = (List<Map<String, Object>>) out.details().get("events");
        assertThat(events).anyMatch(e -> "REGRESSION".equals(e.get("type")));
    }

    @Test
    @DisplayName("Moyenne ≥ 14 sur dernier trimestre → PALIER_ATTEINT")
    void palierDetected() throws Exception {
        when(bulletinRepository.findByStudentIdOrderByAcademicYearDescTrimesterDesc(any(UUID.class)))
                .thenReturn(List.of(
                        makeBulletin("Math", 15.0, "2024-2025", 1),
                        makeBulletin("Français", 14.0, "2024-2025", 1),
                        makeBulletin("Anglais", 13.5, "2024-2025", 1)));
        when(interviewRepository.findByStudentIdOrderByAskedAtDesc(any(UUID.class)))
                .thenReturn(List.of(makeInterview(LocalDateTime.now().minusDays(1))));

        Engine.Output out = engine.evaluate(UUID.randomUUID());

        List<Map<String, Object>> events = (List<Map<String, Object>>) out.details().get("events");
        assertThat(events).anyMatch(e -> "PALIER_ATTEINT".equals(e.get("type")));
    }

    @Test
    @DisplayName("Progression forte d'une matière (≥ +2pts) → NOUVELLE_FORCE")
    void nouvelleForceDetected() throws Exception {
        when(bulletinRepository.findByStudentIdOrderByAcademicYearDescTrimesterDesc(any(UUID.class)))
                .thenReturn(List.of(
                        makeBulletin("Math", 13.0, "2024-2025", 2),
                        makeBulletin("Math", 10.0, "2024-2025", 1),
                        makeBulletin("Français", 12.5, "2024-2025", 2),
                        makeBulletin("Français", 12.0, "2024-2025", 1)));
        when(interviewRepository.findByStudentIdOrderByAskedAtDesc(any(UUID.class)))
                .thenReturn(List.of(makeInterview(LocalDateTime.now().minusDays(1))));

        Engine.Output out = engine.evaluate(UUID.randomUUID());

        List<Map<String, Object>> events = (List<Map<String, Object>>) out.details().get("events");
        // Math: 10 → 13 = +3 = force ; Français: 12 → 12.5 = +0.5 = rien
        assertThat(events).anyMatch(e -> "NOUVELLE_FORCE".equals(e.get("type"))
                && ((String) e.get("message")).contains("Math"));
        assertThat(events).noneMatch(e -> "NOUVELLE_FAIBLESSE".equals(e.get("type")));
    }

    @Test
    @DisplayName("Régression forte d'une matière (≤ -2pts) → NOUVELLE_FAIBLESSE")
    void nouvelleFaiblesseDetected() throws Exception {
        when(bulletinRepository.findByStudentIdOrderByAcademicYearDescTrimesterDesc(any(UUID.class)))
                .thenReturn(List.of(
                        makeBulletin("Math", 14.0, "2024-2025", 2),
                        makeBulletin("Math", 16.0, "2024-2025", 1),
                        makeBulletin("Français", 12.0, "2024-2025", 2),
                        makeBulletin("Français", 11.5, "2024-2025", 1)));
        when(interviewRepository.findByStudentIdOrderByAskedAtDesc(any(UUID.class)))
                .thenReturn(List.of(makeInterview(LocalDateTime.now().minusDays(1))));

        Engine.Output out = engine.evaluate(UUID.randomUUID());

        List<Map<String, Object>> events = (List<Map<String, Object>>) out.details().get("events");
        assertThat(events).anyMatch(e -> "NOUVELLE_FAIBLESSE".equals(e.get("type"))
                && ((String) e.get("message")).contains("Math"));
    }

    @Test
    @DisplayName("Score borné entre 0 et 1 même avec beaucoup d'événements HIGH")
    void scoreClampedToOne() throws Exception {
        when(bulletinRepository.findByStudentIdOrderByAcademicYearDescTrimesterDesc(any(UUID.class)))
                .thenReturn(List.of(
                        makeBulletin("Math", 8.0, "2024-2025", 2),
                        makeBulletin("Math", 10.0, "2024-2025", 1),
                        makeBulletin("Français", 7.5, "2024-2025", 2),
                        makeBulletin("Français", 10.0, "2024-2025", 1)));
        when(interviewRepository.findByStudentIdOrderByAskedAtDesc(any(UUID.class)))
                .thenReturn(List.of(makeInterview(LocalDateTime.now().minusDays(60))));

        Engine.Output out = engine.evaluate(UUID.randomUUID());

        assertThat(out.score()).isBetween(0.0, 1.0);
    }

    // ────────────────────────── Helpers ──────────────────────────

    private static BulletinHistory makeBulletin(String subject, double grade,
                                                String year, int trimester) throws Exception {
        BulletinHistory b = new BulletinHistory();
        setField(b, "subject", subject);
        setField(b, "grade", BigDecimal.valueOf(grade));
        setField(b, "academicYear", year);
        setField(b, "trimester", trimester);
        setField(b, "studentId", UUID.randomUUID());
        return b;
    }

    private static InterviewResponseHistory makeInterview(LocalDateTime askedAt) throws Exception {
        InterviewResponseHistory i = new InterviewResponseHistory();
        setField(i, "askedAt", askedAt);
        setField(i, "studentId", UUID.randomUUID());
        setField(i, "interviewSessionId", UUID.randomUUID());
        setField(i, "questionId", "Q1");
        setField(i, "context", "ORIENTATION");
        return i;
    }

    private static void setField(Object target, String name, Object value) throws Exception {
        Field f = target.getClass().getDeclaredField(name);
        f.setAccessible(true);
        f.set(target, value);
    }
}
