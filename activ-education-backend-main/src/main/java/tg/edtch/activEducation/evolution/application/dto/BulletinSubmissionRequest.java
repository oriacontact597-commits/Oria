package tg.edtch.activEducation.evolution.application.dto;

import jakarta.validation.Valid;
import jakarta.validation.constraints.*;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.math.BigDecimal;
import java.util.List;
import java.util.UUID;

/**
 * Requête envoyée par une école pour publier un ensemble de notes
 * d'un élève pour un trimestre donné.
 */
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class BulletinSubmissionRequest {

    @NotNull(message = "L'identifiant de l'élève est obligatoire")
    private UUID studentId;

    @NotBlank(message = "L'année scolaire est obligatoire (ex. 2024-2025)")
    @Pattern(regexp = "\\d{4}-\\d{4}", message = "Format attendu : YYYY-YYYY")
    private String academicYear;

    @NotNull(message = "Le trimestre est obligatoire (1, 2 ou 3)")
    @Min(1) @Max(3)
    private Integer trimester;

    @NotNull(message = "L'établissement est obligatoire")
    private UUID establishmentId;

    @NotEmpty(message = "Au moins une matière est requise")
    @Valid
    private List<SubjectGrade> grades;

    @Data
    @Builder
    @NoArgsConstructor
    @AllArgsConstructor
    public static class SubjectGrade {
        @NotBlank(message = "La matière est obligatoire")
        @Size(max = 100)
        private String subject;

        @NotNull(message = "La note est obligatoire")
        @DecimalMin(value = "0.0", message = "Note min 0")
        @DecimalMax(value = "20.0", message = "Note max 20")
        private BigDecimal grade;

        @DecimalMin(value = "0.0")
        @DecimalMax(value = "20.0")
        private BigDecimal classAverage;

        @Min(1)
        private Integer rankInClass;

        @Size(max = 500)
        private String appreciation;
    }
}
