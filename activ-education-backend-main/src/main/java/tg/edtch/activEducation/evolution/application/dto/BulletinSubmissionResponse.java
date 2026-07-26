package tg.edtch.activEducation.evolution.application.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.util.List;
import java.util.UUID;

/**
 * Réponse après soumission d'un bulletin par une école.
 * Confirme combien de notes ont été insérées et retourne leurs IDs.
 */
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class BulletinSubmissionResponse {

    private UUID submissionId;
    private UUID studentId;
    private String academicYear;
    private Integer trimester;
    private int gradesInserted;
    private List<UUID> bulletinTrackingIds;
    private String message;
}
