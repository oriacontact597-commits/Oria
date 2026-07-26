package tg.edtch.activEducation.referentiel.domain.entite;

import jakarta.persistence.*;
import lombok.*;
import tg.edtch.activEducation.shared.util.BaseEntity;

import java.util.UUID;

/**
 * Pays supporté par ORIA.
 * Code ISO 3166-1 alpha-2 (TG, BJ, CI, SN, BF...).
 */
@Entity
@Table(name = "referentiel_country")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class Country extends BaseEntity {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "id", updatable = false, nullable = false)
    private Long id;

    @Column(name = "tracking_id", nullable = false, unique = true, updatable = false)
    @Builder.Default
    private UUID trackingId = UUID.randomUUID();

    @Column(name = "code", nullable = false, unique = true, length = 2)
    private String code;

    @Column(name = "name_fr", nullable = false, length = 100)
    private String nameFr;

    @Column(name = "name_en", length = 100)
    private String nameEn;

    @Column(name = "name_local", length = 100)
    private String nameLocal;

    @Column(name = "currency", length = 3)
    private String currency;

    @Column(name = "language_primary", length = 5)
    private String languagePrimary;

    @Column(name = "is_active", nullable = false)
    @Builder.Default
    private Boolean isActive = true;
}
