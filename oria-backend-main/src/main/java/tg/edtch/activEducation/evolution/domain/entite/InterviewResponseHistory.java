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
 * Historique des réponses d'un entretien ORIA avec un élève.
 * Une ligne par question posée.
 * Contexte possible : admission, trimestriel, événementiel.
 */
@Entity
@Table(name = "evolution_interview_history", indexes = {
        @Index(name = "idx_ih_student", columnList = "student_id"),
        @Index(name = "idx_ih_session", columnList = "interview_session_id"),
        @Index(name = "idx_ih_context", columnList = "context")
})
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@SuperBuilder
public class InterviewResponseHistory extends BaseEntity {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "id", updatable = false, nullable = false)
    private Long id;

    @Column(name = "tracking_id", nullable = false, unique = true, updatable = false)
    @Builder.Default
    private UUID trackingId = UUID.randomUUID();

    /** Référence à l'élève. */
    @Column(name = "student_id", nullable = false)
    private UUID studentId;

    /** Identifiant de la session d'entretien (regroupe plusieurs questions). */
    @Column(name = "interview_session_id", nullable = false)
    private UUID interviewSessionId;

    /** Identifiant de la question (ex. "passion_top_1", "learning_style"). */
    @Column(name = "question_id", nullable = false, length = 50)
    private String questionId;

    /**
     * Réponse libre de l'élève.
     * Stockée en JSONB pour permettre des structures riches
     * (ex. {"value": "robotique", "weight": 0.9}).
     */
    @JdbcTypeCode(SqlTypes.JSON)
    @Column(name = "response", columnDefinition = "jsonb", nullable = false)
    private Map<String, Object> response;

    @Column(name = "asked_at", nullable = false)
    @Builder.Default
    private LocalDateTime askedAt = LocalDateTime.now();

    /** Contexte : admission, quarterly, event. */
    @Column(name = "context", nullable = false, length = 50)
    private String context;
}
