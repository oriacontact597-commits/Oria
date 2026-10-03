package tg.edtch.activEducation.evolution.engines;

import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import tg.edtch.activEducation.evolution.domain.entite.BulletinHistory;
import tg.edtch.activEducation.evolution.domain.entite.InterviewResponseHistory;
import tg.edtch.activEducation.evolution.domain.repository.BulletinHistoryRepository;
import tg.edtch.activEducation.evolution.domain.repository.InterviewResponseHistoryRepository;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.Period;
import java.time.ZoneId;
import java.time.temporal.ChronoUnit;
import java.util.*;

/**
 * EventEngine — détecte des événements proactifs sur le profil élève.
 *
 * <p>7 événements détectés :</p>
 * <ol>
 *   <li><b>PROGRESSION</b> — moyenne générale en hausse sur 2 trimestres consécutifs (≥ +1.0 pt)</li>
 *   <li><b>REGRESSION</b> — moyenne générale en baisse sur 2 trimestres consécutifs (≤ -1.0 pt)</li>
 *   <li><b>BAC_APPROCHE</b> — T-6 mois avant le Bac probable (Terminale, ~ juin N+1)</li>
 *   <li><b>INACTIVITE</b> — aucune interaction ORIA depuis > 14 jours</li>
 *   <li><b>NOUVELLE_FORCE</b> — matière avec progression ≥ +2.0 pts sur le dernier trimestre</li>
 *   <li><b>NOUVELLE_FAIBLESSE</b> — matière avec régression ≤ -2.0 pts sur le dernier trimestre</li>
 *   <li><b>PALIER_ATTEINT</b> — moyenne générale ≥ 14/20 sur le dernier trimestre</li>
 * </ol>
 *
 * <p>Le score retourné est une <b>priorité globale</b> (0 = rien à signaler, 1 = action immédiate).
 * Plus il y a d'événements critiques, plus le score est élevé.</p>
 */
@Service
@RequiredArgsConstructor
@Slf4j
public class EventEngine implements Engine<UUID, Engine.Output> {

    private final BulletinHistoryRepository bulletinRepository;
    private final InterviewResponseHistoryRepository interviewRepository;

    private static final double PROGRESSION_THRESHOLD = 1.0;
    private static final double MATIERE_DELTA_THRESHOLD = 2.0;
    private static final double PALIER_MOYENNE = 14.0;
    private static final long INACTIVITE_JOURS = 14;
    private static final int BAC_APPROCHE_MOIS = 6;

    @Override
    public String name() {
        return "event";
    }

    @Override
    public Engine.Output evaluate(UUID studentId) {
        log.info("EventEngine.evaluate({})", studentId);

        List<BulletinHistory> bulletins = safeBulletins(studentId);
        List<InterviewResponseHistory> interviews = safeInterviews(studentId);

        List<Map<String, Object>> events = new ArrayList<>();

        events.add(checkProgression(bulletins));
        events.add(checkRegression(bulletins));
        events.add(checkBacApproche(bulletins));
        events.add(checkInactivite(interviews));
        events.addAll(checkNouvellesForcesFaiblesses(bulletins));
        events.add(checkPalier(bulletins));

        events.removeIf(Objects::isNull);

        double score = computePriority(events);

        String explanation = String.format(
                "%d événement(s) détecté(s) sur le profil.",
                events.size());

        Map<String, Object> details = new LinkedHashMap<>();
        details.put("eventCount", events.size());
        details.put("events", events);
        details.put("checkedAt", System.currentTimeMillis());

        log.info("EventEngine student={} events={} priority={}", studentId, events.size(), score);
        return new Engine.Output(score, explanation, details);
    }

    // ────────────────────────── Détection ──────────────────────────

    private Map<String, Object> checkProgression(List<BulletinHistory> bulletins) {
        Double delta = moyenneTrend(bulletins, 2);
        if (delta != null && delta >= PROGRESSION_THRESHOLD) {
            return event("PROGRESSION", "MEDIUM",
                    "Tes notes progressent (+" + String.format("%.1f", delta) + " pts sur 2 trimestres). Continue !");
        }
        return null;
    }

    private Map<String, Object> checkRegression(List<BulletinHistory> bulletins) {
        Double delta = moyenneTrend(bulletins, 2);
        if (delta != null && delta <= -PROGRESSION_THRESHOLD) {
            return event("REGRESSION", "HIGH",
                    "Tes notes baissent (" + String.format("%.1f", delta) + " pts). Veux-tu qu'on en parle ?");
        }
        return null;
    }

    private Map<String, Object> checkBacApproche(List<BulletinHistory> bulletins) {
        if (bulletins.isEmpty()) {
            return null;
        }
        BulletinHistory latest = bulletins.get(0);
        int currentYear = extractYear(latest.getAcademicYear());
        if (currentYear == 0) {
            return null;
        }
        LocalDate now = LocalDate.now();
        LocalDate bacMonth = LocalDate.of(currentYear + 1, 6, 1);
        long moisAvant = ChronoUnit.MONTHS.between(now, bacMonth);
        if (moisAvant > 0 && moisAvant <= BAC_APPROCHE_MOIS) {
            return event("BAC_APPROCHE", "HIGH",
                    "Le Bac approche (dans " + moisAvant + " mois). On prépare ton dossier ?");
        }
        return null;
    }

