package tg.edtch.activEducation.evolution.application.service;

import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.cache.annotation.CacheEvict;
import org.springframework.cache.annotation.Cacheable;
import org.springframework.stereotype.Service;
import tg.edtch.activEducation.evolution.domain.entite.StudentEvolutionProfile;
import tg.edtch.activEducation.evolution.domain.repository.StudentEvolutionProfileRepository;
import tg.edtch.activEducation.evolution.engines.Engine;

import java.time.LocalDateTime;
import java.util.*;

/**
 * Service principal du Student Evolution Engine.
 * Évalue tous les moteurs (Phase 2) et stocke le SEP complet.
 *
 * <p>Le résultat est mis en cache Redis (TTL 1h) via {@code @Cacheable} :
 * évite de recalculer 9 engines à chaque appel GET.</p>
 */
@Service
@RequiredArgsConstructor
@Slf4j
public class StudentEvolutionService {

    private final StudentEvolutionProfileRepository profileRepository;
    private final List<Engine<UUID, Engine.Output>> engines;

    @CacheEvict(value = "sep", key = "#studentId")
    public StudentEvolutionProfile compute(UUID studentId) {
        log.info("StudentEvolutionService.compute({})", studentId);

        Map<String, Object> payload = new LinkedHashMap<>();
        payload.put("studentId", studentId);
        payload.put("computedAt", LocalDateTime.now());

        List<String> evaluated = new ArrayList<>();
        for (Engine<UUID, Engine.Output> engine : engines) {
            try {
                Engine.Output output = engine.evaluate(studentId);
                payload.put(engine.name(), Map.of(
                        "score", output.score(),
                        "explanation", output.explanation(),
                        "details", output.details()));
                evaluated.add(engine.name());
            } catch (Exception e) {
                log.warn("Engine {} failed for student {}: {}", engine.name(), studentId, e.getMessage());
                payload.put(engine.name(), Map.of(
                        "score", 0.5,
                        "explanation", "Erreur: " + e.getMessage(),
                        "details", Map.of()));
                evaluated.add(engine.name() + "(error)");
            }
        }

        payload.put("enginesEvaluated", evaluated);

        StudentEvolutionProfile profile = profileRepository.findByStudentId(studentId)
                .map(existing -> {
                    existing.setVersion(existing.getVersion() + 1);
                    existing.setComputedAt(LocalDateTime.now());
                    existing.setPayload(payload);
                    return existing;
                })
                .orElseGet(() -> StudentEvolutionProfile.builder()
                        .studentId(studentId)
                        .version(1)
                        .computedAt(LocalDateTime.now())
                        .payload(payload)
                        .build());

        return profileRepository.save(profile);
    }

    @Cacheable(value = "sep", key = "#studentId", unless = "#result == null")
    public StudentEvolutionProfile get(UUID studentId) {
        log.info("StudentEvolutionService.get({}) [DB lookup]", studentId);
        return profileRepository.findByStudentId(studentId)
                .orElseThrow(() -> new IllegalArgumentException(
                        "Profil non trouvé pour studentId=" + studentId
                                + " (appeler compute() d'abord)"));
    }
}

