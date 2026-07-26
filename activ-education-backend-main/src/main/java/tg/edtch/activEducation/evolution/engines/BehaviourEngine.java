package tg.edtch.activEducation.evolution.engines;

import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import tg.edtch.activEducation.badge.repository.BadgeDecerneRepository;
import tg.edtch.activEducation.defis.repository.DefiReleveRepository;
import tg.edtch.activEducation.entretien.repository.SimulationEntretienRepository;

import java.util.LinkedHashMap;
import java.util.Map;
import java.util.UUID;

@Service
@RequiredArgsConstructor
@Slf4j
public class BehaviourEngine implements Engine<UUID, Engine.Output> {

    private final DefiReleveRepository defiReleveRepository;
    private final BadgeDecerneRepository badgeDecerneRepository;
    private final SimulationEntretienRepository entretienRepository;

    @Override
    public String name() {
        return "behaviour";
    }

    @Override
    public Engine.Output evaluate(UUID studentId) {
        String eleveId = studentId.toString();

        int defisCount = 0;
        try {
            defisCount = defiReleveRepository.findByEleveTrackingId(eleveId).size();
        } catch (Exception ex) {
            log.warn("BehaviourEngine: defis lookup failed for {}", studentId);
        }

        int badgesCount = 0;
        try {
            badgesCount = badgeDecerneRepository.countByEleveTrackingId(eleveId);
        } catch (Exception ex) {
            log.warn("BehaviourEngine: badges lookup failed for {}", studentId);
        }

        int interviewsCount = 0;
        try {
            interviewsCount = entretienRepository.findByEleveTrackingIdOrderByCreatedAtDesc(eleveId).size();
        } catch (Exception ex) {
            log.warn("BehaviourEngine: interviews lookup failed for {}", studentId);
        }

        int totalActions = defisCount + badgesCount + interviewsCount;
        double score = Math.min(1.0, totalActions / 50.0);

        String explanation = String.format(
                "Engagement : %d défis, %d badges, %d entretiens.",
                defisCount, badgesCount, interviewsCount);

        Map<String, Object> details = new LinkedHashMap<>();
        details.put("defisCount", defisCount);
        details.put("badgesCount", badgesCount);
        details.put("interviewsCount", interviewsCount);
        details.put("totalActions", totalActions);

        log.info("BehaviourEngine student={} actions={} score={}", studentId, totalActions, score);
        return new Engine.Output(score, explanation, details);
    }
}
