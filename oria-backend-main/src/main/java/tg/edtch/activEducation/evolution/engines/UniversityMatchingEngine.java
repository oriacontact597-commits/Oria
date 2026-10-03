package tg.edtch.activEducation.evolution.engines;

import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.data.domain.PageRequest;
import org.springframework.stereotype.Service;
import tg.edtch.activEducation.bibliotheque.domain.entite.FicheEtablissement;
import tg.edtch.activEducation.bibliotheque.repository.FicheEtablissementRepository;

import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.UUID;

@Service
@RequiredArgsConstructor
@Slf4j
public class UniversityMatchingEngine implements Engine<UUID, Engine.Output> {

    private final FicheEtablissementRepository etablissementRepository;

    @Override
    public String name() {
        return "university";
    }

    @Override
    public Engine.Output evaluate(UUID studentId) {
        List<FicheEtablissement> etablissements =
                etablissementRepository.findAllByEstPublieTrue(PageRequest.of(0, 200)).getContent();

        if (etablissements.isEmpty()) {
            return new Engine.Output(0.5,
                    "Aucun établissement référencé dans la base.",
                    Map.of("etablissementsCount", 0));
        }

        long univCount = etablissements.stream()
                .filter(e -> e.getTypeEtablissement() != null
                        && e.getTypeEtablissement().name().toLowerCase().contains("universite"))
                .count();
        long ecoleCount = etablissements.size() - univCount;

        int niveauCount = (int) etablissements.stream()
                .filter(e -> e.getNiveau() != null)
                .map(FicheEtablissement::getNiveau)
                .distinct()
                .count();

        long villeCount = etablissements.stream()
                .filter(e -> e.getVille() != null)
                .map(FicheEtablissement::getVille)
                .distinct()
                .count();

        double score = Math.min(1.0, 0.2 + (etablissements.size() / 200.0) * 0.4
                + (niveauCount / 5.0) * 0.2 + (villeCount / 10.0) * 0.2);

        String explanation = String.format(
                "%d établissements (%d universités, %d écoles) dans %d villes, %d niveaux.",
                etablissements.size(), univCount, ecoleCount, villeCount, niveauCount);

        Map<String, Object> details = new LinkedHashMap<>();
        details.put("etablissementsCount", etablissements.size());
        details.put("universitesCount", univCount);
        details.put("ecolesCount", ecoleCount);
        details.put("villesCount", villeCount);
        details.put("niveauxCount", niveauCount);

        log.info("UniversityMatchingEngine student={} etablissements={} score={}",
                studentId, etablissements.size(), score);
        return new Engine.Output(score, explanation, details);
    }
}
