package tg.edtch.activEducation.evolution.application.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;
import tg.edtch.activEducation.evolution.domain.entite.ScoringConfigHistory;

import java.time.LocalDateTime;
import java.util.Map;
import java.util.UUID;

/**
 * Réponse exposant une entrée d'historique de scoring (P2.1 ORIA — MlRegistry).
 * Utilisée par les 3 endpoints admin (promote, history, rollback, current).
 */
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class ScoringConfigHistoryResponse {

    private UUID trackingId;
    private String countryCode;
    private String configName;
    private Map<String, Double> weights;
    private ScoringConfigHistory.ActionType action;
    private UUID rolledBackFrom;
    private String comment;
    private String changedBy;
    private LocalDateTime changedAt;
    private Boolean isCurrent;

    /**
     * Mapping entité → DTO.
     */
    public static ScoringConfigHistoryResponse fromEntity(ScoringConfigHistory entity) {
        if (entity == null) return null;
        return ScoringConfigHistoryResponse.builder()
                .trackingId(entity.getTrackingId())
                .countryCode(entity.getCountryCode())
                .configName(entity.getConfigName())
                .weights(entity.getWeights())
                .action(entity.getAction())
                .rolledBackFrom(entity.getRolledBackFrom())
                .comment(entity.getComment())
                .changedBy(entity.getChangedBy())
                .changedAt(entity.getChangedAt())
                .isCurrent(entity.getIsCurrent())
                .build();
    }
}
