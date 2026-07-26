package tg.edtch.activEducation.evolution.engines;

import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import tg.edtch.activEducation.riasec.domain.entite.TestRIASECResultat;
import tg.edtch.activEducation.riasec.repository.TestRIASECResultatRepository;

import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.UUID;

@Service
@RequiredArgsConstructor
@Slf4j
public class RIASECEngine implements Engine<UUID, Engine.Output> {

    private final TestRIASECResultatRepository riasecRepository;

    private static final double MAX_RAW_SCORE = 30.0;

    @Override
    public String name() {
        return "riasec";
    }

    @Override
    public Engine.Output evaluate(UUID studentId) {
        String eleveId = studentId.toString();
        List<TestRIASECResultat> results = riasecRepository
                .findByEleveTrackingIdOrderByDatePassationDesc(eleveId);

        if (results.isEmpty()) {
            return new Engine.Output(0.5,
                    "Aucun test RIASEC complété. L'élève n'a pas encore évalué ses centres d'intérêt professionnels.",
                    Map.of("testsCount", 0));
        }

        TestRIASECResultat latest = results.get(0);

        int r = latest.getScoreRealiste() != null ? latest.getScoreRealiste() : 0;
        int i = latest.getScoreInvestigateur() != null ? latest.getScoreInvestigateur() : 0;
        int a = latest.getScoreArtistique() != null ? latest.getScoreArtistique() : 0;
        int s = latest.getScoreSocial() != null ? latest.getScoreSocial() : 0;
        int e = latest.getScoreEntreprenant() != null ? latest.getScoreEntreprenant() : 0;
        int c = latest.getScoreConventionnel() != null ? latest.getScoreConventionnel() : 0;

        double rNorm = Math.min(1.0, r / MAX_RAW_SCORE);
        double iNorm = Math.min(1.0, i / MAX_RAW_SCORE);
        double aNorm = Math.min(1.0, a / MAX_RAW_SCORE);
        double sNorm = Math.min(1.0, s / MAX_RAW_SCORE);
        double eNorm = Math.min(1.0, e / MAX_RAW_SCORE);
        double cNorm = Math.min(1.0, c / MAX_RAW_SCORE);

        double score = (rNorm + iNorm + aNorm + sNorm + eNorm + cNorm) / 6.0;

        String profileCode = latest.getCodeProfil() != null ? latest.getCodeProfil() : "RIASEC";

        Map<String, Object> details = new LinkedHashMap<>();
        details.put("profileCode", profileCode);
        details.put("R", rNorm);
        details.put("I", iNorm);
        details.put("A", aNorm);
        details.put("S", sNorm);
        details.put("E", eNorm);
        details.put("C", cNorm);
        details.put("testsCount", results.size());
        details.put("dateDernierTest", latest.getDatePassation() != null
                ? latest.getDatePassation().toString() : null);

        String explanation = String.format(
                "Profil RIASEC : %s. Scores : R=%.2f I=%.2f A=%.2f S=%.2f E=%.2f C=%.2f.",
                profileCode, rNorm, iNorm, aNorm, sNorm, eNorm, cNorm);

        log.info("RIASECEngine student={} profile={} score={}", studentId, profileCode, score);
        return new Engine.Output(score, explanation, details);
    }
}
