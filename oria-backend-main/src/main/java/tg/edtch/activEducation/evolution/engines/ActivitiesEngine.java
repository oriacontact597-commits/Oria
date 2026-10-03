package tg.edtch.activEducation.evolution.engines;

import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import tg.edtch.activEducation.defis.domain.entite.DefiReleve;
import tg.edtch.activEducation.defis.repository.DefiReleveRepository;

import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.UUID;

@Service
@RequiredArgsConstructor
@Slf4j
public class ActivitiesEngine implements Engine<UUID, Engine.Output> {

    private final DefiReleveRepository defiReleveRepository;

    @Override
    public String name() {
        return "activities";
    }

    @Override
    public Engine.Output evaluate(UUID studentId) {
        String eleveId = studentId.toString();
        List<DefiReleve> releves = defiReleveRepository.findByEleveTrackingId(eleveId);

        if (releves.isEmpty()) {
            return new Engine.Output(0.5,
                    "Aucune activité extra-scolaire recensée.",
                    Map.of("activitiesCount", 0));
        }

        long completedCount = releves.stream()
                .filter(r -> "TERMINE".equalsIgnoreCase(r.getStatut()))
                .count();
        long inProgressCount = releves.stream()
                .filter(r -> "EN_COURS".equalsIgnoreCase(r.getStatut()))
                .count();

        int totalWeight = releves.size()
                + (int) completedCount * 2;
        double score = Math.min(1.0, totalWeight / 20.0);

        String explanation = String.format(
                "%d activités (%d terminées, %d en cours).",
                releves.size(), completedCount, inProgressCount);

        Map<String, Object> details = new LinkedHashMap<>();
        details.put("activitiesCount", releves.size());
        details.put("completedCount", completedCount);
        details.put("inProgressCount", inProgressCount);

        log.info("ActivitiesEngine student={} count={} score={}", studentId, releves.size(), score);
        return new Engine.Output(score, explanation, details);
    }
}
