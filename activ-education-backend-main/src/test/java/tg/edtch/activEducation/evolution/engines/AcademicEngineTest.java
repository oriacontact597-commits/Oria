package tg.edtch.activEducation.evolution.engines;

import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import tg.edtch.activEducation.evolution.domain.entite.BulletinHistory;
import tg.edtch.activEducation.evolution.domain.repository.BulletinHistoryRepository;

import java.math.BigDecimal;
import java.util.List;
import java.util.UUID;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
class AcademicEngineTest {

    @Mock
    private BulletinHistoryRepository bulletinRepository;

    private AcademicEngine engine;

    @BeforeEach
    void setUp() {
        engine = new AcademicEngine(bulletinRepository);
    }

    @Test
    void evaluate_withNoBulletins_returnsNeutralScore() {
        UUID studentId = UUID.randomUUID();
        when(bulletinRepository.findByStudentIdOrderByAcademicYearDescTrimesterDesc(studentId))
                .thenReturn(List.of());

        Engine.Output output = engine.evaluate(studentId);

        assertEquals(0.5, output.score());
        assertEquals("Aucun bulletin officiel reçu pour l'instant.", output.explanation());
    }

    @Test
    void evaluate_withSingleBulletin_returnsScore() {
        UUID studentId = UUID.randomUUID();
        when(bulletinRepository.findByStudentIdOrderByAcademicYearDescTrimesterDesc(studentId))
                .thenReturn(List.of(
                        bulletin(studentId, "2024-2025", 1, "Mathématiques", 14.0)));

        Engine.Output output = engine.evaluate(studentId);

        double expected = 0.5 * (14.0 / 20.0) + 0.3 * 0.5 + 0.2 * 1.0;
        assertEquals(expected, output.score(), 0.001);
        assertEquals(1, output.details().get("bulletinsCount"));
    }

    @Test
    void evaluate_withMultipleBulletins_calculatesTrend() {
        UUID studentId = UUID.randomUUID();
        when(bulletinRepository.findByStudentIdOrderByAcademicYearDescTrimesterDesc(studentId))
                .thenReturn(List.of(
                        bulletin(studentId, "2024-2025", 3, "Mathématiques", 16.0),
                        bulletin(studentId, "2024-2025", 2, "Mathématiques", 14.0),
                        bulletin(studentId, "2024-2025", 1, "Mathématiques", 12.0),
                        bulletin(studentId, "2023-2024", 3, "Mathématiques", 10.0),
                        bulletin(studentId, "2023-2024", 2, "Mathématiques", 9.0),
                        bulletin(studentId, "2023-2024", 1, "Mathématiques", 8.0)));

        Engine.Output output = engine.evaluate(studentId);

        assertTrue(output.score() > 0.5, "Score should be above neutral for improving grades");
        assertTrue(output.explanation().contains("progression"));
        assertEquals(6, output.details().get("bulletinsCount"));
    }

    @Test
    void evaluate_withMultipleSubjects_identifiesStrengthsAndWeaknesses() {
        UUID studentId = UUID.randomUUID();
        when(bulletinRepository.findByStudentIdOrderByAcademicYearDescTrimesterDesc(studentId))
                .thenReturn(List.of(
                        bulletin(studentId, "2024-2025", 1, "Mathématiques", 18.0),
                        bulletin(studentId, "2024-2025", 1, "Physique", 16.0),
                        bulletin(studentId, "2024-2025", 1, "Français", 12.0),
                        bulletin(studentId, "2024-2025", 1, "Anglais", 8.0),
                        bulletin(studentId, "2024-2025", 1, "Histoire", 6.0)));

        Engine.Output output = engine.evaluate(studentId);

        @SuppressWarnings("unchecked")
        List<String> forces = (List<String>) output.details().get("forces");
        @SuppressWarnings("unchecked")
        List<String> faiblesses = (List<String>) output.details().get("faiblesses");

        assertTrue(forces.contains("Mathématiques"));
        assertTrue(faiblesses.contains("Histoire"));
    }

    @Test
    void evaluate_scoreIsClampedTo01() {
        UUID studentId = UUID.randomUUID();
        when(bulletinRepository.findByStudentIdOrderByAcademicYearDescTrimesterDesc(studentId))
                .thenReturn(List.of(
                        bulletin(studentId, "2024-2025", 1, "Mathématiques", 0.0)));

        Engine.Output output = engine.evaluate(studentId);
        assertTrue(output.score() >= 0.0 && output.score() <= 1.0);
    }

    @Test
    void engineName_isAcademic() {
        assertEquals("academic", engine.name());
    }

    private static BulletinHistory bulletin(UUID studentId, String year, int trimester, String subject, double grade) {
        return BulletinHistory.builder()
                .studentId(studentId)
                .academicYear(year)
                .trimester(trimester)
                .subject(subject)
                .grade(BigDecimal.valueOf(grade))
                .isOfficial(true)
                .build();
    }
}
