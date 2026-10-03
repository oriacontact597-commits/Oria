package tg.edtch.activEducation.prediction.application.dto;

/**
 * Représente le résultat brut renvoyé par l'API Python de prédiction.
 */
public record MLPredictionResponse(
    String prediction,
    Double probability,
    String modelMode,
    String warning
) {}
