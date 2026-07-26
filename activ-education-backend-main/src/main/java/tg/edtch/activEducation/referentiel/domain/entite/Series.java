package tg.edtch.activEducation.referentiel.domain.entite;

import jakarta.persistence.*;
import lombok.*;
import org.hibernate.annotations.JdbcTypeCode;
import org.hibernate.type.SqlTypes;
import tg.edtch.activEducation.shared.util.BaseEntity;

import java.util.List;
import java.util.UUID;

/**
 * Série du secondaire (par pays).
 * Ex. TG-C = "Sciences Mathématiques" au Togo.
 */
@Entity
@Table(name = "referentiel_series", uniqueConstraints = {
        @UniqueConstraint(columnNames = {"country_code", "code"})
})
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class Series extends BaseEntity {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "id", updatable = false, nullable = false)
    private Long id;

    @Column(name = "tracking_id", nullable = false, unique = true, updatable = false)
    @Builder.Default
    private UUID trackingId = UUID.randomUUID();

    @Column(name = "country_code", nullable = false, length = 2)
    private String countryCode;

    @Column(name = "code", nullable = false, length = 10)
    private String code;

    @Column(name = "name", nullable = false, length = 100)
    private String name;

    @Column(name = "description", columnDefinition = "TEXT")
    private String description;

    @JdbcTypeCode(SqlTypes.JSON)
    @Column(name = "required_subjects", columnDefinition = "jsonb")
    private List<String> requiredSubjects;

    @JdbcTypeCode(SqlTypes.JSON)
    @Column(name = "career_paths", columnDefinition = "jsonb")
    private List<String> careerPaths;
}
