package tg.edtch.activEducation.profil.application.dto.response;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDateTime;

/**
 * Statut du consentement parental pour un élève.
 * {@code tokenValidation} n'est jamais renvoyé en réponse (information sensible).
 */
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class ConsentementResponse {

    private Long eleveId;
    private boolean consenti;
    private LocalDateTime dateDemande;
    private LocalDateTime dateValidation;
    private String emailParent;
}
