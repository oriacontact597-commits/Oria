package tg.edtch.activEducation.evolution.application.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotEmpty;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.util.Map;

/**
 * Requête de promotion d'une nouvelle configuration de scoring (P2.1 ORIA — MlRegistry).
 * L'admin envoie les pondérations ; le service les valide (somme = 1.0) et les historise.
 */
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class PromoteWeightsRequest {

    /** Code pays ISO 3166-1 alpha-2 (TG, BJ, CI, SN, BF, ML…). */
    @NotBlank(message = "Le code pays est obligatoire")
    @Size(min = 2, max = 2, message = "Le code pays doit faire 2 caractères")
    private String countryCode;

    /** Nom logique de la config (ex. "default_v1", "terminale_v1"). */
    @NotBlank(message = "Le nom de la config est obligatoire")
    @Size(max = 50, message = "Le nom ne peut pas dépasser 50 caractères")
    private String configName;

    /**
     * Pondérations par moteur. Toutes les valeurs doivent être ≥ 0
     * et la somme doit être 1.0 (validation côté service).
     */
    @NotNull(message = "Les weights sont obligatoires")
    @NotEmpty(message = "Les weights ne peuvent pas être vides")
    private Map<String, Double> weights;

    /** Commentaire libre (optionnel, ≤ 500 caractères). */
    @Size(max = 500, message = "Le commentaire ne peut pas dépasser 500 caractères")
    private String comment;
}
