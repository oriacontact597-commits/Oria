package tg.edtch.activEducation.evolution.engines;

import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;

import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.UUID;

@Service
@Slf4j
public class ExplainabilityEngine implements Engine<Map<String, Engine.Output>, Engine.Output> {

    @Override
    public String name() {
        return "explainability";
    }

    @Override
    public Engine.Output evaluate(Map<String, Engine.Output> allEngineOutputs) {
        if (allEngineOutputs == null || allEngineOutputs.isEmpty()) {
            return new Engine.Output(1.0,
                    "Aucun moteur évalué.",
                    Map.of("summary", "Pas de données disponibles."));
        }

        double overallScore = allEngineOutputs.values().stream()
                .mapToDouble(Engine.Output::score)
                .average().orElse(0.5);

        var sorted = allEngineOutputs.entrySet().stream()
                .sorted(Map.Entry.<String, Engine.Output>comparingByValue(
                        (a, b) -> Double.compare(b.score(), a.score())))
                .toList();

        String best = sorted.isEmpty() ? "aucun" : sorted.get(0).getKey();
        String worst = sorted.isEmpty() ? "aucun" : sorted.get(sorted.size() - 1).getKey();

        StringBuilder summary = new StringBuilder();
        summary.append("Résumé du profil élève :\n");
        for (var entry : sorted) {
            String name = entry.getKey();
            Engine.Output out = entry.getValue();
            summary.append(String.format("- %s : %.0f/100 — %s%n",
                    capitalize(name), out.score() * 100, truncate(out.explanation(), 80)));
        }
        summary.append(String.format("\nPoint fort : %s. Point à améliorer : %s.", best, worst));

        String explanation = String.format(
                "Profil multi-dimensions évalué sur %d moteurs. " +
                "Meilleur : %s (%.0f/100). Point faible : %s (%.0f/100).",
                allEngineOutputs.size(),
                best, getScore(sorted, 0),
                worst, getScore(sorted, sorted.size() - 1));

        Map<String, Object> details = new LinkedHashMap<>();
        details.put("summary", summary.toString());
        details.put("enginesCount", allEngineOutputs.size());
        details.put("bestEngine", best);
        details.put("worstEngine", worst);
        details.put("overallScore", Math.round(overallScore * 100.0) / 100.0);

        log.info("ExplainabilityEngine engines={} best={} worst={}",
                allEngineOutputs.size(), best, worst);

        return new Engine.Output(overallScore, explanation, details);
    }

    private double getScore(List<Map.Entry<String, Engine.Output>> sorted, int idx) {
        if (idx < 0 || idx >= sorted.size()) return 0;
        return sorted.get(idx).getValue().score() * 100;
    }

    private static String capitalize(String s) {
        if (s == null || s.isBlank()) return s;
        return Character.toUpperCase(s.charAt(0)) + s.substring(1);
    }

    private static String truncate(String s, int max) {
        if (s == null) return "";
        return s.length() <= max ? s : s.substring(0, max) + "...";
    }
}
