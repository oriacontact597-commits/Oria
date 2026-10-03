package tg.edtch.activEducation.evolution.domain.entite;

import jakarta.persistence.*;
import lombok.*;
import lombok.experimental.SuperBuilder;
import tg.edtch.activEducation.shared.util.BaseEntity;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.UUID;

/**
 * Historique d'un bulletin scolaire trimestriel.
 * Une ligne par matière, par trimestre.
 * Source officielle : l'établissement (is_official = true).
 *
 * <p>Cette table est immuable (append-only) : on n'update jamais une note,
 * on insère une nouvelle version si correction.</p>
 */
@Entity
@Table(name = "evolution_bulletin_history", indexes = {
        @Index(name = "idx_bh_student", columnList = "student_id"),
        @Index(name = "idx_bh_year_trimester", columnList = "academic_year, trimester"),
        @Index(name = "idx_bh_subject", columnList = "subject")
})
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@SuperBuilder
public class BulletinHistory extends BaseEntity {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "id", updatable = false, nullable = false)
    private Long id;

    /** Identifiant public (référence externe). */
    @Column(name = "tracking_id", nullable = false, unique = true, updatable = false)
    @Builder.Default
    private UUID trackingId = UUID.randomUUID();

    /** Référence à l'élève (tracking_id de Utilisateur). */
    @Column(name = "student_id", nullable = false)
    private UUID studentId;

    /** Trimestre : 1, 2 ou 3. */
    @Column(name = "trimester", nullable = false)
    private Integer trimester;

    /** Année scolaire (ex. "2024-2025"). */
    @Column(name = "academic_year", nullable = false, length = 9)
    private String academicYear;

    /** Matière (libellé libre : "Mathématiques", "Physique-Chimie"…). */
    @Column(name = "subject", nullable = false, length = 100)
    private String subject;

    /** Note sur 20. */
    @Column(name = "grade", nullable = false, precision = 4, scale = 2)
    private BigDecimal grade;

    /** Moyenne de la classe sur 20. */
    @Column(name = "class_average", precision = 4, scale = 2)
    private BigDecimal classAverage;

    /** Rang dans la classe. */
    @Column(name = "rank_in_class")
    private Integer rankInClass;

    /** Appréciation du professeur (texte libre). */
    @Column(name = "appreciation", columnDefinition = "TEXT")
    private String appreciation;

    /** true = bulletin officiel établissement, false = saisie libre élève. */
    @Column(name = "is_official", nullable = false)
    @Builder.Default
    private Boolean isOfficial = true;

    /** Date de réception du bulletin. */
    @Column(name = "received_at", nullable = false)
    @Builder.Default
    private LocalDateTime receivedAt = LocalDateTime.now();

    /** Établissement qui a envoyé le bulletin (référence vers bibliotheque). */
    @Column(name = "sent_by_establishment_id")
    private UUID sentByEstablishmentId;

    /** Conseiller qui a validé (si applicable). */
    @Column(name = "validated_by")
    private UUID validatedBy;
}
