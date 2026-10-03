package tg.edtch.activEducation.evolution.application.service;

import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import tg.edtch.activEducation.evolution.domain.entite.StudentEvolutionProfile;
import tg.edtch.activEducation.evolution.domain.repository.StudentEvolutionProfileRepository;
import tg.edtch.activEducation.evolution.engines.Engine;

import java.util.List;
import java.util.Map;
import java.util.Optional;
import java.util.UUID;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.ArgumentMatchers.*;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
class StudentEvolutionServiceTest {

    @Mock
    private StudentEvolutionProfileRepository profileRepository;

    @Mock
    private Engine<UUID, Engine.Output> academicEngine;

    private StudentEvolutionService service;
    private List<Engine<UUID, Engine.Output>> engines;

    @BeforeEach
    void setUp() {
        lenient().when(academicEngine.name()).thenReturn("academic");
        engines = List.of(academicEngine);
        service = new StudentEvolutionService(profileRepository, engines);
    }

    @Test
    void compute_withNewStudent_createsProfile() {
        UUID studentId = UUID.randomUUID();
        Engine.Output academicOutput = new Engine.Output(
                0.75, "Bon niveau général", Map.of("bulletinsCount", 3));
        when(academicEngine.evaluate(studentId)).thenReturn(academicOutput);
        when(profileRepository.findByStudentId(studentId)).thenReturn(Optional.empty());
        when(profileRepository.save(any(StudentEvolutionProfile.class))).thenAnswer(inv -> inv.getArgument(0));

        StudentEvolutionProfile profile = service.compute(studentId);

        assertEquals(1, profile.getVersion());
        assertEquals(studentId, profile.getStudentId());
        assertNotNull(profile.getPayload());
        assertEquals(studentId.toString(), profile.getPayload().get("studentId").toString());
    }

    @Test
    void compute_withExistingProfile_incrementsVersion() {
        UUID studentId = UUID.randomUUID();
        Engine.Output academicOutput = new Engine.Output(
                0.80, "Excellent", Map.of("bulletinsCount", 5));
        when(academicEngine.evaluate(studentId)).thenReturn(academicOutput);
        when(profileRepository.findByStudentId(studentId)).thenReturn(Optional.of(
                StudentEvolutionProfile.builder()
                        .studentId(studentId)
                        .version(3)
                        .payload(Map.of())
                        .build()));
        when(profileRepository.save(any(StudentEvolutionProfile.class))).thenAnswer(inv -> inv.getArgument(0));

        StudentEvolutionProfile profile = service.compute(studentId);

        assertEquals(4, profile.getVersion());
    }

    @Test
    void get_withNoProfile_throws() {
        UUID studentId = UUID.randomUUID();
        when(profileRepository.findByStudentId(studentId)).thenReturn(Optional.empty());

        assertThrows(IllegalArgumentException.class, () -> service.get(studentId));
    }

    @Test
    void get_withExistingProfile_returnsIt() {
        UUID studentId = UUID.randomUUID();
        StudentEvolutionProfile existing = StudentEvolutionProfile.builder()
                .studentId(studentId)
                .version(2)
                .payload(Map.of("academic", Map.of("score", 0.75)))
                .build();
        when(profileRepository.findByStudentId(studentId)).thenReturn(Optional.of(existing));

        StudentEvolutionProfile profile = service.get(studentId);
        assertEquals(2, profile.getVersion());
    }

    @Test
    void compute_includesAcademicDataInPayload() {
        UUID studentId = UUID.randomUUID();
        Engine.Output academicOutput = new Engine.Output(
                0.65, "Moyenne en progrès", Map.of("moyenneGenerale", 13.0, "bulletinsCount", 4));
        when(academicEngine.evaluate(studentId)).thenReturn(academicOutput);
        when(profileRepository.findByStudentId(studentId)).thenReturn(Optional.empty());
        when(profileRepository.save(any(StudentEvolutionProfile.class))).thenAnswer(inv -> inv.getArgument(0));

        StudentEvolutionProfile profile = service.compute(studentId);

        @SuppressWarnings("unchecked")
        Map<String, Object> academic = (Map<String, Object>) profile.getPayload().get("academic");
        assertNotNull(academic);
        assertEquals(0.65, (Double) academic.get("score"), 0.001);
        assertEquals("Moyenne en progrès", academic.get("explanation"));
    }
}
