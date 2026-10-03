package tg.edtch.activEducation.prediction.application.dto;

import java.util.Map;

/**
 * Requête envoyée à l'API Python pour obtenir une prédiction.
 */
public record MLPredictionRequest(
    Map<String, Object> features
) {}
