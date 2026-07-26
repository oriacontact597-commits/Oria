package tg.edtch.activEducation.evolution.engines;

import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.data.domain.PageRequest;
import org.springframework.stereotype.Service;
import tg.edtch.activEducation.bibliotheque.domain.entite.FicheMetier;
import tg.edtch.activEducation.bibliotheque.repository.FicheMetierRepository;
import tg.edtch.activEducation.prediction.domain.util.ProfilFiliereRiasecCatalog;
import tg.edtch.activEducation.riasec.domain.entite.TestRIASECResultat;
import tg.edtch.activEducation.riasec.repository.TestRIASECResultatRepository;

import java.util.*;

@Service
@RequiredArgsConstructor
@Slf4j
public class CareerMatchingEngine implements Engine<UUID, Engine.Output> {

    private final FicheMetierRepository metierRepository;
    private final TestRIASECResultatRepository riasecRepository;

    @Override
    public String name() {
        return "career";
    }

    @Override
    public Engine.Output evaluate(UUID studentId) {
        String eleveId = studentId.toString();
        List<TestRIASECResultat> riasecResults = riasecRepository
                .findByEleveTrackingIdOrderByDatePassationDesc(eleveId);

        double[] studentRIASEC = getStudentRIASEC(riasecResults);
        boolean hasRIASEC = riasecResults.size() > 0;

        List<FicheMetier> metiers = metierRepository.findAllByEstPublieTrue(PageRequest.of(0, 100)).getContent();

        if (metiers.isEmpty() || !hasRIASEC) {
            return new Engine.Output(0.5,
                    hasRIASEC ? "Catalogue métiers vide." : "Test RIASEC nécessaire pour le matching métier.",
                    Map.of("matchingMetiersCount", 0, "hasRIASEC", hasRIASEC));
        }

        List<Map<String, Object>> matches = new ArrayList<>();
        for (FicheMetier m : metiers) {
            String titre = m.getTitre() != null ? m.getTitre() : "";
            String secteur = m.getSecteur() != null ? m.getSecteur() : "";
            double[] careerProfile = ProfilFiliereRiasecCatalog.profilPour(titre);
            double[] secteurProfile = ProfilFiliereRiasecCatalog.profilPour(secteur);
            double[] combined = new double[6];
            for (int i = 0; i < 6; i++) {
                combined[i] = (careerProfile[i] + secteurProfile[i]) / 2.0;
            }
            double similarity = cosineSimilarity(studentRIASEC, combined);
            if (similarity > 0.6) {
                Map<String, Object> mInfo = new LinkedHashMap<>();
                mInfo.put("titre", titre);
                mInfo.put("secteur", secteur);
                mInfo.put("score", Math.round(similarity * 100.0) / 100.0);
                matches.add(mInfo);
            }
        }

        matches.sort((a, b) -> Double.compare(
                (Double) b.get("score"), (Double) a.get("score")));
        List<Map<String, Object>> top5 = matches.size() > 5 ? matches.subList(0, 5) : matches;

        double score = top5.isEmpty() ? 0.3 :
                Math.min(1.0, top5.stream().mapToDouble(m -> (Double) m.get("score")).average().orElse(0.3));

        String explanation = String.format(
                "%d métiers compatibles trouvés. Top 5 similitude RIASEC.",
                matches.size());

        Map<String, Object> details = new LinkedHashMap<>();
        details.put("totalMatching", matches.size());
        details.put("top5", top5);

        log.info("CareerMatchingEngine student={} matches={} score={}", studentId, matches.size(), score);
        return new Engine.Output(score, explanation, details);
    }

    private double[] getStudentRIASEC(List<TestRIASECResultat> results) {
        if (results.isEmpty()) return new double[]{0.5, 0.5, 0.5, 0.5, 0.5, 0.5};
        TestRIASECResultat r = results.get(0);
        return new double[]{
                norm(r.getScoreRealiste()),
                norm(r.getScoreInvestigateur()),
                norm(r.getScoreArtistique()),
                norm(r.getScoreSocial()),
                norm(r.getScoreEntreprenant()),
                norm(r.getScoreConventionnel())
        };
    }

    private double norm(Integer score) {
        return score != null ? Math.min(1.0, score / 30.0) : 0.5;
    }

    private double cosineSimilarity(double[] a, double[] b) {
        double dot = 0, normA = 0, normB = 0;
        for (int i = 0; i < a.length; i++) {
            dot += a[i] * b[i];
            normA += a[i] * a[i];
            normB += b[i] * b[i];
        }
        double denom = Math.sqrt(normA) * Math.sqrt(normB);
        return denom == 0 ? 0.5 : dot / denom;
    }
}
