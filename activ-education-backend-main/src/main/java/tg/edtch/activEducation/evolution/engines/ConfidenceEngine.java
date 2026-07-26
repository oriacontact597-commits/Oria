package tg.edtch.activEducation.evolution.engines;

import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import tg.edtch.activEducation.badge.repository.BadgeDecerneRepository;
import tg.edtch.activEducation.defis.repository.DefiReleveRepository;
import tg.edtch.activEducation.entretien.repository.SimulationEntretienRepository;
import tg.edtch.activEducation.evolution.domain.repository.BulletinHistoryRepository;
import tg.edtch.activEducation.evolution.domain.repository.InterviewResponseHistoryRepository;
import tg.edtch.activEducation.portfolio.repository.PortfolioCompetenceRepository;
import tg.edtch.activEducation.riasec.repository.TestRIASECResultatRepository;

import java.util.LinkedHashMap;
import java.util.Map;
import java.util.UUID;

@Service
@RequiredArgsConstructor
@Slf4j
public class ConfidenceEngine implements Engine<UUID, Engine.Output> {

    private final BulletinHistoryRepository bulletinRepository;
    private final InterviewResponseHistoryRepository interviewRepository;
    private final TestRIASECResultatRepository riasecRepository;
    private final PortfolioCompetenceRepository portfolioRepository;
    private final DefiReleveRepository defiReleveRepository;
    private final BadgeDecerneRepository badgeDecerneRepository;
    private final SimulationEntretienRepository entretienRepository;

    @Override
    public String name() {
        return "confidence";
    }

    @Override
    public Engine.Output evaluate(UUID studentId) {
        String eleveId = studentId.toString();

        int bulletinsCount = 0;
        try {
            bulletinsCount = bulletinRepository
                    .findByStudentIdOrderByAcademicYearDescTrimesterDesc(studentId).size();
        } catch (Exception e) {
            // ignore
        }

        int interviewsCount = 0;
        try {
            interviewsCount = interviewRepository.findByStudentIdOrderByAskedAtDesc(studentId).size();
        } catch (Exception e) {
            // ignore
        }

        int riasecTests = 0;
        try {
            riasecTests = riasecRepository.findByEleveTrackingIdOrderByDatePassationDesc(eleveId).size();
        } catch (Exception e) {
            // ignore
        }

        int skillsCount = 0;
        try {
            skillsCount = portfolioRepository.findByEleveTrackingIdOrderByCategorieAscNiveauEstimeDesc(eleveId).size();
        } catch (Exception e) {
            // ignore
        }

        int defisCount = 0;
        try {
            defisCount = defiReleveRepository.findByEleveTrackingId(eleveId).size();
        } catch (Exception e) {
            // ignore
        }

        int badgesCount = 0;
        try {
            badgesCount = badgeDecerneRepository.countByEleveTrackingId(eleveId);
        } catch (Exception e) {
            // ignore
        }

        int entretiensCount = 0;
        try {
            entretiensCount = entretienRepository.findByEleveTrackingIdOrderByCreatedAtDesc(eleveId).size();
        } catch (Exception e) {
            // ignore
        }

        int totalDataPoints = bulletinsCount + interviewsCount + riasecTests
                + skillsCount + defisCount + badgesCount + entretiensCount;

        double score = Math.min(1.0, totalDataPoints / 30.0);

        String explanation = String.format(
                "Fiabilité basée sur %d points de données : %d bulletins, %d entretiens ORIA, "
                + "%d tests RIASEC, %d compétences, %d défis, %d badges, %d simulations.",
                totalDataPoints, bulletinsCount, interviewsCount, riasecTests,
                skillsCount, defisCount, badgesCount, entretiensCount);

        Map<String, Object> details = new LinkedHashMap<>();
        details.put("totalDataPoints", totalDataPoints);
        details.put("bulletinsCount", bulletinsCount);
        details.put("interviewsCount", interviewsCount);
        details.put("riasecTests", riasecTests);
        details.put("skillsCount", skillsCount);
        details.put("defisCount", defisCount);
        details.put("badgesCount", badgesCount);
        details.put("entretiensCount", entretiensCount);

        log.info("ConfidenceEngine student={} dataPoints={} score={}", studentId, totalDataPoints, score);
        return new Engine.Output(score, explanation, details);
    }
}
