package tg.edtch.activEducation.evolution.domain.entite;

import jakarta.persistence.*;
import lombok.*;
import lombok.experimental.SuperBuilder;
import org.hibernate.annotations.JdbcTypeCode;
import org.hibernate.type.SqlTypes;
import tg.edtch.activEducation.shared.util.BaseEntity;

import java.time.LocalDateTime;
import java.util.Map;
import java.util.UUID;

/**
 * Historique append-only des configurations de scoring (P2.1 ORIA — MlRegistry).
 * Une ligne par promote/rollback. {@code is_current=true} pointe vers la config
 * actuellement active (au plus une par (country_code, config_name)).
 *
 * <p>La table est volontairement non FK-vers {@link ScoringConfig} : l'historique
 * survit aux suppressions de la table principale.</p>
 */
@Entity
@Table(name = "evolution_scoring_config_history", indexes = {
        @Index(name = "idx_scch_country_name_time", columnList = "country_code, config_name, changed_at"),
        @Index(name = "idx_scch_current", columnList = "country_code, config_name")
})
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@SuperBuilder
public class ScoringConfigHistory extends BaseEntity {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "id", updatable = false, nullable = false)
    private Long id;

    @Column(name = "tracking_id", nullable = false, unique = true, updatable = false)
    @Builder.Default
    private UUID trackingId = UUID.randomUUID();

    /** Code pays ISO 3166-1 alpha-2 (TG, BJ, CI, SN, BF, ML…). */
    @Column(name = "country_code", nullable = false, length = 2)
    private String countryCode;

    /** Nom logique de la config (ex. "default_v1", "terminale_v1"). */
    @Column(name = "config_name", nullable = false, length = 50)
    private String configName;

    /** Pondérations snapshot au moment de l'action. Format identique à ScoringConfig.weights. */
    @JdbcTypeCode(SqlTypes.JSON)
    @Column(name = "weights", columnDefinition = "jsonb", nullable = false)
    private Map<String, Double> weights;

    /** Type d'action : PROMOTE (nouvelle config) ou ROLLBACK (retour à une config antérieure). */
    @Enumerated(EnumType.STRING)
    @Column(name = "action", nullable = false, length = 20)
    private ActionType action;

    /** Pour un ROLLBACK : tracking_id de l'entrée d'historique dont on copie les weights. */
    @Column(name = "rolled_back_from")
    private UUID rolledBackFrom;

    /** Commentaire libre fourni par l'admin. */
    @Column(name = "comment", columnDefinition = "TEXT")
    private String comment;

    /** Email de l'admin qui a déclenché l'action. */
    @Column(name = "changed_by", nullable = false, length = 255)
    private String changedBy;

    @Column(name = "changed_at", nullable = false)
    @Builder.Default
    private LocalDateTime changedAt = LocalDateTime.now();

    /** Vrai pour la config active (une seule par (country, name)). */
    @Column(name = "is_current", nullable = false)
    @Builder.Default
    private Boolean isCurrent = false;

    /**
     * Actions possibles sur le registre de scoring.
     */
    public enum ActionType {
        PROMOTE,
        ROLLBACK
    }
}
