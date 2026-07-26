package tg.edtch.activEducation.shared.security.auth;

import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import tg.edtch.activEducation.profil.application.dto.request.ConsentementDemandeRequest;
import tg.edtch.activEducation.profil.application.dto.response.ConsentementResponse;
import tg.edtch.activEducation.profil.domain.entite.ConsentementParental;
import tg.edtch.activEducation.profil.domain.service.ConsentementParentalService;

import java.util.Map;
import java.util.UUID;

/**
 * Endpoints du consentement parental (P1.2 ORIA).
 * Public (pas d'auth — la validation se fait par token email).
 */
@RestController
@RequestMapping("/api/v1/consentement")
@RequiredArgsConstructor
@Tag(name = "Consentement parental", description = "Validation du consentement parental pour les mineurs")
public class ConsentementController {

    private final ConsentementParentalService consentementService;

    /**
     * Demande de consentement : crée (ou remplace) un enregistrement
     * {@code consentements_parentaux} avec un token UUID et un email parent.
     * Le mail de validation est censé être envoyé hors-backend (job / cron).
     */
    @PostMapping("/demander")
    @Operation(summary = "Demander le consentement parental pour un élève mineur")
    public ResponseEntity<ConsentementResponse> demander(@Valid @RequestBody ConsentementDemandeRequest request) {
        ConsentementParental c = consentementService.demanderConsentementParTrackingId(
                request.getEleveTrackingId(), request.getEmailParent());
        return ResponseEntity.status(HttpStatus.CREATED).body(toResponse(c));
    }

    /**
     * Validation via le lien email (token UUID).
     */
    @GetMapping("/valider")
    @Operation(summary = "Valider le consentement parental via le lien envoyé par email")
    public ResponseEntity<Map<String, Object>> valider(@RequestParam("token") String token,
                                                        HttpServletRequest request) {
        boolean success = consentementService.validerConsentement(token, request.getRemoteAddr());
        return success
                ? ResponseEntity.ok(Map.of("message", "Consentement validé avec succès"))
                : ResponseEntity.badRequest().body(Map.of("message", "Lien invalide ou expiré"));
    }

    /**
     * Statut du consentement pour l'élève identifié par son trackingId.
     * Renvoie 200 avec consenti=false même si aucun consentement n'a été demandé
     * (utile pour le front : "existe-t-il un consentement validé ?").
     */
    @GetMapping("/eleve/{trackingId}")
    @Operation(summary = "Statut du consentement parental pour un élève")
    public ResponseEntity<ConsentementResponse> statutEleve(@PathVariable UUID trackingId) {
        ConsentementParental c = consentementService.statutParTrackingId(trackingId);
        if (c == null) {
            return ResponseEntity.ok(ConsentementResponse.builder()
                    .eleveId(null)
                    .consenti(false)
                    .build());
        }
        return ResponseEntity.ok(toResponse(c));
    }

    private static ConsentementResponse toResponse(ConsentementParental c) {
        return ConsentementResponse.builder()
                .eleveId(c.getEleveId())
                .consenti(c.isConsenti())
                .dateDemande(c.getDateDemande())
                .dateValidation(c.getDateValidation())
                .emailParent(c.getEmailParent())
                .build();
    }
}
