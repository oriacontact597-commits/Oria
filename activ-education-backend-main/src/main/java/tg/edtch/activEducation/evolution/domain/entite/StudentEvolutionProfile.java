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
 * Snapshot sérialisable du Student Evolution Profile (SEP) à un instant T.
 * Le payload complet est stocké en JSONB pour permettre des reconstructions
 * rapides sans 15 jointures.
 *
 * <p>Cette table est un cache : la source de vérité reste les tables
 * bulletin_history, interview_history, etc. Un job recalcule périodiquement
 * et incrémente {@code version}.</p>
 */
@Entity
@Table(name = "evolution_student_profile", indexes = {
        @Index(name = "idx_esp_student", columnList = "student_id", unique = true)
})
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@SuperBuilder
public class StudentEvolutionProfile extends BaseEntity {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "id", updatable = false, nullable = false)
    private Long id;

    @Column(name = "tracking_id", nullable = false, unique = true, updatable = false)
    @Builder.Default
    private UUID trackingId = UUID.randomUUID();

    /** Référence à l'élève. */
    @Column(name = "student_id", nullable = false, unique = true)
    private UUID studentId;

    /** Version monotonement croissante (incrémentée à chaque recalcul). */
    @Column(name = "version", nullable = false)
    @Builder.Default
    private Integer version = 1;

    /** Date du dernier calcul. */
    @Column(name = "computed_at", nullable = false)
    @Builder.Default
    private LocalDateTime computedAt = LocalDateTime.now();

    /**
     * Le SEP complet en JSONB.
     * Structure : voir ARCHITECTURE_ORIA.md §3.2.
     */
    @JdbcTypeCode(SqlTypes.JSON)
    @Column(name = "payload", columnDefinition = "jsonb", nullable = false)
    private Map<String, Object> payload;
}
