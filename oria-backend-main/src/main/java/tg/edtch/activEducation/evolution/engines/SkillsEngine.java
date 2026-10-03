package tg.edtch.activEducation.evolution.engines;

import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import tg.edtch.activEducation.portfolio.domain.entite.PortfolioCompetence;
import tg.edtch.activEducation.portfolio.repository.PortfolioCompetenceRepository;

import java.util.*;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
@Slf4j
public class SkillsEngine implements Engine<UUID, Engine.Output> {

    private final PortfolioCompetenceRepository portfolioRepository;

    @Override
    public String name() {
        return "skills";
    }

    @Override
    public Engine.Output evaluate(UUID studentId) {
        String eleveId = studentId.toString();
        List<PortfolioCompetence> competences = portfolioRepository
                .findByEleveTrackingIdOrderByCategorieAscNiveauEstimeDesc(eleveId);

        if (competences.isEmpty()) {
            return new Engine.Output(0.5,
                    "Aucune compétence renseignée dans le portfolio.",
                    Map.of("skillsCount", 0));
        }

        double avgLevel = competences.stream()
                .mapToInt(PortfolioCompetence::getNiveauEstime)
                .average().orElse(1.0);

        Map<String, List<PortfolioCompetence>> byCategory = competences.stream()
                .collect(Collectors.groupingBy(
                        c -> c.getCategorie() != null ? c.getCategorie() : "Autre",
                        LinkedHashMap::new, Collectors.toList()));

        Map<String, Object> categoryStats = new LinkedHashMap<>();
        for (var entry : byCategory.entrySet()) {
            int catCount = entry.getValue().size();
            double catAvg = entry.getValue().stream()
                    .mapToInt(PortfolioCompetence::getNiveauEstime)
                    .average().orElse(1.0);
            Map<String, Object> catInfo = new LinkedHashMap<>();
            catInfo.put("count", catCount);
            catInfo.put("avgLevel", Math.round(catAvg * 100.0) / 100.0);
            categoryStats.put(entry.getKey(), catInfo);
        }

        double score = 0.3 + 0.7 * (avgLevel / 5.0) * Math.min(1.0, competences.size() / 10.0);

        String explanation = String.format(
                "%d compétences dans le portfolio, niveau moyen %.1f/5. Catégories : %s.",
                competences.size(), avgLevel,
                byCategory.keySet().stream().limit(5).collect(Collectors.joining(", ")));

        Map<String, Object> details = new LinkedHashMap<>();
        details.put("skillsCount", competences.size());
        details.put("avgLevel", Math.round(avgLevel * 100.0) / 100.0);
        details.put("categories", categoryStats);

        log.info("SkillsEngine student={} count={} avgLevel={} score={}",
                studentId, competences.size(), avgLevel, score);
        return new Engine.Output(score, explanation, details);
    }
}
