package tg.edtch.activEducation.evolution.engines;

import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import tg.edtch.activEducation.evolution.domain.entite.InterviewResponseHistory;
import tg.edtch.activEducation.evolution.domain.repository.InterviewResponseHistoryRepository;
import tg.edtch.activEducation.shared.ai.domain.entite.ProfilOrientation;
import tg.edtch.activEducation.shared.ai.repository.ProfilOrientationRepository;

import java.util.*;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
@Slf4j
public class InterestEngine implements Engine<UUID, Engine.Output> {

    private final InterviewResponseHistoryRepository interviewRepository;
    private final ProfilOrientationRepository profilOrientationRepository;

    private static final Set<String> INTEREST_QUESTIONS = Set.of(
            "passion_top_1", "passion_top_2", "passion_top_3",
            "centre_interet", "hobbies", "matiere_preferee",
            "ambition_professionnelle", "dream_job");

    @Override
    public String name() {
        return "interest";
    }

    @Override
    public Engine.Output evaluate(UUID studentId) {
        String studentIdStr = studentId.toString();
        List<String> interests = new ArrayList<>();

        var interviews = interviewRepository.findByStudentIdOrderByAskedAtDesc(studentId);
        for (var iv : interviews) {
            if (INTEREST_QUESTIONS.contains(iv.getQuestionId())) {
                Object value = iv.getResponse().get("value");
                if (value != null) {
                    interests.add(value.toString().trim().toLowerCase());
                }
            }
        }

        var profilOpt = profilOrientationRepository.findByUserId(studentIdStr);
        profilOpt.ifPresent(p -> {
            if (p.getDomainesInteret() != null && !p.getDomainesInteret().isBlank()) {
                interests.addAll(Arrays.asList(p.getDomainesInteret().split(",\\s*")));
            }
            if (p.getPremiereAmbition() != null && !p.getPremiereAmbition().isBlank()) {
                interests.addAll(Arrays.asList(p.getPremiereAmbition().split(",\\s*")));
            }
        });

        if (interests.isEmpty()) {
            return new Engine.Output(0.5, "Aucun intérêt recueilli (entretien ORIA non commencé).", Map.of("interests", List.of(), "count", 0));
        }

        Map<String, Long> frequency = interests.stream()
                .collect(Collectors.groupingBy(i -> i, Collectors.counting()));
        List<String> top3 = frequency.entrySet().stream()
                .sorted(Map.Entry.<String, Long>comparingByValue().reversed())
                .limit(3)
                .map(Map.Entry::getKey)
                .toList();

        double score = Math.min(1.0, 0.3 + (frequency.size() / 10.0));

        String explanation = String.format(
                "Centres d'intérêt identifiés : %s (%d mentions).",
                String.join(", ", top3), interests.size());

        Map<String, Object> details = new LinkedHashMap<>();
        details.put("top3", top3);
        details.put("totalMentions", interests.size());
        details.put("uniqueTopics", frequency.size());

        log.info("InterestEngine student={} top3={} score={}", studentId, top3, score);
        return new Engine.Output(score, explanation, details);
    }
}