    private Map<String, Object> checkInactivite(List<InterviewResponseHistory> interviews) {
        if (interviews.isEmpty()) {
            return event("INACTIVITE", "LOW",
                    "Ça fait un moment ! Reprends où tu en étais avec ORIA.");
        }
        InterviewResponseHistory last = interviews.get(0);
        LocalDateTime askedAt = last.getAskedAt();
        if (askedAt == null) {
            return null;
        }
        long jours = ChronoUnit.DAYS.between(askedAt, LocalDateTime.now());
        if (jours > INACTIVITE_JOURS) {
            return event("INACTIVITE", "MEDIUM",
                    "Tu n'as pas parlé à ORIA depuis " + jours + " jours. Une question ?");
        }
        return null;
    }

    private List<Map<String, Object>> checkNouvellesForcesFaiblesses(List<BulletinHistory> bulletins) {
        List<Map<String, Object>> result = new ArrayList<>();
        Map<String, List<Double>> bySubject = groupBySubject(bulletins);
        for (var entry : bySubject.entrySet()) {
            List<Double> grades = entry.getValue();
            if (grades.size() < 2) continue;
            double latest = grades.get(0);
            double previous = grades.get(1);
            double delta = latest - previous;
            if (delta >= MATIERE_DELTA_THRESHOLD) {
                result.add(event("NOUVELLE_FORCE", "MEDIUM",
                        "Belle progression en " + entry.getKey()
                                + " (+" + String.format("%.1f", delta) + " pts)."));
            } else if (delta <= -MATIERE_DELTA_THRESHOLD) {
                result.add(event("NOUVELLE_FAIBLESSE", "MEDIUM",
                        "Baisse en " + entry.getKey()
                                + " (" + String.format("%.1f", delta) + " pts). On regarde ensemble ?"));
            }
        }
        return result;
    }

    private Map<String, Object> checkPalier(List<BulletinHistory> bulletins) {
        Double latestMoyenne = latestMoyenne(bulletins);
        if (latestMoyenne != null && latestMoyenne >= PALIER_MOYENNE) {
            return event("PALIER_ATTEINT", "LOW",
                    "Bravo ! Moyenne de " + String.format("%.1f", latestMoyenne)
                            + "/20 ce trimestre. Objectif atteint.");
        }
        return null;
    }

    // ────────────────────────── Helpers ──────────────────────────

    private Map<String, Object> event(String type, String severity, String message) {
        Map<String, Object> e = new LinkedHashMap<>();
        e.put("type", type);
        e.put("severity", severity);
        e.put("message", message);
        e.put("detectedAt", System.currentTimeMillis());
        return e;
    }

    /**
     * Calcule la différence de moyenne entre les 2 derniers trimestres disponibles.
     * @return delta (positif = hausse), null si pas assez de données.
     */
    private Double moyenneTrend(List<BulletinHistory> bulletins, int nbTrimestres) {
        if (bulletins.size() < 2) return null;
        Map<String, Double> moyennes = new LinkedHashMap<>();
        for (BulletinHistory b : bulletins) {
            String key = b.getAcademicYear() + "-T" + b.getTrimester();
            moyennes.putIfAbsent(key, moyenne(bulletins, b.getAcademicYear(), b.getTrimester()));
        }
        List<Double> values = new ArrayList<>(moyennes.values());
        if (values.size() < 2) return null;
        int limit = Math.min(nbTrimestres, values.size());
        return values.get(0) - values.get(limit - 1);
    }

    private Double latestMoyenne(List<BulletinHistory> bulletins) {
        if (bulletins.isEmpty()) return null;
        BulletinHistory latest = bulletins.get(0);
        return moyenne(bulletins, latest.getAcademicYear(), latest.getTrimester());
    }

    private double moyenne(List<BulletinHistory> all, String year, int trimester) {
        return all.stream()
                .filter(b -> b.getAcademicYear().equals(year) && b.getTrimester() == trimester)
                .map(b -> b.getGrade().doubleValue())
                .mapToDouble(Double::doubleValue)
                .average()
                .orElse(0.0);
    }

    private Map<String, List<Double>> groupBySubject(List<BulletinHistory> bulletins) {
        Map<String, List<Double>> bySubject = new LinkedHashMap<>();
        for (BulletinHistory b : bulletins) {
            bySubject.computeIfAbsent(b.getSubject(), k -> new ArrayList<>())
                    .add(b.getGrade().doubleValue());
        }
        return bySubject;
    }

    private double computePriority(List<Map<String, Object>> events) {
        if (events.isEmpty()) return 0.0;
        double score = 0.0;
        for (Map<String, Object> e : events) {
            String severity = (String) e.get("severity");
            score += switch (severity) {
                case "HIGH" -> 0.4;
                case "MEDIUM" -> 0.2;
                case "LOW" -> 0.05;
                default -> 0.0;
            };
        }
        return Math.min(1.0, score);
    }

    private int extractYear(String academicYear) {
        if (academicYear == null || academicYear.length() < 4) return 0;
        try {
            return Integer.parseInt(academicYear.substring(0, 4));
        } catch (NumberFormatException e) {
            return 0;
        }
    }

    private List<BulletinHistory> safeBulletins(UUID studentId) {
        try {
            return bulletinRepository
                    .findByStudentIdOrderByAcademicYearDescTrimesterDesc(studentId);
        } catch (Exception e) {
            log.warn("EventEngine: bulletins fetch failed for {}: {}", studentId, e.getMessage());
            return List.of();
        }
    }

    private List<InterviewResponseHistory> safeInterviews(UUID studentId) {
        try {
            return interviewRepository.findByStudentIdOrderByAskedAtDesc(studentId);
        } catch (Exception e) {
            log.warn("EventEngine: interviews fetch failed for {}: {}", studentId, e.getMessage());
            return List.of();
        }
    }
}
