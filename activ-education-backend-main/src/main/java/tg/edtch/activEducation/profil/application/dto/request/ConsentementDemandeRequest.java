package tg.edtch.activEducation.profil.application.dto.request;

import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.util.UUID;

/**
 * Requête de demande de consentement parental.
 * Envoyée par l'élève lors de l'inscription (s'il a < 15 ans) ou par le backoffice.
 */
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class ConsentementDemandeRequest {

    /** TrackingId (UUID public) de l'élève mineur. */
    @NotNull(message = "Le trackingId de l'élève est obligatoire")
    private UUID eleveTrackingId;

    /** Email du parent à qui envoyer le lien de validation. */
    @NotBlank(message = "L'email du parent est obligatoire")
    @Email(message = "Le format de l'email est invalide")
    @Size(max = 150, message = "L'email ne peut pas dépasser 150 caractères")
    private String emailParent;
}
