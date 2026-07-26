package tg.edtch.activEducation.evolution.domain.entite;

import jakarta.persistence.*;
import lombok.*;
import lombok.experimental.SuperBuilder;
import org.hibernate.annotations.JdbcTypeCode;
import org.hibernate.type.SqlTypes;
import tg.edtch.activEducation.shared.util.BaseEntity;

import java.util.Map;
import java.util.UUID;

/**
 * Configuration des pondérations utilisées par l'orchestrateur de
 * recommandation.
 * Modifiable par les admins via /api/v1/admin/scoring-config sans recompiler.
 *
 * <p>Clé naturelle : (country_code, config_name, is_active=true).</p>
 */
@Entity
@Table(name = "evolution_scoring_config", indexes = {
        @Index(name = "idx_sc_country_active", columnList = "country_code, is_active")
})
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@SuperBuilder
public class ScoringConfig extends BaseEntity {

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

    /**
     * Pondérations par moteur.
     * Format : {"academic": 0.40, "interest": 0.20, "riasec": 0.15,
     *          "behaviour": 0.05, "skills": 0.10, "activities": 0.10}
     * La somme doit faire 1.0 (validée en service).
     */
    @JdbcTypeCode(SqlTypes.JSON)
    @Column(name = "weights", columnDefinition = "jsonb", nullable = false)
    private Map<String, Double> weights;

    /** Une seule config active par (pays, nom). */
    @Column(name = "is_active", nullable = false)
    @Builder.Default
    private Boolean isActive = true;
}
