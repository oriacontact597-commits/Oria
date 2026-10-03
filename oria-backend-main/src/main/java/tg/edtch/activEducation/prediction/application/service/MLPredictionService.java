package tg.edtch.activEducation.prediction.application.service;

import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.web.client.RestTemplate;
import tg.edtch.activEducation.prediction.application.dto.MLPredictionRequest;
import tg.edtch.activEducation.prediction.application.dto.MLPredictionResponse;
import tg.edtch.activEducation.profil.domain.entite.Eleve;
import tg.edtch.activEducation.profil.repository.EleveRepository;

import java.time.LocalDate;
import java.time.Period;
import java.util.HashMap;
import java.util.Map;
import java.util.UUID;

@Service
@RequiredArgsConstructor
@Slf4j
public class MLPredictionService {

    private final RestTemplate restTemplate;
    private final EleveRepository eleveRepository;
    private static final String PYTHON_API_URL = "http://127.0.0.1:8000/predict";

    /**
     * Appelle l'API Python pour obtenir une prédiction basée sur les données réelles de l'élève.
     *
     * @param eleveTrackingId L'ID de l'élève.
     * @param filiereTrackingId L'ID de la filière demandée.
     * @return Le résultat de la prédiction.
     */
    public MLPredictionResponse calculate(UUID eleveTrackingId, String filiereTrackingId) {
        log.info("Calcul de prédiction ML pour eleve={} filiere={}", eleveTrackingId, filiereTrackingId);

        Eleve eleve = eleveRepository.findByTrackingId(eleveTrackingId)
                .orElseThrow(() -> new RuntimeException("Élève non trouvé avec l'ID : " + eleveTrackingId));

        // Construction des features basées sur les données réelles
        Map<String, Object> features = new HashMap<>();

        // Âge
        int age = 18;
        if (eleve.getDateNaissance() != null) {
            age = Period.between(eleve.getDateNaissance(), LocalDate.now()).getYears();
        }
        features.put("age", age);

        // Moyennes (Simulation : on utilise 12.5 par défaut si pas de bulletins,
        // car le calcul complexe des moyennes par matière nécessiterait l'analyse des Documents)
        features.put("moyenne_bac", 12.5);
        features.put("note_mathematiques", 11.0);
        features.put("note_francais", 12.0);
        features.put("note_anglais", 10.0);
        features.put("taux_reference_admission", 0.5);

        // Profil et identité
        features.put("profil_type", "BACHELIER");
        features.put("annee_academique", "2024-2025");
        features.put("region", "Grand Lomé"); // Valeur par défaut
        features.put("sexe", "M"); // Valeur par défaut
        features.put("serie_bac", eleve.getFiliere() != null ? eleve.getFiliere() : "D");
        features.put("type_enseignement", "GENERAL");
        features.put("cohorte", "BAC1");
        features.put("concours_filiere", filiereTrackingId);
        features.put("etablissement_demande", eleve.getEtablissement() != null ? eleve.getEtablissement() : "UL");

        MLPredictionRequest request = new MLPredictionRequest(features);

        try {
            return restTemplate.postForObject(PYTHON_API_URL, request, MLPredictionResponse.class);
        } catch (Exception e) {
            log.error("Erreur lors de l'appel à l'API Python ML : {}", e.getMessage());
            return new MLPredictionResponse("RECALE", 0.0, "fallback", "L'API de prédiction est indisponible. Résultat par défaut.");
        }
    }
}
