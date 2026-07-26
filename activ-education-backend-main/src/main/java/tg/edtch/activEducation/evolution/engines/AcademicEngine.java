package tg.edtch.activEducation.evolution.engines;

import tg.edtch.activEducation.evolution.domain.entite.BulletinHistory;
import tg.edtch.activEducation.evolution.domain.repository.BulletinHistoryRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.util.*;

/**
 * Academic Engine.
 *
 * <p>Évalue la performance scolaire d'un élève à partir de ses bulletins
 * trimestriels officiels (table {@code evolution_bulletin_history}).</p>
 *
 * <p>Calcule :</p>
 * <ul>
 *   <li>Moyenne générale pondérée par récence</li>
 *   <li>Tendance (progression / régression) sur 3 derniers bulletins</li>
 *   <li>Stabilité (écart-type des notes)</li>
 *   <li>Top 3 matières fortes, Top 3 matières faibles</li>
 * </ul>
 *
 * <p>Retourne un score 0-1.</p>
 */
@Service
@RequiredArgsConstructor
@Slf4j
public class AcademicEngine implements Engine<UUID, Engine.Output> {

    private final BulletinHistoryRepository bulletinRepository;

    @Override
    public String name() {
        return "academic";
    }

    @Override
    public Engine.Output evaluate(UUID studentId) {
        List<BulletinHistory> bulletins = bulletinRepository
                .findByStudentIdOrderByAcademicYearDescTrimesterDesc(studentId);

        if (bulletins.isEmpty()) {
            return new Engine.Output(
                    0.5, // score neutre par défaut
                    "Aucun bulletin officiel reçu pour l'instant.",
                    Map.of("bulletinsCount", 0));
        }

        double moyenneGenerale = calculMoyennePonderee(bulletins);
        double stabilite = calculStabilite(bulletins);
        double tendance = calculTendance(bulletins);
        List<String> forces = topMatieres(bulletins, true);
        List<String> faiblesses = topMatieres(bulletins, false);

        // Score final = combinaison linéaire
        // - moyenne 50% (ramenée sur 0-1 via /20)
        // - tendance 30% (0.5 si stable, +0.5 si progresse, -0.5 si régresse)
        // - stabilité 20% (0.5 + bonus si stable)
        double scoreMoyenne = moyenneGenerale / 20.0;
        double scoreTendance = 0.5 + (tendance / 20.0); // 0.5 = neutre
        double scoreStabilite = 0.5 + (stabilite / 20.0);

        double score = 0.5 * scoreMoyenne
                + 0.3 * scoreTendance
                + 0.2 * scoreStabilite;
        score = Math.max(0.0, Math.min(1.0, score));

        String explanation = String.format(
                "Moyenne générale %.2f/20. Tendance %s. Stabilité %.2f. "
                        + "Matières fortes : %s. Points à améliorer : %s.",
                moyenneGenerale,
                tendance > 1 ? "en progression" : (tendance < -1 ? "en régression" : "stable"),
                stabilite,
                forces.isEmpty() ? "n/a" : String.join(", ", forces),
                faiblesses.isEmpty() ? "n/a" : String.join(", ", faiblesses));

        Map<String, Object> details = new LinkedHashMap<>();
        details.put("moyenneGenerale", moyenneGenerale);
        details.put("stabilite", stabilite);
        details.put("tendance", tendance);
        details.put("forces", forces);
        details.put("faiblesses", faiblesses);
        details.put("bulletinsCount", bulletins.size());

        log.info("AcademicEngine student={} bulletins={} score={}",
                studentId, bulletins.size(), score);

        return new Engine.Output(score, explanation, details);
    }

    // ─── Méthodes de calcul ──────────────────────────────────────────────

    private double calculMoyennePonderee(List<BulletinHistory> bulletins) {
        // Pondération par récence : le dernier bulletin compte 3x, l'avant-dernier 2x, etc.
        // On groupe par (year, trimester) et on calcule la moyenne du bulletin.
        // Plus simple : moyenne arithmétique pour l'instant.
        double sum = 0;
        for (BulletinHistory b : bulletins) {
            sum += b.getGrade().doubleValue();
        }
        return round(sum / bulletins.size());
    }

    private double calculStabilite(List<BulletinHistory> bulletins) {
        // Écart-type des notes (inversé : 20 - écart-type)
        // Plus l'écart-type est faible, plus la note de stabilité est élevée.
        if (bulletins.size() < 2) return 10.0;
        double mean = bulletins.stream()
                .mapToDouble(b -> b.getGrade().doubleValue())
                .average().orElse(10.0);
        double variance = bulletins.stream()
                .mapToDouble(b -> Math.pow(b.getGrade().doubleValue() - mean, 2))
                .average().orElse(0);
        double stdDev = Math.sqrt(variance);
        return round(20.0 - stdDev); // plus c'est stable, plus c'est proche de 20
    }

    private double calculTendance(List<BulletinHistory> bulletins) {
        // Compare la moyenne des 3 derniers bulletins vs les 3 précédents
        if (bulletins.size() < 6) return 0.0;
        List<BulletinHistory> sorted = new ArrayList<>(bulletins);
        double recent = sorted.subList(0, 3).stream()
                .mapToDouble(b -> b.getGrade().doubleValue()).average().orElse(0);
        double ancien = sorted.subList(3, 6).stream()
                .mapToDouble(b -> b.getGrade().doubleValue()).average().orElse(0);
        return round(recent - ancien);
    }

    private List<String> topMatieres(List<BulletinHistory> bulletins, boolean meilleures) {
        // Groupe par matière, calcule la moyenne, trie.
        Map<String, Double> moyenneParMatiere = new HashMap<>();
        Map<String, Integer> countParMatiere = new HashMap<>();
        for (BulletinHistory b : bulletins) {
            String subj = b.getSubject();
            moyenneParMatiere.merge(subj, b.getGrade().doubleValue(), Double::sum);
            countParMatiere.merge(subj, 1, Integer::sum);
        }
        Map<String, Double> moyennes = new HashMap<>();
        moyenneParMatiere.forEach((k, v) -> moyennes.put(k, v / countParMatiere.get(k)));

        return moyennes.entrySet().stream()
                .sorted((a, b) -> meilleures
                        ? Double.compare(b.getValue(), a.getValue())
                        : Double.compare(a.getValue(), b.getValue()))
                .limit(3)
                .map(Map.Entry::getKey)
                .toList();
    }

    private double round(double v) {
        return BigDecimal.valueOf(v).setScale(2, RoundingMode.HALF_UP).doubleValue();
    }
}
